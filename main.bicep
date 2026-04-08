// ------------------
//    PARAMETERS
// ------------------

param aiServicesConfig array = []
param modelsConfig array = []
param apimSku string
param apimSubscriptionsConfig array = []
param inferenceAPIType string = 'AzureOpenAI'
param inferenceAPIPath string = 'inference' // Path to the inference API in the APIM service
param foundryProjectName string = 'default'
param enableDiagnostics bool = true

var resourceSuffix = uniqueString(subscription().id, resourceGroup().id)
var diagnosticsWorkspaceName = 'law-${resourceSuffix}'
var applicationInsightsName = 'appi-${resourceSuffix}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (enableDiagnostics) {
  name: diagnosticsWorkspaceName
  location: resourceGroup().location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableDiagnostics) {
  name: applicationInsightsName
  location: resourceGroup().location
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
//    RESOURCES
// ------------------

// 1. API Management
module apimModule './modules/apim/v2/apim.bicep' = {
  params: {
    apimSku: apimSku
    apimSubscriptionsConfig: apimSubscriptionsConfig
    lawId: enableDiagnostics ? logAnalyticsWorkspace.id : ''
    appInsightsId: enableDiagnostics ? applicationInsights.id : ''
    appInsightsInstrumentationKey: enableDiagnostics ? (applicationInsights.?properties.InstrumentationKey ?? '') : ''
  }
}

// 2. AI Foundry
module foundryModule './modules/cognitive-services/v3/foundry.bicep' = {
    params: {
      aiServicesConfig: aiServicesConfig
      modelsConfig: modelsConfig
      apimPrincipalId: apimModule.outputs.principalId
      foundryProjectName: foundryProjectName
      lawId: enableDiagnostics ? logAnalyticsWorkspace.id : ''
      appInsightsId: enableDiagnostics ? applicationInsights.id : ''
      appInsightsInstrumentationKey: enableDiagnostics ? (applicationInsights.?properties.InstrumentationKey ?? '') : ''
    }
  }

// 3. APIM Inference API
module inferenceAPIModule './modules/apim/v2/inference-api.bicep' = {
  params: {
    policyXml: loadTextContent('policy.xml')
    aiServicesConfig: foundryModule.outputs.extendedAIServicesConfig
    inferenceAPIType: inferenceAPIType
    inferenceAPIPath: inferenceAPIPath
    configureCircuitBreaker: true
    apimLoggerId: apimModule.outputs.loggerId
    appInsightsId: enableDiagnostics ? applicationInsights.id : ''
    appInsightsInstrumentationKey: enableDiagnostics ? (applicationInsights.?properties.InstrumentationKey ?? '') : ''
  }
}


// ------------------
//    OUTPUTS
// ------------------

output apimServiceId string = apimModule.outputs.id
output apimResourceGatewayURL string = apimModule.outputs.gatewayUrl

output apimSubscriptions array = apimModule.outputs.apimSubscriptions
output aiServicesRuntimeConfig array = foundryModule.outputs.extendedAIServicesConfig
output appInsightsResourceId string = enableDiagnostics ? applicationInsights.id : ''
output appInsightsAppId string = enableDiagnostics ? (applicationInsights.?properties.AppId ?? '') : ''
output logAnalyticsWorkspaceId string = enableDiagnostics ? logAnalyticsWorkspace.id : ''
output diagnosticsEnabled bool = enableDiagnostics
