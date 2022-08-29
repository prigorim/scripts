#region var

#Путь к скрипту
$scriptPath = $MyInvocation.MyCommand.Path | split-path -parent
#Путь к папке
$accessDirectoryPaths = "\\angarsk-fs09\Folders\RNU"

#Создать файл групп доступа для папки
$createFileAccess = $false
#Создать список групп доступа для папки
$createGroupsList = $true
#Сортировка
$sortUserList = $true
$sortProperties = 'ParentGroup', 'Group', 'samaccountname'


#параметры для групп поиска
$groupParametrs = 'name', 'samaccountname', 'objectClass'
#параметры для пользователей
$userParametrs = 'name', 'samaccountname', 'title', 'department', 'company'
#edregion var

#region functions

#Создать файл доступа
function createFileAccess {
    #var
    param (
        $path,
        $name
    )
    #Получить access по path и вывести в csv
    (Get-Acl -Path $path).Access | 
    Select-Object IdentityReference, FileSystemRights  | 
    Where-Object { $_.IdentityReference -like 'ROSNEFT\*' } |
    Export-CSV -Path ($scriptPath + '\output\' + $accessDirectoryName + "\" + $accessDirectoryName + ".csv") -Encoding Default -NoTypeInformation -Delimiter ';'
}

#Состав группы
function groupMember {
    #var
    param (
        $parentGroup,
        $group,
        $access
    )
    #Список состава группы
    $items = Get-ADGroupMember $group | Select-Object $groupParametrs
    #Для каждого в составе
    foreach ($item in $items) {
        #Если группа
        if ($item.objectClass -eq 'group') {
            #Рекусивный вызов функции
            groupMember -parentGroup $group -group $item.samaccountname -access $access
        }
        #Если пользователь
        if ($item.objectClass -eq 'user') {
            #Получить атрибуты пользователя
            $user = get-adUser $item.samaccountname -Properties $userParametrs | Select-Object $userParametrs 
            #Создание нового объекта
            $data = @()
            #Формирование строки объекта
            $row = New-Object PSObject
            $row | Add-Member -MemberType NoteProperty -Name 'ParentGroup' -Value $parentGroup
            $row | Add-Member -MemberType NoteProperty -Name 'Group' -Value $group
            $row | Add-Member -MemberType NoteProperty -Name 'Type' -Value $item.objectClass
            $row | Add-Member -MemberType NoteProperty -Name 'FileSystemRights' -Value $access
            foreach ($userParametr in $userParametrs) {
                $row | Add-Member -MemberType NoteProperty -Name $userParametr -Value $user.$userParametr
            }
            #Добавление строки в объект
            $data += $row
            #Экспорт в CSV
            $data | Export-Csv -Path ($scriptPath + '\output\' + $accessDirectoryName + "\" + $accessDirectoryName + "users.csv") -Append -Encoding Default -NoTypeInformation -Delimiter ';'
        }
    } 
}

#Сортировка пользователей
function sortUserList {
    #Импортировать CSV и отсортировать по sortProperties и вывести под новым именем
    Import-CSV ($scriptPath + '\output\' + $accessDirectoryName + "\" + $accessDirectoryName + "users.csv") -Encoding Default -Delimiter ';' |
    Sort-Object -Property $sortProperties |
    Export-Csv -Path ($scriptPath + '\output\' + $accessDirectoryName + "\" + $accessDirectoryName + "userssort.csv") -Encoding Default -NoTypeInformation -Delimiter ';' 
}
#endregion functions


foreach ($accessDirectoryPath in $accessDirectoryPaths) {

    #Имя папки
    $accessDirectoryName = $accessDirectoryPath.split('\')[-1]

    #Создание папок для вывода всей инфы
    New-Item -ItemType "directory" -Force -Path ($scriptPath + "\output\" + $accessDirectoryName)

    #Создание файла доступа групп до папки
    if ($createFileAccess) { 
        createFileAccess -path $accessDirectoryPath -name $accessDirectoryName 
    }

    #Если создавать лист групп
    if ($createGroupsList) {
        #Импортируем CSV
        $accessGroups = Import-CSV -Path ($scriptPath + '\output\' + $accessDirectoryName + "\" + $accessDirectoryName + ".csv") -Encoding Default -Delimiter ';'
        #Для каждой группы доступа
        foreach ($accessGroup in $accessGroups) {
            #Обрабатываем имя
            $groupName = $accessGroup.IdentityReference.trimStart('ROSNEFT\')
            #Присваеваем права
            $groupAccess = $accessGroup.FileSystemRights
            #Узнаем состав группы
            groupMember -parentGroup $accessDirectoryName -group $groupName -access $groupAccess
        }
    }

    # если сортировать то сортируем
    if ($sortUserList) {
        sortUserList 
    }
}