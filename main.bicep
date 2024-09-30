targetScope = 'subscription'

@description('Name of the Automation Account to be created.')
param automationAccountName string = 'bmoAutomationAccount'

@description('Name of the Runbook to manage VM start/stop actions.')
param runbookName string = 'bmorunbook'

@description('Name of the schedule for starting VMs.')
param startScheduleName string = 'StartVMsSchedule'

@description('Name of the schedule for stopping VMs.')
param stopScheduleName string = 'StopVMsSchedule'

@description('The start time for the VM start schedule in ISO 8601 format (UTC).')
param startTime string = '2024-09-09T20:30:00-04:00'

@description('The stop time for the VM stop schedule in ISO 8601 format (UTC).')
param stopTime string = '2024-09-09T18:15:00-04:00'

@description('URI of the PowerShell script to be used by the Runbook.')
param runbookScriptUri string = 'https://raw.githubusercontent.com/ghostme/azurescripts/main/startstopVM.ps1'

@description('Name of the Resource Group where the Automation Account will be deployed.')
param acRgName string = 'bmostartstopRG'

@description('Azure region where the resources will be deployed.')
param location string = 'eastus'

@description('ID of the subscription where the role assignment will be enabled.')
param subscriptionToEnable string = 'b4d37e03-6a45-4ebd-b9b3-a39314a819e7'

// Deploy the automation account and related resources

resource rgLog 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: acRgName
  location: location
}
module automation 'automationAccount.bicep' = {
  name: 'automationAccountDeployment'
  scope:resourceGroup(rgLog.name)
  params: {
    location: location
    automationAccountName: automationAccountName
    runbookName: runbookName
    startScheduleName: startScheduleName
    stopScheduleName: stopScheduleName
    startTime: startTime
    stopTime: stopTime
    runbookScriptUri:runbookScriptUri
  }
}

// Deploy the role assignment for the automation account's system-assigned managed identity
module roleAssignment 'roleAssignment.bicep' = {
  name: 'roleAssignmentDeployment'
  scope:subscription(subscriptionToEnable)
  params: {
    principalId: automation.outputs.systemAssignedIdentityId  // Pass the automation account's system-assigned identity ID as the principalId
  }
}

// Outputs for reference
output automationAccountName string = automationAccountName
output systemAssignedIdentityId string = automation.outputs.systemAssignedIdentityId
