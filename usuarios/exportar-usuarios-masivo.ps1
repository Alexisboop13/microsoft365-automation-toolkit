# ============================================================
# exportar-usuarios-masivo.ps1
# Exporta TODOS los miembros de una lista de distribución sin límite
#
# USO:
#   1. Configura las variables de la sección CONFIGURACIÓN
#   2. Ejecuta desde Exchange Management Shell
#   3. El archivo CSV se genera en la ruta de salida configurada
#
# NOTA TÉCNICA:
#   Exchange limita por defecto a 1,000 resultados.
#   Este script usa -ResultSize Unlimited para superar ese límite
#   y exportar listas de cualquier tamaño (probado con 3,000+ usuarios).
# ============================================================

# ── CONFIGURACIÓN ────────────────────────────────────────────
$identidadLista = "tu-lista@tudominio.com"
$rutaSalida     = "C:\Exportaciones\miembros-completo.csv"
# ─────────────────────────────────────────────────────────────

Write-Host "Exportando miembros de: $identidadLista" -ForegroundColor Cyan
Write-Host "Sin límite de resultados (-ResultSize Unlimited)..." -ForegroundColor Gray

Get-DistributionGroupMember -ResultSize Unlimited -Identity $identidadLista |
    Select-Object Identity, Alias, FirstName, LastName, Name, `
                  Office, Title, WindowsLiveID, WhenMailboxCreated, `
                  Id, ExternalEmailAddress |
    Export-CSV -NoTypeInformation -Path $rutaSalida -Encoding UTF8

Write-Host "Exportación completada: $rutaSalida" -ForegroundColor Green
Write-Host "Total exportado: $((Import-Csv $rutaSalida).Count) usuarios" -ForegroundColor Cyan
