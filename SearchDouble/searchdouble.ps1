#region var
#Путь к скрипту

$scriptPath = $MyInvocation.MyCommand.Path | split-path -parent
#Путь к папке через запятую "\\angarsk-fs09\Folders\RNU", 
$DirectoryPaths = "D:\Programs", "D:\output", "C:\Program Files"

function ProgressBar {
    param (
        $count,
        $itemsCount,
        $path
    )
    Write-Progress -Activity "Search in Progress. Path: $path" -Status "$count / $itemsCount" -PercentComplete ($count / $itemsCount * 100)
}

function getChildItem {
    param (
        $path
    )
    Get-Childitem –path $path -Recurse |
    Group-Object -property Length | 
    Where-Object { $_.count -gt 1 } |
    Select-Object –Expand Group |
    Get-FileHash | 
    Group-Object -property hash | 
    Where-Object { $_.count -gt 1 } | 
    ForEach-Object { $_.group | 
        Select-Object Path, Hash
        $hashPath = $_.group.path
        $countHash++
        Write-Progress -Activity "Calculate hash. $hashPath" -Status "in Progress" -PercentComplete (100)
    }
}


function searchdouble () {
    param (
        $path,
        $name
    )
    $items = getChildItem -path $path
    $count = 0
    $itemsCount = $items.count
    foreach ($item in $items) {
        $item |
        ForEach-Object {
            $count++
            ProgressBar -count $count -itemsCount $itemsCount -path $path
            $size = (Get-ChildItem –path $_.path).Length
            $data = @()
            #Формирование строки объекта
            $row = New-Object PSObject
            $row | Add-Member -MemberType NoteProperty -Name 'path' -Value $_.Path
            $row | Add-Member -MemberType NoteProperty -Name 'hash' -Value $_.Hash
            $row | Add-Member -MemberType NoteProperty -Name 'size (mb)' -Value ([math]::Round($size / 8 / 1024 / 1024, 2))
            #Добавление строки в объект
            $data += $row
            #Экспорт в CSV
            $data | Export-Csv -Path ($scriptPath + '\output\' + $name + '.csv') -Append -Encoding UTF8 -NoTypeInformation -Delimiter ';'       
        }
    } 
}

foreach ($DirectoryPath in $DirectoryPaths) {
    $starttime = Get-Date
    $directoryName = $DirectoryPath.Split('\')[-1]
    Write-Progress -Activity "Build tree. Path: $DirectoryPath" -Status "in Progress" -PercentComplete 0
    searchdouble -path $DirectoryPath -name $directoryName
    $finishtime = Get-Date
    $currenttime = $finishtime - $starttime
    write-host $currenttime.ToString() "|" $DirectoryPath 
}