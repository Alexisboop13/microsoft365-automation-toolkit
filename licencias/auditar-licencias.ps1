# ============================================================
# auditar-licencias.ps1
# Genera un reporte CSV con las licencias actuales de una lista de usuarios
#
# USO:
#   1. Coloca los correos a auditar en el archivo de input (uno por línea)
#   2. Configura las rutas en la sección CONFIGURACIÓN
#   3. Ejecuta — no modifica nada, solo lee y reporta
#
# REQUISITOS:
#   - Módulo Microsoft.Graph instalado
#   - Conectado a Graph:
#     Connect-MgGraph -Scopes "User.Read.All"
#   - Permiso de solo lectura es suficiente (operación no destructiva)
# ============================================================

# ── CONFIGURACIÓN ────────────────────────────────────────────
$archivoInput  = "C:\Usuarios\emails.txt"              # Un email por línea
$archivoReporte = "C:\Exportaciones\reporte-licencias.csv"  # CSV de salida
# ─────────────────────────────────────────────────────────────

# ── CLASIFICACIÓN DE LICENCIAS ───────────────────────────────
# Edita este bloque para agregar nuevos SKUs según tu tenant.
# El primer match gana — ordena de más específico a más general.
function Clasificar-Licencia {
    param([string[]]$Skus)

    if ($null -eq $Skus -or $Skus.Count -eq 0) {
        return "Sin Licencia Asignada"
    }
    if ($Skus -contains "Microsoft_365_E3_(no_Teams)") { return "Microsoft 365 E3 (Sin Teams)" }
    if ($Skus -contains "SPE_E3")                      { return "Microsoft 365 E3 (Completo)" }
    if ($Skus -contains "STANDARDPACK")                { return "Office 365 E1" }
    return "Otras: $($Skus -join ', ')"   # Muestra los SKUs reales si no hay match
}
# ─────────────────────────────────────────────────────────────

if (!(Test-Path $archivoInput)) {
    Write-Host "ERROR: No se encontró $archivoInput" -ForegroundColor Red
    return
}

$Correos = Get-Content -Path $archivoInput |
           ForEach-Object { $_.Trim() } |
           Where-Object { ![string]::IsNullOrWhiteSpace($_) }

$Total  = $Correos.Count
$Actual = 0

Write-Host "Auditando licencias de $Total usuarios..." -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray

$Reporte = foreach ($email in $Correos) {
    $Actual++
    Write-Host "[ $Actual / $Total ] $email" -ForegroundColor Gray
    Start-Sleep -Milliseconds 150   # Evita throttling de Graph API

    try {
        $Skus = Get-MgUserLicenseDetail -UserId $email -ErrorAction Stop |
                Select-Object -ExpandProperty SkuPartNumber

        [PSCustomObject]@{
            Correo   = $email
            Licencia = Clasificar-Licencia -Skus $Skus
            SKUs_Raw = $Skus -join " | "   # Detalle completo para auditoría
        }
    }
    catch {
        $msg = $_.Exception.Message
        $clase = if ($msg -like "*User not found*" -or $msg -like "*Resource not found*") {
            "No encontrado en Azure AD"
        } else {
            "Error de Consulta"
        }
        [PSCustomObject]@{
            Correo   = $email
            Licencia = $clase
            SKUs_Raw = $msg
        }
    }
}

$Reporte | Export-Csv -Path $archivoReporte `
    -NoTypeInformation `
    -Encoding UTF8 `
    -Delimiter ";"

Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host "-> Total procesados : $($Reporte.Count)" -ForegroundColor White
Write-Host "-> Sin licencia     : $(($Reporte | Where-Object Licencia -eq 'Sin Licencia Asignada').Count)" -ForegroundColor Yellow
Write-Host "-> No encontrados   : $(($Reporte | Where-Object Licencia -eq 'No encontrado en Azure AD').Count)" -ForegroundColor Red
Write-Host "-> Reporte guardado : $archivoReporte" -ForegroundColor Green
