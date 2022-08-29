#region var
#путь скрипта
$script_path = $MyInvocation.MyCommand.Path | split-path -parent
#Пользователи для бэка
$csvUsers = Import-CSV -Path ($script_path + '/users.csv') -Delimiter ';' -Encoding Default
$users = $csvUsers.SamAccountName
#Текущая дата
$date = [string](Get-Date -Format 'dd/MM/yyyy HH:mm')
$datestring = $date.Replace('/', '.').Replace(' ', '_').Replace(':', '.')
#Поля для сохранения
$MembersProperties = 'Type', 'SamAccountName', 'DisplayName', 'Title', 'Department', ' Company' 
$MembersProperties += 'Notes', 'telephoneNumber', 'objectSid', 'objectGUID', 'st', 'l', 'City'
$MembersProperties += 'office', 'UserPrincipalName', 'MemberOf', 'NestedMemberOf', 'AllMemberOf'
#endregion var

#region functions
function BackUpUser {
    #Для каждого пользователя в списке пользователей
    foreach ($user in $users) {
        #Создаём объект описания
        $data = @()
        $row = New-Object PSObject
        #Для каждого параметра в списке параметров
        foreach ($MembersProperty in $MembersProperties) {
            #Приводим в вид строк
            $memberstring = [string](get-qaduser $user).$MembersProperty
            #Для каждой строки в списке строк
            foreach ($memberstr in $memberstring) {
                #Добавляем значение в результирующую строку 
                $row | Add-Member -MemberType NoteProperty -Name $MembersProperty -Value $memberstr
            }
        }
        #Добавляем в объект описания
        $data += $row
        #Добавляем в выходной файл
        $data | Export-Csv -Path ($script_path + '\output\' + $datestring + '_' + $user + '.csv') -Append -Encoding Default -NoTypeInformation -Delimiter ';'
    }
}
#endregion functions

#Вызов функци
BackUpUser