# ============================================================
# asignar-licencias.ps1
# Asignación masiva de licencias Microsoft 365 vía Microsoft Graph
#
# IMPORTANTE — LEE ANTES DE EJECUTAR:
#   1. Verifica los SKU IDs con tu tenant antes de correr:
#      Get-MgSubscribedSku | Select-Object SkuPartNumber, SkuId
#   2. Confirma que tienes permisos de administrador de licencias
#   3. Prueba primero con 1-2 usuarios antes de correr masivo
#   4. Este script NO quita licencias existentes (RemoveLicenses = @())
#
# REQUISITOS:
#   - PowerShell 5.1+
#   - Módulo Microsoft.Graph instalado:
#     Install-Module Microsoft.Graph -Scope CurrentUser
#   - Conectado a Graph:
#     Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
# ============================================================

# ── CONFIGURACIÓN ────────────────────────────────────────────
$archivoUsuarios = "C:\Usuarios\emails.txt"   # Un email por línea
$ubicacionUso    = "MX"                        # Código de país ISO 3166-1
# ─────────────────────────────────────────────────────────────

# ── SKU IDs disponibles en tu tenant ─────────────────────────
# Consulta los tuyos con: Get-MgSubscribedSku | Select SkuPartNumber, SkuId
$SKUs = @{
    # Paquetes principales
    "E3"              = "05e9a617-0261-4cee-bb44-138d3ef5d965"  # SPE_E3
    "E5_Security"     = "26124093-3d78-432b-b5dc-48bf992543d5"  # IDENTITY_THREAT_PROTECTION
    "E1"              = "18181a46-0d4e-45cd-891e-60aabd171b4e"  # STANDARDPACK
    "Defender_Plan1"  = "4ef96642-f096-40de-a3e9-d83fb2f90211"  # ATP_ENTERPRISE
    # Agrega más según los SKUs disponibles en tu tenant
}
# ─────────────────────────────────────────────────────────────

# ── PERFILES DE LICENCIA ─────────────────────────────────────
# Define qué combinación de licencias aplica para cada perfil.
# Edita o agrega perfiles según las necesidades de tu organización.
$Perfiles = @{
    "E3_Security" = @($SKUs["E3"], $SKUs["E5_Security"])   # E3 + Identity Protection
    "E1_Defender" = @($SKUs["E1"], $SKUs["Defender_Plan1"]) # E1 + Defender Plan 1
}
# ─────────────────────────────────────────────────────────────

function Asignar-Licencias {
    param(
        [string]$PerfilNombre
    )

    if (-not $Perfiles.ContainsKey($PerfilNombre)) {
        Write-Host "ERROR: Perfil '$PerfilNombre' no encontrado." -ForegroundColor Red
        Write-Host "Perfiles disponibles: $($Perfiles.Keys -join ', ')" -ForegroundColor Yellow
        return
    }

    if (!(Test-Path $archivoUsuarios)) {
        Write-Host "ERROR: No se encontró el archivo en $archivoUsuarios" -ForegroundColor Red
        return
    }

    $emails   = Get-Content -Path $archivoUsuarios | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $Exitosos = @()
    $Errores  = @()

    $licensesToAssign = $Perfiles[$PerfilNombre] | ForEach-Object {
        [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphAssignedLicense]@{
            SkuId = [Guid]::Parse($_)
        }
    }

    Write-Host "Perfil seleccionado : $PerfilNombre" -ForegroundColor Cyan
    Write-Host "Usuarios a procesar : $($emails.Count)" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray

    foreach ($email in $emails) {
        try {
            $user = Get-MgUser -UserId $email -ErrorAction Stop

            if (-not $user.UsageLocation) {
                Update-MgUser -UserId $email -UsageLocation $ubicacionUso
                Write-Host "[UBICACIÓN] $email → $ubicacionUso" -ForegroundColor DarkCyan
            }

            Set-MgUserLicense -UserId $email `
                -AddLicenses $licensesToAssign `
                -RemoveLicenses @() `
                -ErrorAction Stop

            Write-Host "[ÉXITO] $email" -ForegroundColor Green
            $Exitosos += $email

        } catch {
            Write-Host "[ERROR] $email — $($_.Exception.Message)" -ForegroundColor Red
            $Errores += $email
        }
    }

    Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "RESUMEN — Perfil: $PerfilNombre" -ForegroundColor Cyan
    Write-Host "-> Exitosos : $($Exitosos.Count)" -ForegroundColor Green
    Write-Host "-> Errores  : $($Errores.Count)"  -ForegroundColor Red

    $fecha = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
    if ($Exitosos.Count -gt 0) { $Exitosos | Out-File "C:\Exportaciones\Licencias_Exitosas_$fecha.txt" -Encoding UTF8 }
    if ($Errores.Count -gt 0)  { $Errores  | Out-File "C:\Exportaciones\Licencias_Errores_$fecha.txt"  -Encoding UTF8 }
}

# ── EJECUCIÓN ────────────────────────────────────────────────
# Cambia el perfil según lo que necesites asignar:
#   "E3_Security" → E3 + Identity Threat Protection
#   "E1_Defender" → E1 + Defender Plan 1
#
Asignar-Licencias -PerfilNombre "E3_Security"
