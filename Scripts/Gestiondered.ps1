<#
.SYNOPSIS
    GESTOR DE RED PROFESIONAL UNIFICADO - POWERSHELL
    Incluye: Configuracion, Diagnostico, Auditoria y Descubrimiento.
    Ejecutar como ADMINISTRADOR.
#>

function Mostrar-Menu-Red {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "      GESTOR DE RED INTEGRAL - WINDOWS        " -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "--- CONFIGURACION Y ESTADO ---" -ForegroundColor Yellow
    Write-Host "1.  Listar Detalles (IP, Mascara, GW, DNS)"
    Write-Host "2.  Ver IP Publica (Internet)"
    Write-Host "3.  Cambiar a IP Estatica"
    Write-Host "4.  Cambiar Servidores DNS"
    Write-Host "5.  Cambiar a DHCP (Automatico)"
    
    Write-Host "`n--- DIAGNOSTICO DE CONECTIVIDAD ---" -ForegroundColor Yellow
    Write-Host "6.  Ping a una IP"
    Write-Host "7.  Ping a Gateway (Puerta de enlace)"
    Write-Host "8.  Ping a Dominio (DNS Test)"
    Write-Host "9.  Trazar Ruta (Tracert - Ver saltos)"
    Write-Host "10. Test de Estabilidad (Jitter/Latencia)"
    
    Write-Host "`n--- AUDITORIA Y DESCUBRIMIENTO ---" -ForegroundColor Yellow
    Write-Host "11. Escaneo Rapido de Red Local (Ping Sweep)"
    Write-Host "12. Identificar Nombre de Host (IP a Nombre)"
    Write-Host "13. Listar Puertos Escuchando (Netstat)"
    Write-Host "14. Ver Tabla de Rutas y ARP (MACs)"
    Write-Host "15. Estadisticas de Trafico (Bytes Enviados/Recibidos)"
    
    Write-Host "`n--- MANTENIMIENTO ---" -ForegroundColor Yellow
    Write-Host "16. Liberar/Renovar IP (Release-Renew)"
    Write-Host "17. Limpiar Cache DNS (FlushDNS)"
    
    Write-Host "`n0. Salir" -ForegroundColor Red
    Write-Host "==============================================" -ForegroundColor Green
}

do {
    Mostrar-Menu-Red
    $opcion = Read-Host "Seleccione una opcion"

    switch ($opcion) {
        "1" { Get-NetIPConfiguration | Out-String | Write-Host }
        "2" { 
            Write-Host "Consultando IP Publica..." -ForegroundColor Cyan
            try { (Invoke-RestMethod -Uri "https://api.ipify.org") | Write-Host -ForegroundColor Green } catch { Write-Host "Error de red." -ForegroundColor Red }
        }
        "3" {
            $interfaz = Read-Host "Nombre de la Interfaz"; $ip = Read-Host "Nueva IP"; $mask = Read-Host "Prefijo (ej: 24)"; $gw = Read-Host "GW"
            New-NetIPAddress -InterfaceAlias $interfaz -IPAddress $ip -PrefixLength $mask -DefaultGateway $gw
        }
        "4" {
            $interfaz = Read-Host "Interfaz"; $dns1 = Read-Host "DNS1"; $dns2 = Read-Host "DNS2"
            Set-DnsClientServerAddress -InterfaceAlias $interfaz -ServerAddresses ($dns1, $dns2)
        }
        "5" {
            $interfaz = Read-Host "Interfaz"
            Set-NetIPInterface -InterfaceAlias $interfaz -DHCP Enabled
            Set-DnsClientServerAddress -InterfaceAlias $interfaz -ResetServerAddresses
            Write-Host "DHCP Activado." -ForegroundColor Green
        }
        "6" { $target = Read-Host "IP"; Test-Connection -ComputerName $target -Count 4 }
        "7" {
            $gw = (Get-NetRoute -DestinationPrefix 0.0.0.0/0).NextHop | Select-Object -First 1
            if ($gw) { Write-Host "Probando Gateway: $gw"; Test-Connection -ComputerName $gw -Count 4 }
        }
        "8" { $dom = Read-Host "Dominio"; Test-Connection -ComputerName $dom -Count 4 }
        "9" {
            $dest = Read-Host "Destino para Tracert"
            Write-Host "Iniciando traza..." -ForegroundColor Yellow
            tracert $dest
        }
        "10" {
            $dest = Read-Host "Destino para prueba de estabilidad"
            Test-Connection -ComputerName $dest -Count 10 | Select-Object Address, ResponseTime
        }
        "11" {
            $red = Read-Host "Ingrese los primeros 3 octetos (Ej: 192.168.1)"
            Write-Host "Escaneando red $red.0/24..." -ForegroundColor Yellow
            1..254 | ForEach-Object {
                $ip = "$red.$_"
                if (Test-Connection -ComputerName $ip -Count 1 -Quiet) { Write-Host "[ ON ] $ip responde." -ForegroundColor Green }
            }
        }
        "12" {
            $ip = Read-Host "Ingrese la IP para identificar"
            try { [System.Net.Dns]::GetHostEntry($ip) | Select-Object HostName, AddressList } catch { Write-Host "No se encontro nombre." -ForegroundColor Red }
        }
        "13" {
            Write-Host "Puertos en escucha (LISTENING):" -ForegroundColor Cyan
            netstat -an | Select-String "LISTENING" | Write-Host
        }
        "14" {
            Write-Host "--- Tabla de Rutas ---" -ForegroundColor Cyan
            Get-NetRoute -AddressFamily IPv4 | Select-Object DestinationPrefix, NextHop, InterfaceAlias
            Write-Host "`n--- Tabla ARP (IP-MAC) ---" -ForegroundColor Cyan
            arp -a | Write-Host
        }
        "15" {
            Get-NetAdapterStatistics | Select-Object Name, ReceivedBytes, SentBytes | Out-String | Write-Host
        }
        "16" { ipconfig /release; ipconfig /renew; Write-Host "IP Refrescada." -ForegroundColor Green }
        "17" { ipconfig /flushdns; Write-Host "Cache DNS limpia." -ForegroundColor Green }
        "0" { Write-Host "Saliendo..." -ForegroundColor Green }
        Default { Write-Host "Opcion no valida." -ForegroundColor Red }
    }

    if ($opcion -ne "0") { Read-Host "`nPresione Enter para continuar..." }

} while ($opcion -ne "0")