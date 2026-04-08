/**
 * @module diagnostics-v1
 * @description This module defines the Azure diagnostics and monitoring resources (Log Analytics Workspace and Application Insights).
 * This is version 1 (v1) of the diagnostics Bicep module.
 */

// ------------------
//    PARAMETERS
// ------------------

@description('Enable diagnostics for all resources')
param enableDiagnostics bool = true

@description('Location for diagnostics resources')
param location string = resourceGroup().location

@description('Retention in days for Log Analytics Workspace')
param lawRetentionDays int = 30

// ------------------
//    VARIABLES
// ------------------

var resourceSuffix = uniqueString(subscription().id, resourceGroup().id)
var logAnalyticsWorkspaceName = 'law-${resourceSuffix}'
var applicationInsightsName = 'appi-${resourceSuffix}'

// ------------------
//    RESOURCES
// ------------------

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (enableDiagnostics) {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: lawRetentionDays
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableDiagnostics) {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    IngestionMode: 'LogAnalytics'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ------------------
//    OUTPUTS
// ------------------

@description('The resource ID of the Log Analytics Workspace')
output lawId string = enableDiagnostics ? logAnalyticsWorkspace.id : ''

@description('The resource ID of the Application Insights instance')
output appInsightsId string = enableDiagnostics ? applicationInsights.id : ''

@description('The instrumentation key for Application Insights')
@secure()
output appInsightsInstrumentationKey string = enableDiagnostics ? (applicationInsights.?properties.InstrumentationKey ?? '') : ''

@description('The App ID for Application Insights')
output appInsightsAppId string = enableDiagnostics ? (applicationInsights.?properties.AppId ?? '') : ''

@description('Whether diagnostics are enabled')
output diagnosticsEnabled bool = enableDiagnostics
