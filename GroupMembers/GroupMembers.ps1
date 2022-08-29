#Получить состав группы
$scriptPath = $MyInvocation.MyCommand.Path | split-path -parent
$groupNames = 'ang_fs09_fold_UIT_L'

#параметры для групп поиска
$groupParametrs = 'name', 'samaccountname', 'objectClass'
#параметры для пользователей
$userParametrs = 'name', 'samaccountname', 'title', 'department', 'company'

#Рекурсивно
$recursive = $true;

#Состав группы
function groupMember {
    #var
    param (
        $parentGroup,
        $group
    )
    #Участники группы
    $groupMembers = Get-ADGroupMember $group | 
    Select-Object $groupParametrs
    #Для каждого участника
    foreach ($groupMember in $groupMembers) {
        #Если участник группа
        if ($groupMember.objectClass -eq 'group') {
            #ТО Если рекусивно
            if ($recursive) {
                #ТО Рекусивный запуск функции
                groupMember -parentgroup $group -group $groupmember.samaccountname
            }
            else {
                #Иначе
                $data = @()
                #Формирование строки объекта
                $row = New-Object PSObject
                #Добавление параметров для строки объекта
                $row | Add-Member -MemberType NoteProperty -Name 'ParentGroup' -Value $parentGroup
                $row | Add-Member -MemberType NoteProperty -Name 'Group' -Value $group
                $row | Add-Member -MemberType NoteProperty -Name 'Type' -Value $GroupMember.objectClass
                $row | Add-Member -MemberType NoteProperty -Name 'name' -Value $GroupMember.name
                $row | Add-Member -MemberType NoteProperty -Name 'samaccountname' -Value ''
                $row | Add-Member -MemberType NoteProperty -Name 'title' -Value ''
                $row | Add-Member -MemberType NoteProperty -Name 'department' -Value ''
                $row | Add-Member -MemberType NoteProperty -Name 'company' -Value ''
                #Добавление строки в объект
                $data += $row
                #Экспорт в CSV
                $data | Export-Csv -Path ($scriptPath + '\output\' + $groupName + '.csv') -Append -Encoding Default -NoTypeInformation -Delimiter ';'
            }
        }
        if ($groupMember.objectClass -eq 'user') {
            #Получение атрибутов пользователя
            $user = get-adUser $groupMember.samaccountname -Properties $userParametrs | Select-Object $userParametrs 
            #Создание нового объекта
            $data = @()
            #Формирование строки объекта
            $row = New-Object PSObject
            #Добавление параметров для строки объекта
            $row | Add-Member -MemberType NoteProperty -Name 'ParentGroup' -Value $parentGroup
            $row | Add-Member -MemberType NoteProperty -Name 'Group' -Value $group
            $row | Add-Member -MemberType NoteProperty -Name 'Type' -Value $GroupMember.objectClass
            foreach ($userParametr in $userParametrs) {
                $row | Add-Member -MemberType NoteProperty -Name $userParametr -Value $user.$userParametr
            }
            #Добавление строки в объект
            $data += $row
            #Экспорт в CSV
            $data | Export-Csv -Path ($scriptPath + '\output\' + $groupName + '.csv') -Append -Encoding Default -NoTypeInformation -Delimiter ';'
        }
        #Если участник компьютер или контакт
        if (($groupMember.objectClass -eq 'computer') -or ($groupMember.objectClass -eq 'contact')) {
            #Создание нового объекта
            $data = @()
            #Формирование строки объекта
            $row = New-Object PSObject
            #Добавление параметров для строки объекта
            $row | Add-Member -MemberType NoteProperty -Name 'ParentGroup' -Value $parentGroup
            $row | Add-Member -MemberType NoteProperty -Name 'Group' -Value $group
            $row | Add-Member -MemberType NoteProperty -Name 'Type' -Value $GroupMember.objectClass
            $row | Add-Member -MemberType NoteProperty -Name 'name' -Value $GroupMember.name
            $row | Add-Member -MemberType NoteProperty -Name 'samaccountname' -Value ''
            $row | Add-Member -MemberType NoteProperty -Name 'title' -Value ''
            $row | Add-Member -MemberType NoteProperty -Name 'department' -Value ''
            $row | Add-Member -MemberType NoteProperty -Name 'company' -Value ''
            #Добавление строки в объект
            $data += $row
            #Экспорт в CSV
            $data | Export-Csv -Path ($scriptPath + '\output\' + $groupName + '.csv') -Append -Encoding Default -NoTypeInformation -Delimiter ';'
        }
    }
} 

#Для каждой группы в списке групп
foreach ($groupName in $groupNames) {
    groupMember -parentGroup $groupName -group $groupName
}