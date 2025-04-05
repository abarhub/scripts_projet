# Paramètres

. "liste_projet.ps1"
$versionPom = Get-Projets "." | Where-Object -Property Type -eq 'maven' | Get-Pom | Select -ExpandProperty Version -first 1
Write-Host "version: $versionPom"
$versionPom2 = $versionPom -replace '-SNAPSHOT',''
Write-Host "version2: $versionPom2"
$versionMajor, $versionMinor, $versionMinor2 = ($versionPom2 -split '\.')
Write-Host "versionMajor: $versionMajor, versionMinor: $versionMinor, versionMinor2: $versionMinor2"
$version01=""+([int]$versionMajor +1)+"."+ $versionMinor+"."+ $versionMinor2+'-SNAPSHOT'
$version02=$versionMajor+"."+ ([int]$versionMinor +1)+"."+ $versionMinor2+'-SNAPSHOT'
$version03=$versionMajor+"."+ $versionMinor+"."+ ([int]$versionMinor2 +1)+'-SNAPSHOT'
Write-Host "version01: $version01"
Write-Host "version02: $version02"
Write-Host "version03: $version03"

function Afficher-Menu {
    Clear-Host
    Write-Host "===== MENU PRINCIPAL ====="
    Write-Host "1. $version01"
    Write-Host "2. $version02"
    Write-Host "3. $version03"
    Write-Host "4. Autre"
    Write-Host "5. Quitter le programme"
    Write-Host "=========================="
}

function Modification ($versionChoisie) {
    Invoke-Expression "D:\projet\scripts_projet\update_version.ps1 -ligneCible 13 -version $versionChoisie"
}

function Option ($versionChoisie) {
    Write-Host "Version : $versionChoisie"
    Modification $versionChoisie
    Read-Host "Appuyez sur Entrée pour continuer"
}


function Option-ChoixVersion {
    $versionChoisi = Read-Host "Quelle version ?"
    Modification $versionChoisi
    Read-Host "Appuyez sur Entrée pour continuer"
}

do {
    Afficher-Menu
    $choix = Read-Host "Entrez le numéro de l'option désirée"

    switch ($choix) {
        '1' { 
            Option $version01 
            exit 0
            }
        '2' { 
            Option $version02 
            exit 0
            }
        '3' { 
            Option $version03 
            exit 0
            }
        '4' { 
            Option-ChoixVersion 
            exit 0
            }
        '5' { 
            Write-Host "Au revoir !"
            break 
        }
        default { 
            Write-Host "Option invalide. Veuillez réessayer."
            Start-Sleep -Seconds 2 
        }
    }
} while ($choix -ne '5')
