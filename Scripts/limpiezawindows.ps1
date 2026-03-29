# Comprobar si se está ejecutando como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "¡Debes ejecutar este script como ADMINISTRADOR!"
    Pause
    Exit
}

Write-Host "--- INICIANDO LIMPIEZA PROFUNDA DE WINDOWS ---" -ForegroundColor Cyan

# 1. Limpieza de Temporales del Usuario y del Sistema
Write-Host "[1/5] Eliminando archivos temporales..." -ForegroundColor Yellow
$TempFolders = @($env:TEMP, "C:\Windows\Temp", "C:\Windows\Prefetch")
foreach ($folder in $TempFolders) {
    Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Limpieza de la carpeta WinSxS (Actualizaciones antiguas)
Write-Host "[2/5] Limpiando almacén de componentes (WinSxS)..." -ForegroundColor Yellow
Dism /Online /Cleanup-Image /StartComponentCleanup /NoRestart

# 3. Vaciar Papelera de Reciclaje
Write-Host "[3/5] Vaciando la papelera de reciclaje..." -ForegroundColor Yellow
Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue

# 4. Limpieza de Caché DNS
Write-Host "[4/5] Limpiando caché de DNS..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null

# 5. Optimización de la unidad C: (Trim para SSD)
Write-Host "[5/5] Optimizando unidad C..." -ForegroundColor Yellow
Optimize-Volume -DriveLetter C -ReTrim -Verbose

Write-Host "--- LIMPIEZA COMPLETADA CON ÉXITO ---" -ForegroundColor Green
Pause
