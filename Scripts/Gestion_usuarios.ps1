<#
.SYNOPSIS
    HERRAMIENTA INTEGRAL DE ADMINISTRACION DE WINDOWS
    Funciones: Usuarios, Grupos, Permisos, Red y Sesiones.
    Ejecutar siempre como ADMINISTRADOR.
#>

function Mostrar-Menu {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "   GESTOR INTEGRAL DE SISTEMA - POWERSHELL    " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "--- USUARIOS Y GRUPOS ---" -ForegroundColor DarkCyan
    Write-Host "1. Listar Usuarios y Grupos"
    Write-Host "2. Crear / Eliminar Usuario"
    Write-Host "3. Crear / Eliminar Grupo"
    Write-Host "4. Gestionar Miembros de Grupos"
    Write-Host "5. Resetear Contrasena / Desbloquear Cuenta"
    Write-Host "6. Habilitar / Deshabilitar Usuario"
    
    Write-Host "`n--- SEGURIDAD Y PERMISOS (ACL) ---" -ForegroundColor DarkCyan
    Write-Host "7. Ver / Asignar Dueno de Carpeta (Owner)"
    Write-Host "8. Dar Control Total a una carpeta"

    Write-Host "`n--- RED Y MONITORIZACION ---" -ForegroundColor DarkCyan
    Write-Host "9. Ver Configuracion de Red (IP/DNS)"
    Write-Host "10. Listar Sesiones Activas (RDP/Local)"
    Write-Host "11. Reiniciar Servicio de Impresion (Spooler)"
    
    Write-Host "`n0. Salir" -ForegroundColor Red
    Write-Host "==============================================" -ForegroundColor Cyan
}

do {
    Mostrar-Menu
    $opcion = Read-Host "Seleccione una opcion"

    switch ($opcion) {
        "1" {
            Write-Host "`n[ USUARIOS ]" -ForegroundColor Yellow
            Get-LocalUser | Select-Object Name, Enabled, LastLogon
            Write-Host "`n[ GRUPOS ]" -ForegroundColor Yellow
            Get-LocalGroup | Select-Object Name
        }
        "2" {
            $accion = Read-Host "Desea (A)nadir o (E)liminar usuario?"
            $user = Read-Host "Nombre del usuario"
            if ($accion -eq "A") {
                $pass = Read-Host "Contrasena" -AsSecureString
                New-LocalUser -Name $user -Password $pass -Description "Creado via Script"
                Write-Host "Usuario creado." -ForegroundColor Green
            } else {
                Remove-LocalUser -Name $user -Confirm:$false
                Write-Host "Proceso terminado." -ForegroundColor Yellow
            }
        }
        "3" {
            $accion = Read-Host "Desea (A)nadir o (E)liminar grupo?"
            $grupo = Read-Host "Nombre del grupo"
            if ($accion -eq "A") {
                New-LocalGroup -Name $grupo
                Write-Host "Grupo creado." -ForegroundColor Green
            } else {
                Remove-LocalGroup -Name $grupo -Confirm:$false
                Write-Host "Grupo eliminado." -ForegroundColor Yellow
            }
        }
        "4" {
            $user = Read-Host "Nombre del usuario"
            $grupo = Read-Host "Nombre del grupo"
            $accion = Read-Host "(A)gregar o (Q)uitar del grupo?"
            if ($accion -eq "A") {
                Add-LocalGroupMember -Group $grupo -Member $user
                Write-Host "Agregado." -ForegroundColor Green
            } else {
                Remove-LocalGroupMember -Group $grupo -Member $user
                Write-Host "Quitado." -ForegroundColor Yellow
            }
        }
        "5" {
            $user = Read-Host "Nombre del usuario"
            $newPass = Read-Host "Nueva Contrasena (Dejar vacio solo para desbloquear)" -AsSecureString
            if ($newPass) { Set-LocalUser -Name $user -Password $newPass }
            # Desbloqueo (en cuentas locales se hace habilitandola de nuevo)
            Enable-LocalUser -Name $user
            Write-Host "Operacion realizada." -ForegroundColor Green
        }
        "6" {
            $user = Read-Host "Nombre del usuario"
            $estado = Read-Host "(H)abilitar o (D)eshabilitar?"
            if ($estado -eq "H") { Enable-LocalUser -Name $user } else { Disable-LocalUser -Name $user }
            Write-Host "Estado actualizado." -ForegroundColor Green
        }
        "7" {
            $ruta = Read-Host "Ruta de la carpeta"
            $owner = Read-Host "Nuevo Dueno (Ej: Administradores)"
            takeown /F $ruta /R /D S
            Write-Host "Propiedad asignada." -ForegroundColor Green
        }
        "8" {
            $ruta = Read-Host "Ruta de la carpeta"
            $user = Read-Host "Usuario/Grupo para Control Total"
            icacls $ruta /grant "${user}:(OI)(CI)F" /T
            Write-Host "Permisos aplicados." -ForegroundColor Green
        }
        "9" {
            Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress | Out-String | Write-Host
            Get-DnsClientServerAddress -AddressFamily IPv4 | Out-String | Write-Host
        }
        "10" {
            query session | Write-Host
        }
        "11" {
            Restart-Service -Name Spooler -Force
            Write-Host "Servicio de impresion reiniciado." -ForegroundColor Green
        }
        "0" {
            Write-Host "Saliendo..." -ForegroundColor Cyan
        }
        Default {
            Write-Host "Opcion incorrecta." -ForegroundColor Red
        }
    }

    if ($opcion -ne "0") {
        Read-Host "`nPresione Enter para volver al menu..."
    }

} while ($opcion -ne "0")