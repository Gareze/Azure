# Before running the script use 'az login' to authenticate
# Variables
$subscriptionId = "<your-subscription-id>"  # Replace with your devops-dev subscription ID
$resourceGroup = "devops-ai-rg-dev"
$location = "North Europe"
$templateFile = "main.bicep"
$parametersFile = "parameters.dev.json"

# Set subscription
az account set --subscription $subscriptionId

# Create the resource group (if it doesn't exist)
az group create `
  --name $resourceGroup `
  --location "$location" `
  --tags Owner=DevOps Environment=Development Function="AI Services"

# Deploy the Bicep template
az deployment group create `
  --resource-group $resourceGroup `
  --template-file $templateFile `
  --parameters "@$parametersFile" `
  --verbose
