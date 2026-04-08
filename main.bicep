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

// ------------------
//    RESOURCES
// ------------------

// 0. Diagnostics (Log Analytics & Application Insights)
module diagnosticsModule './modules/shared/v1/diagnostics.bicep' = {
  params: {
    enableDiagnostics: enableDiagnostics
    location: resourceGroup().location
  }
}

// 1. API Management
module apimModule './modules/apim/v2/apim.bicep' = {
  params: {
    apimSku: apimSku
    apimSubscriptionsConfig: apimSubscriptionsConfig
    lawId: diagnosticsModule.outputs.lawId
    appInsightsId: diagnosticsModule.outputs.appInsightsId
    appInsightsInstrumentationKey: diagnosticsModule.outputs.appInsightsInstrumentationKey
  }
}

// 2. AI Foundry
module foundryModule './modules/cognitive-services/v3/foundry.bicep' = {
  params: {
    aiServicesConfig: aiServicesConfig
    modelsConfig: modelsConfig
    apimPrincipalId: apimModule.outputs.principalId
    foundryProjectName: foundryProjectName
    lawId: diagnosticsModule.outputs.lawId
    appInsightsId: diagnosticsModule.outputs.appInsightsId
    appInsightsInstrumentationKey: diagnosticsModule.outputs.appInsightsInstrumentationKey
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
    appInsightsId: diagnosticsModule.outputs.appInsightsId
    appInsightsInstrumentationKey: diagnosticsModule.outputs.appInsightsInstrumentationKey
  }
}


// ------------------
//    OUTPUTS
// ------------------

output apimServiceId string = apimModule.outputs.id
output apimResourceGatewayURL string = apimModule.outputs.gatewayUrl

output apimSubscriptions array = apimModule.outputs.apimSubscriptions
output aiServicesRuntimeConfig array = foundryModule.outputs.extendedAIServicesConfig
output appInsightsResourceId string = diagnosticsModule.outputs.appInsightsId
output appInsightsAppId string = diagnosticsModule.outputs.appInsightsAppId
output logAnalyticsWorkspaceId string = diagnosticsModule.outputs.lawId
output diagnosticsEnabled bool = diagnosticsModule.outputs.diagnosticsEnabled
