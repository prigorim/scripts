#Получить состав OU
$scriptPath = $MyInvocation.MyCommand.Path | split-path -parent
$OUPaths = 'OU=LIMS,OU=PI_LIMS_SPU,OU=Application,OU=Groups,OU=AG ANGARSK,OU=RN,DC=rosneft,DC=ru', 'OU=OURR,OU=PI_LIMS_SPU,OU=Application,OU=Groups,OU=AG ANGARSK,OU=RN,DC=rosneft,DC=ru'

#Создание директории для выходных файлов
$createOUDirectory = $true

#параметры для групп поиска
$groupParametrs = 'name', 'samaccountname', 'objectClass'
#параметры для пользователей
$userParametrs = 'name', 'samaccountname', 'title', 'department', 'company'
#параметры для OU
$ouParametrs = 'SamAccountName', 'ObjectClass', 'Name', 'DistinguishedName'


#region functions

#Создание директории
function createOUDirectory {
    #var
    param (
        $path = $scriptPath + "\output\" + $OUDirectoryName
    )
    #Создание папок для вывода всей инфы
    New-Item -ItemType "directory" -Force -Path $path
}

#Список состава группы
function groupMember {
    #var
    param (
        $parentGroup,
        $group,
        $OUName
    )
    #Сформировать список состава группы
    $groupMembers = Get-ADGroupMember $group | Select-Object $groupParametrs
    #Для каждого участника группы
    foreach ($groupMember in $groupMembers) {
        #Если участник группа
        if ($groupmember.objectClass -eq 'group') {
            #Рекурсивный вызов функции с новыми параметрами
            groupMember -parentGroup $group -group $groupMember.samaccountname -OUName $OUName
        }
        #Если участник пользователь
        if ($groupMember.objectClass -eq 'user') {
            #Получение атрибутов пользователя
            $user = get-adUser $groupMember.samaccountname -Properties $userParametrs | Select-Object $userParametrs 
            #Создание нового объекта
            $data = @()
            #Формирование строки объекта
            $row = New-Object PSObject
            #Добавление параметров для строки объекта
            $row | Add-Member -MemberType NoteProperty -Name 'OU' -Value $OUName
            $row | Add-Member -MemberType NoteProperty -Name 'ParentGroup' -Value $parentGroup
            $row | Add-Member -MemberType NoteProperty -Name 'Group' -Value $group
            $row | Add-Member -MemberType NoteProperty -Name 'Type' -Value $GroupMember.objectClass
            foreach ($userParametr in $userParametrs) {
                $row | Add-Member -MemberType NoteProperty -Name $userParametr -Value $user.$userParametr
            }
            #Добавление строки в объект
            $data += $row
            #Экспорт в CSV
            $data | Export-Csv -Path ($scriptPath + '\output\' + $OUDirectoryName + '\' + $OUName + '.csv') -Append -Encoding Default -NoTypeInformation -Delimiter ';'
        }
        #Если участник компьютер или контакт
        if (($groupMember.objectClass -eq 'computer') -or ($groupMember.objectClass -eq 'contact')) {
            #Создание нового объекта
            $data = @()
            #Формирование строки объекта
            $row = New-Object PSObject
            #Добавление параметров для строки объекта
            $row | Add-Member -MemberType NoteProperty -Name 'OU' -Value $OUName
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
            $data | Export-Csv -Path ($scriptPath + '\output\' + $OUDirectoryName + '\' + $OUName + '.csv') -Append -Encoding Default -NoTypeInformation -Delimiter ';'
        }
    } 
}

#Состав OU
function OUMembers {
    #var
    param (
        $currentOUPath,
        $OUName
    )
    #Сформировать список участников OU
    Get-ADOrganizationalUnit -identity $currentOUPath
    $OUMembers = Get-ADObject -Filter * -searchbase $currentOUPath -properties $ouParametrs | 
    Select-Object $ouParametrs
    #Для каждого контейнера OU
    foreach ($OUMember in $OUMembers) {
        #Если котейнер OU
        if ($OUMember.objectClass -eq 'organizationalUnit') {
            #Если имя контейнера не имя текущего OU
            if ($OUMember.name -ne $OUName) {
                #Рекурсивный вызов функции
                OUMembers -currentOUPath $OUMember.DistinguishedName -OUName $OUMember.name
            }
        }
        #Если контейнер группа
        if ($OUmember.objectclass -eq 'group') {
            #Вызов функции
            groupMember -parentGroup $OUName -group $OUMember.samaccountname -OUName $OUName
        }
        #Если контейнер пользователь
        if ($OUmember.objectclass -eq 'user') {
            #Получить атрибуты пользователя
            $user = get-adUser $OUMember.samaccountname -Properties $userParametrs | Select-Object $userParametrs 
            #Создание нового объекта
            $data = @()
            #Формирование строки объекта
            $row = New-Object PSObject
            #Добавление параметров для строки объекта
            $row | Add-Member -MemberType NoteProperty -Name 'OU' -Value $OUName
            $row | Add-Member -MemberType NoteProperty -Name 'ParentGroup' -Value $OUName
            $row | Add-Member -MemberType NoteProperty -Name 'Group' -Value $OUName
            $row | Add-Member -MemberType NoteProperty -Name 'Type' -Value $OUMember.objectClass
            foreach ($userParametr in $userParametrs) {
                $row | Add-Member -MemberType NoteProperty -Name $userParametr -Value $user.$userParametr
            }
            #Добавление строки в объект
            $data += $row
            #Экспорт в CSV
            $data | Export-Csv -Path ($scriptPath + '\output\' + $OUDirectoryName + '\' + $OUName + '.csv') -Append -Encoding Default -NoTypeInformation -Delimiter ';'
        }    
    }
}
#endregion functions


#Вызов функции для всех путей
foreach ($OUPath in $OUPaths) {
    $OUDirectoryName = $OUPath.split(',')[0].replace('OU=','')
    #создание OU папки
    if ($createOUDirectory) {
        createOUDirectory 
    }
    OUMembers -currentOUPath $OUPath -OUName $OUDirectoryName
}