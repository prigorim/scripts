$ErrorActionPreference = 'silentlyContinue'
#путь скрипта
$script_path = $MyInvocation.MyCommand.Path | split-path -parent

$ports = '3389', '22'

#Тестирование портов
function testPort {
    #var
    param (
        $port,
        $timeOut
    )
    #для 10.223.x где х 0..255
    for ($ip3 = 9; $ip3 -le 9 ; $ip3++) {
        #для 10.223.x.y где y 0..255
        for ($ip4 = 0; $ip4 -le 255 ; $ip4++) {
            #отображаем прогресс
            Write-Progress -Activity "Search in Progress. Port: $port" -Status "10.223.$ip3.$ip4" -PercentComplete ($ip3 / 2.55)
            #ожидание ответа
            $requestCallback = $state = $null
            #клиент
            $client = New-Object System.Net.Sockets.TcpClient
            #проверка соединения
            $client.BeginConnect("10.223.$ip3.$ip4", $port, $requestCallback, $state) | Out-Null
            #спим милисекунду
            Start-Sleep -milli $timeOut
            #если соединение успешно значит $open = $true
            if ($client.Connected) { $open = $true } else { $open = $false }
            #закрываем соединение
            $client.Close()
            #если порт открыт
            if ($open -eq $true) {
                #записываем имя хоста
                $hostname = (Resolve-DnsName -Name 10.223.$ip3.$ip4).namehost               
                if ($null -eq $hostname) {
                    $hostname = 'unnamed'
                }
                #формируем массив адресов
                $data = @()
                #создаем новую строку
                $row = New-Object PSObject
                $row | Add-Member -MemberType NoteProperty -Name 'ip' -Value "10.223.$ip3.$ip4"
                $row | Add-Member -MemberType NoteProperty -Name 'hostname' -Value $hostname
                $row | Add-Member -MemberType NoteProperty -Name 'port' -Value $port
                $data += $row
                $data | Format-List
                #экспортируем массив в csv
                $data | Export-Csv -Path ($script_path + '\output\' + $port + '.csv') -Append -Encoding Default -NoTypeInformation -Delimiter ';'
            }
        }
    }
}

#вызов функции с портом и таймером сна
foreach ($port in $ports) {
    testPort -port $port -timeout '100'
}
$ErrorActionPreference = 'Continue'