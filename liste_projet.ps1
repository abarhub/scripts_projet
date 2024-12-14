function Get-ListProjet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="Chemin du répertoire. Par défaut, répertoire courant.")]
        [string]$Path = (Get-Location).Path
    )

    process {
        if (-not (Test-Path -Path $Path -PathType Container)) {
            Write-Error "Le chemin spécifié '$Path' n'existe pas ou n'est pas un répertoire."
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

    # Vérification si le chemin spécifié est un dépôt Git
    if (-not (Test-Path "$RepositoryPath\.git")) {
        Write-Error "$RepositoryPath n'est pas un dépôt Git valide."
        return
    }

    # Enregistrement du répertoire actuel pour y revenir ensuite
    $currentPath = Get-Location
    Set-Location -Path $RepositoryPath

    try {
        # Effectuer un fetch pour s'assurer que les données sont à jour
        git fetch 2>$null

        # Récupération des informations nécessaires
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

        # Vérifier les modifications locales
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
        # Retourner au répertoire initial
        Set-Location -Path $currentPath
    }
}




