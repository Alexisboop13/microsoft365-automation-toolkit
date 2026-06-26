# ============================================================
# importar-contactos.ps1
# Importación masiva de contactos externos a Exchange desde CSV
#
# USO:
#   1. Prepara el CSV con estas columnas exactas:
#      Name, FirstName, LastName, ExternalEmailAddress
#   2. Configura la ruta del CSV en la sección CONFIGURACIÓN
#   3. Ejecuta desde Exchange Management Shell
#
# NOTA TÉCNICA:
#   El script verifica duplicados antes de crear cada contacto
#   comparando contra ExternalEmailAddress en Exchange.
#   Los contactos ya existentes se omiten sin error.
#
# FORMATO DEL CSV:
#   Name,FirstName,LastName,ExternalEmailAddress
#   Juan Lopez,Juan,Lopez,juan.lopez@externo.com
#   Maria García,Maria,Garcia,maria.garcia@externo.com
# ============================================================

# ── CONFIGURACIÓN ────────────────────────────────────────────
$archivoCSV = "C:\Contactos\contactos.csv"
# ─────────────────────────────────────────────────────────────

if (!(Test-Path $archivoCSV)) {
    Write-Host "ERROR: No se encontró $archivoCSV" -ForegroundColor Red
    return
}

Write-Host "Cargando contactos existentes en Exchange..." -ForegroundColor Cyan
$contactosExistentes = Get-MailContact | Select-Object -ExpandProperty ExternalEmailAddress

$contactosNuevos = Import-Csv $archivoCSV
$Creados  = @()
$Omitidos = @()
$Errores  = @()

Write-Host "Contactos en CSV       : $($contactosNuevos.Count)" -ForegroundColor Gray
Write-Host "Contactos en Exchange  : $($contactosExistentes.Count)" -ForegroundColor Gray
Write-Host "Iniciando importación..." -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray

foreach ($contacto in $contactosNuevos) {
    if ($contactosExistentes -contains $contacto.ExternalEmailAddress) {
        Write-Host "[OMITIDO] Ya existe: $($contacto.ExternalEmailAddress)" -ForegroundColor DarkYellow
        $Omitidos += $contacto.ExternalEmailAddress
        continue
    }

    try {
        New-MailContact `
            -Name                 $contacto.Name `
            -DisplayName          $contacto.Name `
            -ExternalEmailAddress $contacto.ExternalEmailAddress `
            -FirstName            $contacto.FirstName `
            -LastName             $contacto.LastName `
            -ErrorAction Stop

        Write-Host "[ÉXITO] $($contacto.ExternalEmailAddress)" -ForegroundColor Green
        $Creados += $contacto.ExternalEmailAddress

    } catch {
        Write-Host "[ERROR] $($contacto.ExternalEmailAddress) — $($_.Exception.Message)" -ForegroundColor Red
        $Errores += $contacto.ExternalEmailAddress
    }
}

$fecha = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
if ($Creados.Count -gt 0)  { $Creados  | Out-File "C:\Exportaciones\Contactos_Creados_$fecha.txt"  -Encoding UTF8 }
if ($Errores.Count -gt 0)  { $Errores  | Out-File "C:\Exportaciones\Contactos_Errores_$fecha.txt"  -Encoding UTF8 }

Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host "-> Creados  : $($Creados.Count)"  -ForegroundColor Green
Write-Host "-> Omitidos : $($Omitidos.Count)" -ForegroundColor Yellow
Write-Host "-> Errores  : $($Errores.Count)"  -ForegroundColor Red
