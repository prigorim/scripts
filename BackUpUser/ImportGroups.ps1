#region var
#Путь скрипта
$scriptPath = $MyInvocation.MyCommand.Path | split-path -parent
#Имя CSV
$csvFile = '01.07.2022_17.01_ScherbakovOA.csv'
#Путь до CSV
$csvPath = $scriptPath + '\archive\' + $csvFile
#endregion var

#region funcions
function ImportGroups {
    #Считываем CSV
    $csv = Import-csv -path $csvPath -Delimiter ';' -Encoding Default
    #Обработчик для групп
    $groups = $csv.memberof.split(',') | Where-Object { $_ -like '*cn=*' }
    $groups = $groups.Replace('DC=ru ', '').replace('CN=', '')
    #Вывод
    $groups
}
#endregion functions

#Вызов функции
ImportGroups