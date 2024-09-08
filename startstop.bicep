
param location string = resourceGroup().location
param automationAccountName string = 'myAutomationAccount'
param runbookName string = 'ManageVMsRunbook'
param startScheduleName string = 'StartVMsSchedule'
param stopScheduleName string = 'StopVMsSchedule'
param startTime string = '2024-09-08T06:00:00Z'  // Set your desired start time (UTC)
param stopTime string = '2024-09-08T18:00:00Z'  // Set your desired stop time (UTC)
param subscriptionId string = subscription().subscriptionId  // Subscription ID for role assignment

// Define the automation account
resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: location
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// Define the runbook resource
resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: runbookName
  location: location
  properties: {
    description: 'Runbook to manage VM start/stop actions based on tags.'
    logProgress: true
    logVerbose: true
    runbookType: 'PowerShell'
    draft: {
      inEdit: true
    }
    publishContentLink: {
      uri: 'https://your-storage-account.blob.core.windows.net/scripts/manage-vms.ps1'
      contentHash: {
        algorithm: 'SHA256'
        value: 'Your-script-content-hash'  // Add the appropriate content hash for the script
      }
    }
  }
}

// Define the start schedule
resource startSchedule 'Microsoft.Automation/automationAccounts/schedules@2015-10-31' = {
  parent: automationAccount
  name: startScheduleName
  properties: {
    description: 'Start VMs on a schedule'
    startTime: startTime
    expiryTime: '9999-12-31T23:59:59Z'  // Never expires
    interval: 1
    frequency: 'Day'
    timeZone: 'Eastern Standard Time'  // Eastern Time Zone
  }
}

// Define the stop schedule
resource stopSchedule 'Microsoft.Automation/automationAccounts/schedules@2015-10-31' = {
  parent: automationAccount
  name: stopScheduleName
  properties: {
    description: 'Stop VMs on a schedule'
    startTime: stopTime
    expiryTime: '9999-12-31T23:59:59Z'  // Never expires
    interval: 1
    frequency: 'Day'
    timeZone: 'Eastern Standard Time'  // Eastern Time Zone
  }
}

// Define the job schedule for starting VMs
resource startJob 'Microsoft.Automation/automationAccounts/jobSchedules@2015-10-31' = {
  parent: automationAccount
  name: '${automationAccountName}-StartJob'
  properties: {
    schedule: {
      name: startSchedule.name
    }
    runbook: {
      name: runbookName
    }
    parameters: {
      Action: 'start'  // Start action linked with start schedule
    }
  }
}

// Define the job schedule for stopping VMs
resource stopJob 'Microsoft.Automation/automationAccounts/jobSchedules@2015-10-31' = {
  parent: automationAccount
  name: '${automationAccountName}-StopJob'
  properties: {
    schedule: {
      name: stopSchedule.name
    }
    runbook: {
      name: runbookName
    }
    parameters: {
      Action: 'stop'  // Stop action linked with stop schedule
    }
  }
}

// // Role assignment for the system-assigned managed identity as Virtual Machine Contributor
// resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//   name: guid(subscription().id, 'Contributor')

//   properties: {
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')  // Virtual Machine Contributor role ID
//     principalId: automationAccount.identity.principalId  // Assign to the system-assigned identity
//     principalType: 'ServicePrincipal'
//   }
// }

output automationAccountName string = automationAccount.name
output runbookName string = runbook.name
output startScheduleName string = startSchedule.name
output stopScheduleName string = stopSchedule.name
