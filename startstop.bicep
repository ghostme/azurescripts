
param location string = resourceGroup().location
param automationAccountName string = 'myAutomationAccount'
param runbookName string = 'ManageVMsRunbook'
param startScheduleName string = 'StartVMsSchedule'
param stopScheduleName string = 'StopVMsSchedule'
param startTime string = '2024-09-09T20:30:00-04:00'  // Set your desired start time (UTC)
param stopTime string = '2024-09-09T18:15:00-04:00'  // Set your desired stop time (UTC)


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
      uri: 'https://raw.githubusercontent.com/ghostme/azurescripts/main/startstopVM.ps1'
     
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
    frequency: 'Day'
    timeZone: 'Eastern Standard Time'  // Eastern Time Zone
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
  name:  guid(runbook.name)
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
  name: guid(runbook.id)
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
