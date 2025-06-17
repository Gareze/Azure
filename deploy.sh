#!/bin/bash

# Variables
subscriptionId="<your-subscription-id>"  # Set to your devops-dev subscription ID
resourceGroup="devops-ai-rg-dev"
location="North Europe"
templateFile="main.bicep"    # Your Bicep template filename
parametersFile="parameters.dev.json"

# Set subscription
az account set --subscription $subscriptionId

# Create resource group if not exists
az group create --name $resourceGroup --location "$location" --tags Owner=DevOps Environment=Development Function="AI Services"

# Deploy Bicep template
az deployment group create \
  --resource-group $resourceGroup \
  --template-file $templateFile \
  --parameters @$parametersFile \
  --verbose
