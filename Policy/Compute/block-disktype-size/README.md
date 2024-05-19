# Block Disktype and size

Block premium and zrs disk types and size equal or greater than 256 GB.

## Try on Portal

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FGareze%2Azure%2Fmain%2Policy%2FCompute%2Fblock-disktype-size%2Fazurepolicy.json)

## Try with PowerShell

````powershell
$definition = New-AzPolicyDefinition -Name "use-managed-disk-vm" -DisplayName "Block Disktype and size" -description "Block premium and zrs disk types and size equal or greater than 256 GB." -Policy 'https://raw.githubusercontent.com/Gareze/Azure/main/Policy/Compute/block-disktype-size/azurepolicy.json' -Parameter 'https://raw.githubusercontent.com/Gareze/Azure/main/Policy/Compute/block-disktype-size/azurepolicy.parameters.json' -Mode All
$definition
$assignment = New-AzPolicyAssignment -Name <assignmentname> -Scope <scope>  -PolicyDefinition $definition
$assignment 
````



## Try with CLI

````cli

az policy definition create --name 'use-managed-disk-vm' --display-name 'Create VM using Managed Disk' --description 'Create VM using Managed Disk' --rules 'https://raw.githubusercontent.com/Gareze/Azure/main/Policy/Compute/block-disktype-size/azurepolicy.rules.json' --params 'https://raw.githubusercontent.com/Gareze/Azure/main/Policy/Compute/block-disktype-size/azurepolicy.parameters.json' --mode All

az policy assignment create --name <assignmentname> --scope <scope> --policy "use-managed-disk-vm" 

````
