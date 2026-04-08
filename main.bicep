// ------------------
//    PARAMETERS
// ------------------

@minLength(1)
@description('Configuration array for AI Services endpoints. At least one is required.')
param aiServicesConfig array

@description('Configuration array for model deployments across AI Services accounts.')
param modelsConfig array

@description('The SKU tier for the API Management instance (e.g., Basicv2, Consumption).')
param apimSku string

@description('Configuration array for APIM subscriptions to create.')
param apimSubscriptionsConfig array = []

@description('The inference API type — determines the OpenAPI spec and URL path structure.')
param inferenceAPIType string = 'AzureOpenAI'

@description('The base path for the inference API in APIM.')
param inferenceAPIPath string = 'inference'

@description('The AI Foundry project name prefix scoped to each Cognitive Services account.')
param foundryProjectName string = 'default'

@description('Whether to provision Log Analytics and Application Insights diagnostics.')
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

#disable-next-line outputs-should-not-contain-secrets
output apimSubscriptions array = apimModule.outputs.apimSubscriptions
output aiServicesRuntimeConfig array = foundryModule.outputs.extendedAIServicesConfig
output appInsightsResourceId string = diagnosticsModule.outputs.appInsightsId
output appInsightsAppId string = diagnosticsModule.outputs.appInsightsAppId
output logAnalyticsWorkspaceId string = diagnosticsModule.outputs.lawId
output diagnosticsEnabled bool = diagnosticsModule.outputs.diagnosticsEnabled
