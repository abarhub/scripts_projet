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


function Read-Version {
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
        }
    }

}

