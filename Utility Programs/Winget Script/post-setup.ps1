# Windows 11 WinGet Installer with Arrow Navigation
# This script creates a console-based UI for selecting and installing applications via winget
# Navigate with arrow keys, select with spacebar, and press Enter to install selected apps

function Show-Menu {
    param (
        [string]$Title = 'WinGet Package Installer',
        [array]$Categories,
        [hashtable]$Applications,
        [array]$SelectedApps
    )
    
    $currentIndex = 0
    $displayOffset = 0
    $maxDisplay = [Console]::WindowHeight - 7  # Leaving room for header and footer
    $totalItems = $Categories.Count + ($Applications.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    
    # Function to redraw the menu
    function Redraw-Menu {
        [Console]::Clear()
        
        # Title
        Write-Host "`n $Title" -ForegroundColor Cyan
        Write-Host " ===================================================" -ForegroundColor DarkGray
        Write-Host " Navigate: [↑/↓] | Select: [Spacebar] | Install: [Enter] | Quit: [Esc]" -ForegroundColor Yellow
        Write-Host " ===================================================" -ForegroundColor DarkGray
        
        # Calculate display window
        if ($currentIndex -lt $displayOffset) {
            $displayOffset = $currentIndex
        }
        elseif ($currentIndex -ge ($displayOffset + $maxDisplay)) {
            $displayOffset = $currentIndex - $maxDisplay + 1
        }
        
        # Display counter
        $displayEnd = [Math]::Min($displayOffset + $maxDisplay, $totalItems)
        Write-Host " Showing $($displayOffset + 1)-$displayEnd of $totalItems items" -ForegroundColor DarkGray
        
        # Items
        $itemIndex = 0
        $displayIndex = 0
        
        foreach ($category in $Categories) {
            if ($itemIndex -ge $displayOffset -and $displayIndex -lt $maxDisplay) {
                if ($itemIndex -eq $currentIndex) {
                    Write-Host " > $category" -ForegroundColor Magenta -BackgroundColor DarkGray
                }
                else {
                    Write-Host "   $category" -ForegroundColor Magenta
                }
                $displayIndex++
            }
            $itemIndex++
            
            foreach ($app in $Applications[$category]) {
                if ($itemIndex -ge $displayOffset -and $displayIndex -lt $maxDisplay) {
                    $selected = $SelectedApps -contains $app.ID
                    $selectionMarker = if ($selected) { "[X]" } else { "[ ]" }
                    
                    if ($itemIndex -eq $currentIndex) {
                        Write-Host " > $selectionMarker $($app.Name)" -ForegroundColor White -BackgroundColor DarkBlue
                    }
                    else {
                        if ($selected) {
                            Write-Host "   $selectionMarker $($app.Name)" -ForegroundColor Green
                        }
                        else {
                            Write-Host "   $selectionMarker $($app.Name)" -ForegroundColor Gray
                        }
                    }
                    $displayIndex++
                }
                $itemIndex++
            }
        }
        
        # Footer
        Write-Host " ===================================================" -ForegroundColor DarkGray
        Write-Host " Selected: $($SelectedApps.Count) packages" -ForegroundColor Cyan
    }
    
    # Initial draw
    Redraw-Menu
    
    # Handle keypresses
    while ($true) {
        $keyInfo = [Console]::ReadKey($true)
        
        switch ($keyInfo.Key) {
            # Navigation
            UpArrow {
                if ($currentIndex -gt 0) {
                    $currentIndex--
                    Redraw-Menu
                }
            }
            DownArrow {
                if ($currentIndex -lt $totalItems - 1) {
                    $currentIndex++
                    Redraw-Menu
                }
            }
            PageUp {
                $currentIndex = [Math]::Max(0, $currentIndex - $maxDisplay)
                Redraw-Menu
            }
            PageDown {
                $currentIndex = [Math]::Min($totalItems - 1, $currentIndex + $maxDisplay)
                Redraw-Menu
            }
            Home {
                $currentIndex = 0
                Redraw-Menu
            }
            End {
                $currentIndex = $totalItems - 1
                Redraw-Menu
            }
            
            # Selection
            Spacebar {
                # Find the item at current index
                $itemIndex = 0
                $categoryName = $null
                $selectedApp = $null
                
                foreach ($category in $Categories) {
                    if ($itemIndex -eq $currentIndex) {
                        # Selecting/deselecting all apps in category
                        $categoryName = $category
                        break
                    }
                    $itemIndex++
                    
                    foreach ($app in $Applications[$category]) {
                        if ($itemIndex -eq $currentIndex) {
                            $selectedApp = $app
                            break
                        }
                        $itemIndex++
                    }
                    
                    if ($selectedApp) { break }
                }
                
                if ($categoryName) {
                    # Toggle all apps in the category
                    $allSelected = $true
                    foreach ($app in $Applications[$categoryName]) {
                        if ($SelectedApps -notcontains $app.ID) {
                            $allSelected = $false
                            break
                        }
                    }
                    
                    if ($allSelected) {
                        # Deselect all apps in category
                        foreach ($app in $Applications[$categoryName]) {
                            $SelectedApps = $SelectedApps | Where-Object { $_ -ne $app.ID }
                        }
                    }
                    else {
                        # Select all apps in category
                        foreach ($app in $Applications[$categoryName]) {
                            if ($SelectedApps -notcontains $app.ID) {
                                $SelectedApps += $app.ID
                            }
                        }
                    }
                }
                elseif ($selectedApp) {
                    # Toggle individual app
                    if ($SelectedApps -contains $selectedApp.ID) {
                        $SelectedApps = $SelectedApps | Where-Object { $_ -ne $selectedApp.ID }
                    }
                    else {
                        $SelectedApps += $selectedApp.ID
                    }
                }
                
                Redraw-Menu
            }
            
            # Action
            Enter {
                return $SelectedApps
            }
            
            # Exit
            Escape {
                return @()
            }
        }
    }
}

function Get-ApplicationDetails {
    # Define categories and applications with their winget IDs based on your list
    $categories = @(
        "Browsers",
        "Compression",
        "Media",
        "Utilities",
        "Productivity"
    )
    
    $applications = @{
        "Browsers"      = @(
            @{Name = "Mozilla Firefox"; ID = "Mozilla.Firefox"},
            @{Name = "Floorp"; ID = "Ablaze.Floorp"},
            @{Name = "LibreWolf"; ID = "LibreWolf.LibreWolf"}
        );
        "Compression"   = @(
            @{Name = "7-Zip"; ID = "7zip.7zip"},
            @{Name = "WinRAR"; ID = "RARLab.WinRAR"}
        );
        "Media"     = @(
            @{Name = "Audacity"; ID = "Audacity.Audacity"},
            @{Name = "Spotify"; ID = "Spotify.Spotify"},
            @{Name = "VLC Media Player"; ID = "VideoLAN.VLC"}
        );
        "Utilities" = @(
            @{Name = "EarTrumpet"; ID = "File-New-Project.EarTrumpet"},
            @{Name = "Everything"; ID = "voidtools.Everything"},
            @{Name = "LocalSend"; ID = "LocalSend.LocalSend"},
            @{Name = "Open-Shell Menu"; ID = "Open-Shell.Open-Shell-Menu"},
            @{Name = "PowerToys"; ID = "Microsoft.PowerToys"},
            @{Name = "TeraCopy"; ID = "CodeSector.TeraCopy"},
            @{Name = "UniGetUI"; ID = "MartiCliment.UniGetUI"}
        );
        "Productivity"      = @(
            @{Name = "Notepad++"; ID = "Notepad++.Notepad++"},
            @{Name = "Microsoft Whiteboard"; ID = "9NHL4NSC67WM"}
        )
    }
    
    return $categories, $applications
}

function Install-SelectedApplications {
    param (
        [array]$SelectedAppIDs,
        [hashtable]$Applications
    )
    
    if ($SelectedAppIDs.Count -eq 0) {
        Write-Host "`n No applications selected for installation. Exiting..." -ForegroundColor Yellow
        return
    }
    
    # Create a lookup for application names by ID
    $appNames = @{}
    foreach ($category in $Applications.Keys) {
        foreach ($app in $Applications[$category]) {
            $appNames[$app.ID] = $app.Name
        }
    }
    
    # Display selected applications
    Write-Host "`n Installing $($SelectedAppIDs.Count) applications:" -ForegroundColor Cyan
    foreach ($appID in $SelectedAppIDs) {
        Write-Host " - $($appNames[$appID]) ($appID)" -ForegroundColor Yellow
    }
    
    # Create log file
    $logPath = "$env:TEMP\winget_installer_log.txt"
    "WinGet Installation Log - $(Get-Date)" | Out-File -FilePath $logPath -Force
    
    # Install applications
    $totalApps = $SelectedAppIDs.Count
    $currentApp = 0
    
    foreach ($appID in $SelectedAppIDs) {
        $currentApp++
        $appName = $appNames[$appID]
        
        Write-Host "`n [$currentApp/$totalApps] Installing $appName..." -ForegroundColor Cyan
        
        # Log the installation command
        "[$currentApp/$totalApps] Installing $appName ($appID)..." | Out-File -FilePath $logPath -Append
        
        try {
            Write-Host " Running: winget install -e --id $appID --accept-source-agreements --accept-package-agreements" -ForegroundColor DarkGray
            
            # Execute winget command
            $process = Start-Process -FilePath "winget" -ArgumentList "install -e --id $appID --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host " Successfully installed $appName." -ForegroundColor Green
                "Installation successful." | Out-File -FilePath $logPath -Append
            }
            else {
                Write-Host " Failed to install $appName (Exit code: $($process.ExitCode))." -ForegroundColor Red
                "Installation failed with exit code: $($process.ExitCode)" | Out-File -FilePath $logPath -Append
            }
        }
        catch {
            Write-Host " Error installing $appName : $_" -ForegroundColor Red
            "Error: $_" | Out-File -FilePath $logPath -Append
        }
        
        "-----------------------------------------" | Out-File -FilePath $logPath -Append
    }
    
    Write-Host "`n Installation process completed. Log file saved to:" -ForegroundColor Green
    Write-Host " $logPath" -ForegroundColor Cyan
    Write-Host "`n Press any key to exit..." -ForegroundColor Yellow
    $null = [Console]::ReadKey($true)
}

function Check-WinGet {
    Write-Host "Checking for WinGet..." -ForegroundColor Cyan
    try {
        $null = & winget --version
        Write-Host "WinGet is installed. Ready to continue." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error: WinGet is not installed or not working on this system." -ForegroundColor Red
        Write-Host "Please make sure the App Installer package is installed from the Microsoft Store." -ForegroundColor Yellow
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = [Console]::ReadKey($true)
        return $false
    }
}

# Function to run Windows activation
function Run-WindowsActivation {
    Write-Host "`n Running Windows activation script..." -ForegroundColor Cyan
    
    try {
        # Create a log entry
        "Windows Activation - $(Get-Date)" | Out-File -FilePath "$env:TEMP\winget_installer_log.txt" -Append
        
        # Run the activation command
        Write-Host " Downloading and executing activation script..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri "https://get.activated.win" | Invoke-Expression
        
        Write-Host " Activation script completed." -ForegroundColor Green
        "Activation script completed." | Out-File -FilePath "$env:TEMP\winget_installer_log.txt" -Append
    }
    catch {
        Write-Host " Error running activation script: $_" -ForegroundColor Red
        "Error running activation script: $_" | Out-File -FilePath "$env:TEMP\winget_installer_log.txt" -Append
    }
    
    Write-Host "`n Press any key to continue..." -ForegroundColor Yellow
    $null = [Console]::ReadKey($true)
}

# Main script
[Console]::CursorVisible = $false
try {
    # Check if WinGet is installed
    if (-not (Check-WinGet)) {
        exit
    }
    
    # Main menu
    while ($true) {
        Clear-Host
        Write-Host "`n Windows Setup Helper" -ForegroundColor Cyan
        Write-Host " ===================================================" -ForegroundColor DarkGray
        Write-Host " 1. Install Applications" -ForegroundColor Yellow
        Write-Host " 2. Run Windows Activation" -ForegroundColor Yellow
        Write-Host " 3. Exit" -ForegroundColor Yellow
        Write-Host " ===================================================" -ForegroundColor DarkGray
        
        Write-Host "`n Select an option (1-3): " -ForegroundColor Cyan -NoNewline
        $choice = [Console]::ReadKey($true).KeyChar
        
        switch ($choice) {
            '1' {
                # Get application details
                $categories, $applications = Get-ApplicationDetails
                
                # Show menu and get selected applications
                $selectedAppIDs = Show-Menu -Categories $categories -Applications $applications -SelectedApps @()
                
                # Install selected applications
                Install-SelectedApplications -SelectedAppIDs $selectedAppIDs -Applications $applications
            }
            '2' {
                # Run Windows activation
                Run-WindowsActivation
            }
            '3' {
                # Exit
                exit
            }
            default {
                Write-Host "`n Invalid option. Press any key to continue..." -ForegroundColor Red
                $null = [Console]::ReadKey($true)
            }
        }
    }
}
finally {
    [Console]::CursorVisible = $true
}
