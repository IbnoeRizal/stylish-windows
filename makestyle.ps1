$loader = 0

#you can download these app manually for free using winget 
$daftar_app = @(
    @{
        name      = "TERMINAL"
        id        = "Microsoft.WindowsTerminal"
        installed = $false
        deskripsi = "Terminal modern"
    }

    @{
        name      = "POWERSHELL"
        id        = "Microsoft.PowerShell"
        installed = $false
        deskripsi = "powershell terbaru modern"
    }

    @{
        name      = "YASB"; 
        id        = "AmN.yasb"; 
        installed = $false; 
        deskripsi = "status bar" 
    }

    @{
        name      = "KOMOREBI";
        id        = "LGUG2Z.komorebi"; 
        installed = $false; 
        deskripsi = "tiling windows manager opsional" 
    }

    @{
        name      = "WHKD"; 
        id        = "LGUG2Z.whkd"; 
        installed = $false; 
        deskripsi = "key binding untuk komorebi" 
    }

    @{
        name      = "POSH"; 
        id        = "JanDeDobbeleer.OhMyPosh"; 
        installed = $false; 
        deskripsi = "status di powershell" 
    }

    @{
        name      = "NEOVIM"; 
        id        = "Neovim.Neovim"; 
        installed = $false; 
        deskripsi = "text editor GUI shell" 
    }
)

function chekker {
    $wanna_install = winget list | Out-String
   
    foreach ($app in $daftar_app) {
        $loader ++

        if ($wanna_install -match $app.name ) {
            Write-host "$($app.name) sudah terinstall" -ForegroundColor Green 
            $app.installed = $true
        }
        else {
            Write-host "aplikasi $($app.name) belum terinstall" -ForegroundColor Red
        }

        Write-Progress -Activity "Checking installed applications" -Status "Checking $($app.name)" -PercentComplete ($loader * 100 / $daftar_app.Count)
        Start-Sleep -Milliseconds 100
    }
    $loader = 0
}

function install {
    $loader ++
    foreach ($app in $daftar_app) {
        if ($app.installed) {
            $loader ++
            continue  
        }
        
        if ($app.name -eq "KOMOREBI" -or $app.name -eq "NEOVIM" ) {
            write-host "apakah anda ingin menginstall $($app.name) (opsional) `n deskripsi: $($app.deskripsi)"
            $jawab = Read-Host "(y/n)" 

            if ( $jawab -notmatch "y|Y") {
                $loader ++
                continue
            }

        }elseif ($app.name -eq "WHKD") {
            $komorebi = $daftar_app | Where-Object { $_.name -eq "KOMOREBI" }
            if (-not $komorebi.installed) {
                $loader ++
                continue
            }
        }

        switch ($app.name) {
            "YASB" { 
                fontdownload -no 0
            }
            "POSH" {
                fontdownload -no 1
            }
        }

        write-progress -Id 1 -Activity "installing" -Status "$($app.name) deskripsi: $($app.deskripsi)" -PercentComplete ($loader * 100 / $daftar_app.Count)
        winget install --id $app.id -e 
        $app.installed = $true

        $loader ++
    }
    $loader = 0
}


function konfig {
    $loader ++
    foreach ($app in $daftar_app) {

        if (-not $app.installed) {
            $loader ++
            continue
        }
        write-progress -Activity "configuring" -status "$($app.name)" -PercentComplete ($loader * 100 / $daftar_app.Count)
        
        switch ($app.name) {
            "YASB" { 
                yasbc start
                yasbc enable-autostart
            }
            "KOMOREBI" {
                #configure komorebi and whkd

                Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
                
                if ($daftar_app | Where-Object { $_.name -eq "YASB" -and $_.installed }) {
                    komorebic enable-autostart --whkd
                    komorebic start --whkd
                }
                else {
                    komorebic enable-autostart --whkd --bar
                    komorebic start --whkd --bar
                }

                #setup bar
                $path = "$env:USERPROFILE\komorebi.bar.json"
                if(test-path -path $path){
                    $jsonst = get-content -Path $path | convertfrom-json
                    
                    $jsonst.left_widgets[0].Komorebi.workspaces.hide_empty_workspaces = $true
                    $jsonst.right_widgets[2].Storage.enable = $false
                    $jsonst.right_widgets[4].Network.show_total_data_transmitted = $false
                    $jsonst.right_widgets[4].Network.show_network_activity = $false
                    
                    $jsonst | ConvertTo-Json -Depth 10 | set-content -Path $path
                }

                #configure komorebi tiling windws behavior
                $path = "$env:USERPROFILE\komorebi.json"
                if (Test-Path -Path $path){
                    $jsonst = get-content -Path $path | convertfrom-json
                    
                    $jsonst.default_workspace_padding = 10
                    $jsonst.default_container_padding = 4
                    $jsonst.border = $false
                    $jsonst.border_width = 8
                    $jsonst.border_offset = -1
                    
                    $jsonst | ConvertTo-Json -Depth 10 | Set-Content -Path $path
                }

                    
            }
            "POSH" {
                New-Item -Path $PROFILE -ItemType File -Force
                Add-Content -Path $PROFILE -Value 'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression'
            }
            "TERMINAL" {
                $path = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

                $datajson = get-content -Path $path | convertfrom-json
                
                #profile default setup
                 $datajson.profiles.defaults = @{
                    adjustIndistinguishableColors = "indexed"
                    backgroundImage = $null
                    font = @{
                        face = "CaskaydiaCove Nerd Font"
                        builtinGlyph = $false  
                    }
                    opacity = 45
                    scrollbarState = "hidden"
                    useAcrylic = $true
                }
                
                $datajson.useAcrylicInTabRow = $true

                $datajson | ConvertTo-Json -Depth 10 | Set-Content -Path $path 

            }
            
        }

        $loader ++
        Start-Sleep -Milliseconds 200
    }
    $loader = 0
}


function fontdownload {
    param (
        [int]$no
    )
    #yasb membutuhkan font jetbrains 
    #posh membutuhkan font caskaydiacove

    $fontUrls = @(
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip", 
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip"   
    )

    $fontName = @("JetBrainsMono", "CascadiaCode")
    
    $fontZipPath = "$env:TMP\$($fontName[$no]).zip"
    $fontExtractPath = "$env:TMP\$($fontName[$no])"
    $fontsFolder = "$env:WINDIR\Fonts"
    
    $alreadyInstalled = Get-ChildItem $fontsFolder -Filter "*$($fontName[$no])*" | Where-Object { $_.Extension -eq ".ttf" }
    
    if ($alreadyInstalled) {
        Write-Host "$($fontName[$no]) sudah terinstal. Lewati instalasi." -ForegroundColor Yellow
        return
    }
    
    # Unduh font
    if (-not ((Test-Path $fontZipPath) -or (Test-Path $fontExtractPath))) {
        Write-Host "Mengunduh $($fontName[$no]) Nerd Font..."
        Invoke-WebRequest -Uri $fontUrls[$no] -OutFile $fontZipPath -UseBasicParsing
    }
    
    # Ekstrak file ZIP
    if (-not (Test-Path $fontExtractPath)) {
        Write-Host "Mengekstrak font..."
        Expand-Archive -Path $fontZipPath -DestinationPath $fontExtractPath -Force
    }
    
    # Instal font
    Write-Host "Menginstal font..."
    $fontFiles = Get-ChildItem -Path $fontExtractPath -Filter "*.ttf" -Recurse

    $load ++
    foreach ($fontFile in $fontFiles) {
        Write-Progress -Id 2 -Activity "Menginstal" -Status "$($fontFile.Name)" -PercentComplete ($load * 100 / $fontFiles.Count)
        Copy-Item -Path $fontFile.FullName -Destination $fontsFolder
        $load ++
    }
    $load = 0
    
    Write-Host "$($fontName[$no]) Nerd Font berhasil diinstal!" -ForegroundColor Blue 
}

#this delete function won't delete fonts wich it previously downloaded
#it will only delete the installed apps using winget
function delete {
    $loader ++
    foreach ($app in $daftar_app) {
        if ($app.installed) {
            winget uninstall --id $app.id
            Write-Progress -Activity "Deleting applications" -Status "$($app.name)" -PercentComplete ($loader * 100 / $daftar_app.Count)
        }
        $loader ++
    }
    $loader = 0
}

function main {
    
    param(
        [string]$option = $args[0]
    )

    if (-not( Get-CimInstance Win32_OperatingSystem | Where-Object { $_.Version -like "10.*" })) {
        write-host "Hanya mendukung Windows 10 dan yang lebih baru" -BackgroundColor Blue -ForegroundColor White
        exit 1
    }

    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Skrip ini membutuhkan hak Administrator!" -ForegroundColor Red
        exit 1
    }
    
    if (-not (get-command winget)){
        write-host "winget tidak ditemukan, silahkan install winget terlebih dahulu"
        exit 1
    }

    switch ($option) {
        "install" { 
            chekker
            install
            Start-Process -FilePath "pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -option konfig" -Verb RunAs -Wait
            exit 0
        }
         
        "konfig"{
            chekker
            konfig
            exit 0
        }

        "delete" {
            chekker
            delete
            exit 0
        }

        Default {
            Write-Host "makestyle -option 

                -option 
                
                    install 
                        : install required app using winget                  makestyle.ps1 install

                    delete
                        : delete all installed required app using winget     makestyle.ps1 delete

                    help
                        : show help option
            " -ForegroundColor Yellow
        }
    }

    
}

#starter callfunction
main 