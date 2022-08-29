#region var
#Путь до скрипта
$scriptPath = $MyInvocation.MyCommand.Path | split-path -parent
#База поиска
$searchBase = 'OU=AG ANGARSK,OU=RN,DC=rosneft,DC=ru'
#Характеристики пользователя
$userProperties = 'company', 'title', 'department', 'physicalDeliveryOfficeName', 'LastLogonDate'
#Выборка пользователя
$userSelect = 'department', 'physicalDeliveryOfficeName', 'sAMAccountName', 'name', 'title', 'LastLogonDate'
#endregion var

#region functions
#Активные пользователи АНХРС, РН-ПБ, РН-УЧЕТ,
function activeUsersMonth ($output) {
    #Получить список пользователей по фильтру
    Get-ADUser -SearchBase $searchBase -Filter { company -eq 'АНХРС' -and description -eq 'Временно' } -Properties $userProperties | 
    Where-Object { $_.Enabled -eq $True -and $_.LastLogonDate -ge (get-date).adddays(-30) } |
    Select-Object $userSelect | Sort-object name |
    Export-Csv -path ($output + 'ANHRS.csv') -Delimiter ';' -NoTypeInformation -Encoding Default
    #Получить список пользователей по фильтру
    Get-ADUser -SearchBase $searchBase -Filter * -Properties $userProperties |
    Where-Object { $_.company -match "^.*РН.?-.?УЧЕТ.*$" -and $_.Enabled -eq $True -and $_.LastLogonDate -ge (get-date).adddays(-30) } |
    Select-Object $userSelect | Sort-object name |
    Export-Csv -path ($output + 'RNU.csv') -Delimiter ';' -NoTypeInformation -Encoding Default
    #Получить список пользователей по фильтру
    Get-ADUser -SearchBase $searchBase -Filter * -Properties $userProperties |
    Where-Object { $_.company -match "^.*РН.?-.?Пожарная Безопасность.*$" -and $_.Enabled -eq $True -and $_.LastLogonDate -ge (get-date).adddays(-30) } |
    Select-Object $userSelect | Sort-object name |
    Export-Csv -path ($output + 'RNPB.csv') -Delimiter ';' -NoTypeInformation -Encoding Default
}
#endregion functions

activeUsersMonth -output ($scriptPath + '\output\')