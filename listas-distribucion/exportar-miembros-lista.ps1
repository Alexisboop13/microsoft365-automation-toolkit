# ============================================================
# exportar-miembros-lista-distribucion.ps1
# Exporta todos los miembros de una lista de distribución a CSV
#
# USO:
#   1. Configura las variables de la sección CONFIGURACIÓN
#   2. Ejecuta desde Exchange Management Shell
#   3. El archivo CSV se genera en la ruta de salida configurada
# ============================================================

# ── CONFIGURACIÓN ────────────────────────────────────────────
$identidadLista = "nombre-de-tu-lista"        # Nombre o email de la lista
$rutaSalida     = "C:\Exportaciones\miembros-lista.csv"  # Ruta del CSV generado
# ─────────────────────────────────────────────────────────────

Get-DistributionGroupMember -ResultSize Unlimited -Identity $identidadLista |
    Select-Object Identity, Alias, FirstName, LastName, Name, `
                  Office, Title, WindowsLiveID, WhenMailboxCreated, `
                  Id, ExternalEmailAddress |
    Export-CSV -NoTypeInformation -Path $rutaSalida -Encoding UTF8

Write-Host "Exportación completada: $rutaSalida" -ForegroundColor Green
