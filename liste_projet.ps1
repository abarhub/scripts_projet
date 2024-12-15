function Get-ListProjet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="Chemin du r�pertoire. Par d�faut, r�pertoire courant.")]
        [string]$Path = (Get-Location).Path
    )

    process {
        if (-not (Test-Path -Path $Path -PathType Container)) {
            Write-Error "Le chemin sp�cifi� '$Path' n'existe pas ou n'est pas un r�pertoire."
            return
        }

        Get-ChildItem -Path $Path -Directory | Select-Object Name, FullName, CreationTime
    }
}

function Add-Numbers {
  $args[0] + $args[1]
}


function Read-Pom {
    $file=$args[0]
    [xml]$xml = Get-Content $file

    $xml.project | ForEach-Object {
        [PSCustomObject]@{
            'GroupId' = $_.groupId
            'ArtifactId'    = $_.artifactId
            'Version'    = $_.version
            'GroupIdParent' = $_.parent.groupId
            'ArtifactIdParent'    = $_.parent.artifactId
            'VersionParent'    = $_.parent.version
            'Name'=$_.name
            'Description'=$_.description
            'JavaVersion'=$_.properties.'java.version'
            'Path'=$file
        }
    }

}

function Read-Pom-Dependencies {
    $file=$args[0]
    [xml]$xml = Get-Content $file

    $xml.project.dependencies.dependency | ForEach-Object {
        [PSCustomObject]@{
            'GroupId' = $_.groupId
            'ArtifactId'    = $_.artifactId
            'Version'    = $_.version
            'Scope' = $_.scope
            'Path'=$file
        }

    }
}


function Read-Package {
    $file=$args[0]
    $json = Get-Content $file | ConvertFrom-Json 

    $json | ForEach-Object {
        [PSCustomObject]@{
            'Name' = $_.name
            'Version'    = $_.version
            'Path'=$file
        }
    }

}

function Read-Package-Dependencies {
    $file=$args[0]
    $json = Get-Content $file | ConvertFrom-Json 

    $table1=$json.dependencies.psobject.properties | ForEach-Object {
        [PSCustomObject]@{
            'Name' = $_.name
            'Version'    = $_.value
            'Path'=$file
            'dev'= 0
        }
    }

    $table2=$json.devDependencies.psobject.properties | ForEach-Object {
        [PSCustomObject]@{
            'Name' = $_.name
            'Version'    = $_.value
            'Path'=$file
            'dev'= 1
        }
    }

    $CombinedTable = @()
    $CombinedTable += $table1
    $CombinedTable += $table2

    return $CombinedTable
}

function Get-GitBranchInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath
    )

    # V�rification si le chemin sp�cifi� est un d�p�t Git
    if (-not (Test-Path "$RepositoryPath\.git")) {
        Write-Error "$RepositoryPath n'est pas un d�p�t Git valide."
        return
    }

    # Enregistrement du r�pertoire actuel pour y revenir ensuite
    $currentPath = Get-Location
    Set-Location -Path $RepositoryPath

    try {
        # Effectuer un fetch pour s'assurer que les donn�es sont � jour
        git fetch 2>$null

        # R�cup�ration des informations n�cessaires
        $branchName = git rev-parse --abbrev-ref HEAD 2>$null
        $branchDate = git log -1 --format="%ci" 2>$null
        $commitHash = git rev-parse HEAD 2>$null
        $shortCommitHash = git rev-parse --short HEAD 2>$null
        $commitMessage = git log -1 --format="%s" 2>$null
        $status = git status --porcelain=2 --branch 2>$null

        # Analyse des informations sur la synchronisation avec la branche distante
        $isUpToDate = $false
        $hasModifications = $false
        $behind = $status -match "behind ([0-9]+)"
        $ahead = $status -match "ahead ([0-9]+)"

        if (-not $behind -and -not $ahead) {
            $isUpToDate = $true
        }

        # V�rifier les modifications locales
        if ($status -match "1 .*") {
            $hasModifications = $true
        }

        # Construire l'objet de sortie
        $branchInfo = [PSCustomObject]@{
            BranchName        = $branchName
            BranchDate        = $branchDate
            CommitHash        = $commitHash
            ShortCommitHash   = $shortCommitHash
            CommitMessage     = $commitMessage
            HasModifications  = $hasModifications
            IsUpToDate        = $isUpToDate
        }

        return $branchInfo

    } catch {
        Write-Error "Une erreur s'est produite : $_"
    } finally {
        # Retourner au r�pertoire initial
        Set-Location -Path $currentPath
    }
}


function Explore-Arborescence {
    param (
        [string]$Path,
        [ref]$Results, # R�f�rence � la liste pour accumuler les r�sultats
        [bool]$ArretPremierTrouve = $true,
        [string]$NomProjet="",
        [string[]]$Exclusion=@()
    )

    # V�rifie si 'pom.xml' ou 'package.json' existe dans le r�pertoire courant
    $PomFile = Join-Path $Path "pom.xml"
    $PackageFile = Join-Path $Path "package.json"

    if (Test-Path -Path $PomFile -PathType Leaf -ErrorAction SilentlyContinue) {
        if ([string]::IsNullOrEmpty($NomProjet)){
            $NomProjet = Split-Path -Path $Path -Leaf
        }
        $Results.Value += [PSCustomObject]@{
            FullPath= $PomFile
            FileName = "pom.xml"
            Type = 'maven'
            Dir = $Path
            NomProjet=$NomProjet
        }
        #Write-Output "Fichier trouv� : $PomFile"
        if ($ArretPremierTrouve){
            return
        }
    }
    if (Test-Path -Path $PackageFile -PathType Leaf -ErrorAction SilentlyContinue) {
        if ([string]::IsNullOrEmpty($NomProjet)){
            $NomProjet = Split-Path -Path $Path -Leaf
        }
        $Results.Value += [PSCustomObject]@{
            FullPath= $PackageFile
            FileName = "package.json"
            Type = 'node'
            Dir = $Path
            NomProjet=$NomProjet
        }
        #Write-Output "Fichier trouv� : $PackageFile"
        if ($ArretPremierTrouve) {
            return
        }
    }

    # R�cup�re les sous-r�pertoires en excluant 'target' et 'node_modules'
    $SubDirectories = Get-ChildItem -Path $Path -Directory -Exclude $Exclusion -ErrorAction SilentlyContinue

    foreach ($SubDir in $SubDirectories) {
        # Appel r�cursif pour explorer les sous-r�pertoires
        Explore-Arborescence -Path $SubDir.FullName -Results $Results -ArretPremierTrouve $ArretPremierTrouve -NomProjet $NomProjet -Exclusion $Exclusion
    }
}

function Get-Projets {
    param (
        [string]$RootPath="",
        [bool]$ArretPremierTrouve = $true,   
        [string[]]$Exclusion=@()     
    )

    $FoundFiles = @() # Liste pour stocker les r�sultats
    $RefResults = [ref]$FoundFiles

    $config=Get-Config
    $rep=$config["repertoire"]
    $excl=$config["exclusion"]
    #Write-Output "rep : $rep"
    #Write-Output "excl : $excl"
    if ([string]::IsNullOrEmpty($RootPath)){
        if (![string]::IsNullOrEmpty($rep)){
            $RootPath=$rep
        }
    }
    if ($Exclusion.Length -eq 0){
        if ($excl.Length -ne 0){
            $Exclusion=$excl
        } else {
            $Exclusion=@("target", "node_modules","node",".venv",".venv2","venv")
        }
    }

    #Write-Output "RootPath : $RootPath"
    #Write-Output "Exclusion : $Exclusion"

    Explore-Arborescence -Path $RootPath -Results $RefResults -ArretPremierTrouve $ArretPremierTrouve -Exclusion $Exclusion

    $FoundFiles
}

function Lire-Fichier {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CheminFichier
    )

    # V�rifie si le fichier existe
    if (-not (Test-Path -Path $CheminFichier)) {
        throw "Le fichier '$CheminFichier' n'existe pas."
    }

    # Lit le fichier ligne par ligne
    $contenu = Get-Content -Path $CheminFichier

    # Initialise un dictionnaire pour stocker les cl�s/valeurs
    $resultat = @{}

    foreach ($ligne in $contenu) {
        if ($ligne -match "^(?<cle>\w+)\=(?<valeur>.+)$") {
            $cle = $matches['cle']
            $valeur = $matches['valeur']

            if ($cle -eq "exclusion") {
                # Convertit la valeur de "exclusion" en tableau
                $resultat[$cle] = $valeur -split ","
            } else {
                # Stocke la valeur normalement
                $resultat[$cle] = $valeur
            }
        }
    }

    # V�rifie si les cl�s obligatoires sont pr�sentes
    if (-not $resultat.ContainsKey("repertoire")) {
        throw "La cl� 'repertoire' est manquante dans le fichier."
    }

    if (-not $resultat.ContainsKey("exclusion")) {
        throw "La cl� 'exclusion' est manquante dans le fichier."
    }

    # Retourne l'objet contenant les r�sultats
    return $resultat
}

function Get-Config {

    return Lire-Fichier "~\Documents\config_projets.properties"
}

function Get-Pom {
    param (
        [Parameter(ValueFromPipeline)]  # Permet de recevoir les donn�es du pipeline
        $InputItem,
        [bool]$Dependances = $false
    )
    process {
        [xml]$xml = Get-Content $InputItem.FullPath

        if ($Dependances) {
            $xml.project.dependencies.dependency | ForEach-Object {
                [PSCustomObject]@{
                    'GroupId' = $_.groupId
                    'ArtifactId'    = $_.artifactId
                    'Version'    = $_.version
                    'Scope' = $_.scope
                    'Path'=$InputItem.FullPath
                }

            }
        } else {
            $xml.project | ForEach-Object {
                [PSCustomObject]@{
                    'GroupId' = $_.groupId
                    'ArtifactId'    = $_.artifactId
                    'Version'    = $_.version
                    'GroupIdParent' = $_.parent.groupId
                    'ArtifactIdParent'    = $_.parent.artifactId
                    'VersionParent'    = $_.parent.version
                    'Name'=$_.name
                    'Description'=$_.description
                    'JavaVersion'=$_.properties.'java.version'
                    'Path'=$InputItem.FullPath
                }
            }
        }

        
    
    }
}


function Get-Package {
    param (
        [Parameter(ValueFromPipeline)]  # Permet de recevoir les donn�es du pipeline
        $InputItem,
        [bool]$Dependances = $false
    )
    process {
        $json = Get-Content $InputItem.FullPath | ConvertFrom-Json 

        if ($Dependances) {

            $table1=$json.dependencies.psobject.properties | ForEach-Object {
                [PSCustomObject]@{
                    'Name' = $_.name
                    'Version'    = $_.value
                    'Path'=$InputItem.FullPath
                    'dev'= 0
                }
            }

            $table2=$json.devDependencies.psobject.properties | ForEach-Object {
                [PSCustomObject]@{
                    'Name' = $_.name
                    'Version'    = $_.value
                    'Path'=$InputItem.FullPath
                    'dev'= 1
                }
            }

            $CombinedTable = @()
            $CombinedTable += $table1
            $CombinedTable += $table2

            return $CombinedTable

        } else {
            $json | ForEach-Object {
                [PSCustomObject]@{
                    'Name' = $_.name
                    'Version'    = $_.version
                    'Path'=$InputItem.FullPath
                }
            }

        }
    }
}

function Get-Git {
    param (
        [Parameter(ValueFromPipeline)]  # Permet de recevoir les donn�es du pipeline
        $InputItem        
    )
    process {
        Get-GitBranchInfo $InputItem.Dir
    }

}
