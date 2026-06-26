# ============================================================
# cargar-lista-distribucion.ps1
# Carga masiva de correos a una lista de distribución en Exchange
# 
# USO:
#   1. Coloca los correos (uno por línea) en el archivo de input
#   2. Configura las variables de la sección CONFIGURACIÓN
#   3. Ejecuta el script desde Exchange Management Shell
# ============================================================

# ── CONFIGURACIÓN ────────────────────────────────────────────
$rutaCarga   = "C:\Carga"                          # Carpeta de trabajo
$archivoInput = "$rutaCarga\usuarios.txt"          # Archivo con correos a cargar
$identidadLista = "tu-lista@tudominio.com"         # Lista de distribución destino
# ─────────────────────────────────────────────────────────────

$fecha = (Get-Date).ToString("yyyy-MM-dd_HH-mm")

if (!(Test-Path $archivoInput)) {
    Write-Host "ERROR: No se encontró el archivo en $archivoInput" -ForegroundColor Red
    return
}

$Errores         = @()
$Exitosos        = @()
$YaExistian      = @()
$CorreosErroneos = @()

Write-Host "Cargando y limpiando lista..." -ForegroundColor Cyan

# Leer, limpiar y deduplicar en una sola línea
$UsuariosCrudos = Get-Content -Path $archivoInput
$UsuariosUnicos = $UsuariosCrudos | ForEach-Object { $_.Trim() } | Select-Object -Unique

# Validación de formato de correo con Regex
$PatronCorreo = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

Write-Host "Registros originales : $($UsuariosCrudos.Count)" -ForegroundColor Gray
Write-Host "Tras eliminar duplicados: $($UsuariosUnicos.Count)" -ForegroundColor Gray
Write-Host "Iniciando procesamiento en Exchange..." -ForegroundColor Cyan

foreach ($usuario in $UsuariosUnicos) {
    if ([string]::IsNullOrWhiteSpace($usuario)) { continue }

    if ($usuario -notmatch $PatronCorreo) {
        Write-Host "[IGNORADO] Formato inválido: '$usuario'" -ForegroundColor DarkYellow
        $CorreosErroneos += $usuario
        continue
    }

    $fallo = $null
    Add-DistributionGroupMember -Identity $identidadLista -Member $usuario `
        -ErrorAction SilentlyContinue -ErrorVariable fallo

    if ($fallo) {
        $msg = $fallo.Exception.Message
        if ($msg -like "*already a member*" -or $msg -like "*ya es miembro*") {
            Write-Host "[YA EXISTÍA] $usuario" -ForegroundColor Yellow
            $Exitosos   += $usuario
            $YaExistian += $usuario
        } else {
            Write-Host "[ERROR] $usuario — $msg" -ForegroundColor Red
            $Errores += $usuario
        }
    } else {
        Write-Host "[ÉXITO] $usuario agregado." -ForegroundColor Green
        $Exitosos += $usuario
    }
}

Write-Host "Generando reportes..." -ForegroundColor Cyan

if ($Errores.Count -gt 0)         { $Errores         | Out-File "$rutaCarga\Errores_$fecha.txt"          -Encoding UTF8 }
if ($Exitosos.Count -gt 0)        { $Exitosos         | Out-File "$rutaCarga\Agregados_$fecha.txt"        -Encoding UTF8 }
if ($CorreosErroneos.Count -gt 0) { $CorreosErroneos  | Out-File "$rutaCarga\Correos_Erroneos_$fecha.txt" -Encoding UTF8 }

$TotalErroresExcel = $Errores.Count + $CorreosErroneos.Count

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "-> Total original      : $($UsuariosCrudos.Count)" -ForegroundColor White
Write-Host "-> Total cargado       : $($Exitosos.Count)"       -ForegroundColor Green
Write-Host "-> Total errores       : $TotalErroresExcel"       -ForegroundColor Red
Write-Host "-> Duplicados purgados : $($UsuariosCrudos.Count - $UsuariosUnicos.Count)" -ForegroundColor DarkGray
