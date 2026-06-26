# ============================================================
# quitar-licencias.ps1
# Eliminación masiva de licencias Microsoft 365 vía Microsoft Graph
#
# IMPORTANTE — LEE ANTES DE EJECUTAR:
#   1. Verifica qué licencias tiene un usuario antes de correr masivo:
#      Get-MgUserLicenseDetail -UserId "usuario@tudominio.com" | Format-List
#   2. Confirma los SKU de tu tenant:
#      Get-MgSubscribedSku | Select-Object SkuPartNumber, SkuId
#   3. Prueba con 1 usuario antes de correr el archivo completo
#   4. Esta operación NO se puede deshacer automáticamente
#
# REQUISITOS:
#   - Módulo Microsoft.Graph instalado
#   - Conectado a Graph:
#     Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
# ============================================================

# ── CONFIGURACIÓN ────────────────────────────────────────────
$archivoUsuarios = "C:\Usuarios\emails.txt"   # Un email por línea
# ─────────────────────────────────────────────────────────────

# ── PERFILES DE REMOCIÓN ─────────────────────────────────────
# Define qué licencias quitar por perfil.
# El script verifica que el usuario TENGA la licencia antes de quitarla
# — evita errores BadRequest en usuarios que ya no la tienen.
$Perfiles = @{
    "E3_Security"  = @("SPE_E3", "IDENTITY_THREAT_PROTECTION")
    "E3_noTeams"   = @("SPE_E3", "IDENTITY_THREAT_PROTECTION", "Microsoft_365_E3_(no_Teams)")
    "E1_Defender"  = @("STANDARDPACK", "ATP_ENTERPRISE")
}
# ─────────────────────────────────────────────────────────────

function Quitar-Licencias {
    param(
        [string]$PerfilNombre
    )

    if (-not $Perfiles.ContainsKey($PerfilNombre)) {
        Write-Host "ERROR: Perfil '$PerfilNombre' no encontrado." -ForegroundColor Red
        Write-Host "Perfiles disponibles: $($Perfiles.Keys -join ', ')" -ForegroundColor Yellow
        return
    }

    if (!(Test-Path $archivoUsuarios)) {
        Write-Host "ERROR: No se encontró $archivoUsuarios" -ForegroundColor Red
        return
    }

    $targets  = $Perfiles[$PerfilNombre]
    $emails   = Get-Content $archivoUsuarios | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $Exitosos = @()
    $SinLicencia = @()
    $Errores  = @()

    Write-Host "Perfil seleccionado : $PerfilNombre" -ForegroundColor Cyan
    Write-Host "SKUs a remover      : $($targets -join ', ')" -ForegroundColor Cyan
    Write-Host "Usuarios a procesar : $($emails.Count)" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray

    foreach ($email in $emails) {
        try {
            # Verificar qué licencias tiene el usuario actualmente
            $userLics = Get-MgUserLicenseDetail -UserId $email -ErrorAction Stop

            # Solo incluir en remoción las que el usuario SÍ tiene
            $toRemove = $userLics |
                Where-Object { $targets -contains $_.SkuPartNumber } |
                Select-Object -ExpandProperty SkuId

            if ($toRemove) {
                Set-MgUserLicense -UserId $email `
                    -RemoveLicenses @($toRemove) `
                    -AddLicenses @{} `
                    -ErrorAction Stop

                Write-Host "[ÉXITO] Licencias quitadas a: $email" -ForegroundColor Green
                $Exitosos += $email
            } else {
                Write-Host "[SIN LICENCIA] $email no tenía ninguna de esas licencias." -ForegroundColor Yellow
                $SinLicencia += $email
            }

        } catch {
            Write-Host "[ERROR] $email — $($_.Exception.Message)" -ForegroundColor Red
            $Errores += $email
        }
    }

    $fecha = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
    Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "RESUMEN — Perfil: $PerfilNombre" -ForegroundColor Cyan
    Write-Host "-> Licencias quitadas : $($Exitosos.Count)"    -ForegroundColor Green
    Write-Host "-> Sin esas licencias : $($SinLicencia.Count)" -ForegroundColor Yellow
    Write-Host "-> Errores            : $($Errores.Count)"     -ForegroundColor Red

    if ($Exitosos.Count -gt 0)    { $Exitosos    | Out-File "C:\Exportaciones\Quitadas_Exitosas_$fecha.txt"  -Encoding UTF8 }
    if ($SinLicencia.Count -gt 0) { $SinLicencia | Out-File "C:\Exportaciones\Sin_Licencia_$fecha.txt"      -Encoding UTF8 }
    if ($Errores.Count -gt 0)     { $Errores     | Out-File "C:\Exportaciones\Quitadas_Errores_$fecha.txt"  -Encoding UTF8 }
}

# ── EJECUCIÓN ────────────────────────────────────────────────
# Cambia el perfil según lo que necesites remover:
#   "E3_Security" → quita E3 + Identity Threat Protection
#   "E3_noTeams"  → quita E3 + Identity + versión sin Teams
#   "E1_Defender" → quita E1 + Defender Plan 1
#
Quitar-Licencias -PerfilNombre "E3_Security"
