param (
    [string]$Action  # "start" or "stop"
)

try {
    Connect-AzAccount -Identity
    Write-Output "Successfully authenticated using the system-assigned managed identity."
}
catch {
    Write-Error "Failed to authenticate with system-assigned managed identity. Error: $_"
    Exit 1
}
# $Action="stop"
# Define the tag to use for filtering and sorting VMs
$TagName = "StartupOrder"

# Define the maximum number of retries and wait time between retries (in seconds)
$MaxRetries = 30
$WaitTime = 20

# Enable error action preference to catch non-terminating errors
$ErrorActionPreference = "Stop"

# Function to start VMs in sequence based on tag order
function Start-TaggedVMsInSequence {
    try {
        # Get all VMs that are deallocated and have the specified tag
        $VMs = Get-AzVM -Status | Where-Object {$_.Tags.ContainsKey($TagName) -and $_.PowerState -eq 'VM deallocated'}

    } catch {
        Write-Error "Failed to retrieve the list of VMs: $_"
        return
    }

    # Sort the VMs by their tag value (numeric sequence, e.g., 1, 2, 3)
    $SortedVMs = $VMs | Sort-Object { [int]$_.Tags[$TagName] }

    foreach ($vm in $SortedVMs) {
        $tagValue = $vm.Tags[$TagName]
        Write-Output "Attempting to start VM: $($vm.Name) with tag value: $tagValue"
        
        try {
            # Start the VM
            Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -NoWait
        } catch {
            Write-Error "Failed to start VM $($vm.Name): $_"
            continue
        }

        # Custom wait loop to check VM status
        $retryCount = 0
        do {
            try {
                # Get the updated VM status
                $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            } catch {
                Write-Error "Failed to retrieve the status of VM $($vm.Name): $_"
                break
            }

            if ($vmStatus.Statuses[1].Code -eq 'PowerState/running') {
                Write-Output "VM $($vm.Name) is now running."
                break
            } else {
                Write-Output "Waiting for VM $($vm.Name) to start. Current state: $($vmStatus.Statuses[1].Code)"
                Start-Sleep -Seconds $WaitTime
                $retryCount++
            }

        } while ($retryCount -lt $MaxRetries)

        if ($retryCount -ge $MaxRetries) {
            Write-Error "Timeout waiting for VM $($vm.Name) to start."
        }
    }
}

# Function to stop VMs in reverse sequence based on tag order
function Stop-TaggedVMsInReverseSequence {
    try {
        # Get all VMs that are running and have the specified tag
        $VMs = Get-AzVM -Status | Where-Object {$_.Tags.ContainsKey($TagName) -and $_.PowerState -eq 'VM running'}

    } catch {
        Write-Error "Failed to retrieve the list of VMs: $_"
        return
    }

    # Sort the VMs by their tag value in descending order
    $SortedVMs = $VMs | Sort-Object { [int]$_.Tags[$TagName] } -Descending

    foreach ($vm in $SortedVMs) {
        $tagValue = $vm.Tags[$TagName]
        Write-Output "Attempting to stop VM: $($vm.Name) with tag value: $tagValue"
        
        try {
            # Stop the VM
            Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -NoWait
        } catch {
            Write-Error "Failed to stop VM $($vm.Name): $_"
            continue
        }

        # Custom wait loop to check VM status
        $retryCount = 0
        do {
            try {
                # Get the updated VM status
                $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            } catch {
                Write-Error "Failed to retrieve the status of VM $($vm.Name): $_"
                break
            }

            if ($vmStatus.Statuses[1].Code -eq 'PowerState/deallocated') {
                Write-Output "VM $($vm.Name) is now stopped."
                break
            } else {
                Write-Output "Waiting for VM $($vm.Name) to stop. Current state: $($vmStatus.Statuses[1].Code)"
                Start-Sleep -Seconds $WaitTime
                $retryCount++
            }

        } while ($retryCount -lt $MaxRetries)

        if ($retryCount -ge $MaxRetries) {
            Write-Error "Timeout waiting for VM $($vm.Name) to stop."
        }
    }
}

# Main logic to determine whether to start or stop VMs
try {
    if ($Action -eq 'start') {
        Write-Output "Starting VMs based on tag order..."
        Start-TaggedVMsInSequence
    } elseif ($Action -eq 'stop') {
        Write-Output "Stopping VMs based on reverse tag order..."
        Stop-TaggedVMsInReverseSequence
    } else {
        Write-Error "Invalid action. Please use 'start' or 'stop'."
    }
} catch {
    Write-Error "An error occurred during the execution of the script: $_"
}
