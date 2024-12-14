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

function Read-Package-DevDependencies {
    $file=$args[0]
    $json = Get-Content $file | ConvertFrom-Json 

    $json.devDependencies.psobject.properties | ForEach-Object {
        [PSCustomObject]@{
            'Name' = $_.name
            'Version'    = $_.value
            'Path'=$file
        }
    }

}

