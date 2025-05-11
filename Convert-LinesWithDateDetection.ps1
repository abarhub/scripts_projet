#
# fonction pour découper les fichiers de log
#
# Exempels :
#
# Convert-LinesWithDateDetection -Path "chemin\vers\monfichier.txt"
#
#
# $lines = @(
#    "2023-05-01 Ligne 1",
#    "suite de ligne 1",
#    "2023-05-02 Ligne 2"
# )
# $lines | Convert-LinesWithDateDetection
#
#
# Convert-LinesWithDateDetection -Path "log.txt" | Out-File "log_nettoye.txt"
#
# 
# Convert-LinesWithDateDetection -Path "log.txt" | Select-String -Pattern "ERROR"
#


function Convert-LinesWithDateDetection {
    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    param (
        [Parameter(ParameterSetName = 'FromPipeline', ValueFromPipeline = $true)]
        [string[]]$InputObject,

        [Parameter(ParameterSetName = 'FromFile', Mandatory = $true)]
        [string]$Path
    )

    begin {
        $linesBuffer = @()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'FromPipeline') {
            $linesBuffer += $InputObject
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'FromFile') {
            if (-not (Test-Path $Path)) {
                Write-Error "Le fichier '$Path' n'existe pas."
                return
            }
            $linesBuffer = Get-Content -Path $Path
        }

        $datePattern1 = '^\d{4}-\d{2}-\d{2}'      # YYYY-MM-DD
        $datePattern2 = '^\d{2}/\d{2}/\d{4}'      # DD/MM/YYYY

        $formatDetected = $null
        for ($i = 0; $i -lt [math]::Min(5, $linesBuffer.Count); $i++) {
            if ($linesBuffer[$i] -match $datePattern1) {
                $formatDetected = $datePattern1
                break
            } elseif ($linesBuffer[$i] -match $datePattern2) {
                $formatDetected = $datePattern2
                break
            }
        }

        if (-not $formatDetected) {
            Write-Warning "Aucun format de date détecté dans les 5 premières lignes."
            $linesBuffer | ForEach-Object { Write-Output $_ }
            return
        }

        $currentLine = ""

        foreach ($line in $linesBuffer) {
            if ($line -match $formatDetected) {
                if ($currentLine -ne "") {
                    Write-Output $currentLine
                }
                $currentLine = $line
            } else {
                $currentLine += "`r`n" + $line
            }
        }

        if ($currentLine -ne "") {
            Write-Output $currentLine
        }
    }
}
