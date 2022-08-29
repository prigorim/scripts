#region var
#путь скрипта
$script_path = $MyInvocation.MyCommand.Path | split-path -parent

#Пароль хз нужен или нет
$mypasswd = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("SlaveName", $mypasswd)

#Тело сообщения
$MailMessage = @{
    #Кому (можно через запятую)
    To         = "ChernyshevES@sibintek.ru"
    #От
    From       = "ChernyshevES@sibintek.ru"
    #Тема
    Subject    = "test"
    #Тело
    Body       = "<h1>Ссаный текст!</h1> <p><strong>Сформировано:</strong> $(Get-Date -Format g)</p>"
    #Догадайся
    Smtpserver = "smtpserver"
    BodyAsHtml = $true
    Encoding   = "UTF8"
    #Вложения (можно через запятую)
    Attachment = $script_path+"/attachment/test.txt"
}

#Отправка сообщения
Send-MailMessage @MailMessage -Credential $cred
