
@description('Location where the resources will be deployed, defaults to the resource group\'s location.')
param location string = resourceGroup().location

@description('The name of the Automation Account.')
param automationAccountName string 

@description('The name of the runbook to manage VM start/stop actions.')
param runbookName string 

@description('The name of the schedule for starting VMs.')
param startScheduleName string

@description('The name of the schedule for stopping VMs.')
param stopScheduleName string 

@description('The time to start VMs (in UTC format, e.g., 2023-12-01T00:00:00Z).')
param startTime string

@description('The time to stop VMs (in UTC format, e.g., 2023-12-01T18:00:00Z).')
param stopTime string

@description('URI of the PowerShell script that the runbook will execute.')
param runbookScriptUri string


// Define the automation account
resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationAccountName
  location: location
 
  identity: {
    type: 'SystemAssigned'
  }
  properties: { 
    sku: {
    name: 'Basic'
  }}
}

// Define the runbook resource
resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: runbookName
  location: location
  properties: {
    description: 'Runbook to manage VM start/stop actions based on tags.'
    logProgress: true
    logVerbose: true
    runbookType: 'PowerShell'
    publishContentLink: {
      uri: runbookScriptUri
     
    }
  }
}

// Define the start schedule
resource startSchedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: startScheduleName
  properties: {
    description: 'Start VMs on a schedule'
    startTime: startTime
    expiryTime: '9999-12-31T23:59:59Z'  // Never expires
    interval: 1
    frequency: 'Week'
    timeZone: 'Eastern Standard Time'  // Eastern Time Zone
    advancedSchedule: {
      weekDays: [
        'Monday'
        'Tuesday'
        'Wednesday'
        'Thursday'
        'Friday'
      ]
  }
  }
}

// Define the stop schedule
resource stopSchedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
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
resource startJob 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  parent: automationAccount
  name:   guid(resourceGroup().id, runbook.name, startSchedule.name)
  properties: {
    schedule: {
      name: startSchedule.name
    }
    runbook: {
      name: runbook.name
    }
    parameters: {
      Action: 'start'  // Start action linked with start schedule
    }
  }
}

// Define the job schedule for stopping VMs
resource stopJob 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  parent: automationAccount
  name: guid(resourceGroup().id, runbook.name, stopSchedule.name)
  properties: {
    schedule: {
      name: stopSchedule.name
    }
    runbook: {
      name: runbook.name
    }
    parameters: {
      Action: 'stop'  // Stop action linked with stop schedule
    }
  }
}

output automationAccountName string = automationAccount.name
output runbookName string = runbook.name
output startScheduleName string = startSchedule.name
output stopScheduleName string = stopSchedule.name
output systemAssignedIdentityId string = automationAccount.identity.principalId
