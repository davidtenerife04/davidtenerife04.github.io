<#
.SYNOPSIS
    GESTOR DE ALMACENAMIENTO PRO V5 - POWERSHELL
    Herramientas de rescate, limpieza y expansion de volumenes.
    EJECUTAR COMO ADMINISTRADOR.
#>

function Mostrar-Menu-Discos {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Yellow
    Write-Host "      GESTOR DE ALMACENAMIENTO PRO            " -ForegroundColor Yellow
    Write-Host "==============================================" -ForegroundColor Yellow
    Write-Host "--- INFO Y SALUD ---" -ForegroundColor Cyan
    Write-Host "1. Listar Unidades Logicas (C:, D:, etc.)"
    Write-Host "2. Listar Discos Fisicos (SSD/HDD)"
    Write-Host "3. Ver Salud y Tipo de Bus (USB/SATA/NVMe)"
    
    Write-Host "`n--- MANTENIMIENTO ---" -ForegroundColor Cyan
    Write-Host "4. Optimizar / TRIM (SSD/HDD)"
    Write-Host "5. Comprobar Errores (Chkdsk / Repair)"
    
    Write-Host "`n--- OPERACIONES DE DISCO (PELIGRO) ---" -ForegroundColor Red
    Write-Host "6. Crear Particion Primaria (Auto)"
    Write-Host "7. Eliminar Volumen por Letra"
    Write-Host "8. Formatear Unidad (NTFS Rapido)"
    Write-Host "9. Cambiar Letra de Unidad"
    Write-Host "10. LIMPIAR DISCO COMPLETO (Comando CLEAN)"
    Write-Host "11. Extender Volumen (Usar espacio libre)"
    
    Write-Host "`n0. Salir" -ForegroundColor White
    Write-Host "==============================================" -ForegroundColor Yellow
}

do {
    Mostrar-Menu-Discos
    $opcion = Read-Host "Seleccione una opcion"

    switch ($opcion) {
        "1" {
            Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{n="Libre(GB)";e={"{0:N2}" -f ($_.Free/1GB)}} | Out-String | Write-Host
        }
        "2" {
            Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, @{n="Tamano(GB)";e={"{0:N2}" -f ($_.Size/1GB)}} | Out-String | Write-Host
        }
        "3" {
            Get-Disk | Select-Object Number, FriendlyName, HealthStatus, BusType | Out-String | Write-Host
        }
        "4" {
            $letra = Read-Host "Letra de unidad a optimizar (Ej: C)"
            Optimize-Volume -DriveLetter $letra -Verbose
        }
        "5" {
            $letra = Read-Host "Letra de unidad para reparar"
            Repair-Volume -DriveLetter $letra -Scan
        }
        "6" {
            Get-Disk | Where-Object PartitionStyle -eq "RAW" | Out-String | Write-Host
            $num = Read-Host "Numero de disco para inicializar y particionar"
            try {
                Initialize-Disk -Number $num -PartitionStyle GPT -ErrorAction SilentlyContinue
                New-Partition -DiskNumber $num -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -Full:$false
                Write-Host "Disco configurado exitosamente." -ForegroundColor Green
            } catch {
                Write-Host "Error al crear la particion." -ForegroundColor Red
            }
        }
        "7" {
            $letra = Read-Host "Letra de unidad a eliminar"
            Remove-Partition -DriveLetter $letra -Confirm:$true
        }
        "8" {
            $letra = Read-Host "Letra de unidad a formatear"
            Format-Volume -DriveLetter $letra -FileSystem NTFS -Confirm:$true
        }
        "9" {
            $actual = Read-Host "Letra actual"
            $nueva = Read-Host "Nueva letra"
            Get-Partition -DriveLetter $actual | Set-Partition -NewDriveLetter $nueva
        }
        "10" {
            Write-Host "--- ATENCION: ESTO BORRARA TODO EL DISCO FISICO ---" -ForegroundColor White -BackgroundColor Red
            Get-Disk | Select-Object Number, FriendlyName, @{n="Size(GB)";e={"{0:N2}" -f ($_.Size/1GB)}} | Out-String | Write-Host
            $num = Read-Host "Numero de DISCO a dejar de fabrica (CLEAN)"
            $conf = Read-Host "Escriba 'BORRAR' para confirmar la operacion"
            if ($conf -eq "BORRAR") {
                $script = "select disk $num `n clean"
                $script | diskpart
                Write-Host "Disco $num limpiado exitosamente." -ForegroundColor Green
            } else {
                Write-Host "Operacion cancelada." -ForegroundColor Yellow
            }
        }
        "11" {
            $letra = Read-Host "Letra de la unidad a extender"
            try {
                $size = Get-PartitionSupportedSize -DriveLetter $letra
                Resize-Partition -DriveLetter $letra -Size $size.SizeMax
                Write-Host "Volumen extendido al maximo." -ForegroundColor Green
            } catch {
                Write-Host "No se pudo extender. Verifique espacio contiguo." -ForegroundColor Red
            }
        }
        "0" {
            Write-Host "Saliendo..." -ForegroundColor Yellow
            break
        }
        Default {
            Write-Host "Opcion no valida." -ForegroundColor Red
        }
    }

    if ($opcion -ne "0") {
        Read-Host "`nPresione Enter para continuar..."
    }

} while ($opcion -ne "0")