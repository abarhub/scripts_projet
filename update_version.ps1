# Paramètres
param(
    [Int32]$ligneCible=-1,
    # name of the output image
    [string]$version = '1.0.0-SNAPSHOT'
) 
$fichier = "pom.xml"
#$ligneCible = 13  # Ligne X (1 = première ligne)
$regexRecherche = "<version>.*</version>"  # Expression régulière à chercher
#$texteRemplacement = "<version>1.4.6</version>"
$texteRemplacement = "<version>$version</version>"

# Générer un nom de sauvegarde avec timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$nomFichier = [IO.Path]::GetFileName($fichier)
$backupPath = Join-Path $env:TEMP "$($nomFichier)_$timestamp.bak"

# Sauvegarder le fichier
Copy-Item -Path $fichier -Destination $backupPath -Force
Write-Host "💾 Fichier sauvegardé dans : $backupPath"

# Lire les lignes du fichier
$lignes = Get-Content -Path $fichier

# Vérifie si la ligne existe
if ($ligneCible -le $lignes.Count) {
    $ligneTexte = $lignes[$ligneCible - 1]

    if ($ligneTexte -match $regexRecherche) {
        # Remplacement avec regex
        $lignes[$ligneCible - 1] = [regex]::Replace($ligneTexte, $regexRecherche, $texteRemplacement)

        # Réécriture du fichier
        Set-Content -Path $fichier -Value $lignes
        Write-Host "✅ Remplacement effectué à la ligne $ligneCible."
    } else {
        Write-Host "❌ Aucun texte correspondant à l'expression '$regexRecherche' trouvé à la ligne $ligneCible."
    }
} else {
    Write-Host "❌ La ligne $ligneCible n'existe pas (le fichier contient $($lignes.Count) lignes)."
}