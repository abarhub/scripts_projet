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



