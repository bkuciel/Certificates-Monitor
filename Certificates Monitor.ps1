### Variables ###
#region Variables
# Mailserver
$EmailFrom = 'monitor@example.com'
$EmailTo = 'admins@example.com'
$EmailServer = "mailserver.domain.com" 
$EmailServerPort = "25"
# Define the number of days - if the expiration date of the certificate 
# is less than the defined number of days, an e-mail notification will be sent
$days = 35

# Define your path to folder with certificates or leave the setting and create folder "Certificates" in folder where the script is located
$path = "$PSScriptRoot\Certificates" 
#endregion

# Create Certificates folder if it doesn't exist
if (-not (Test-Path -Path $path)) {
    New-Item -ItemType Directory -Path $path
    Write-Host "Created directory: $path" -ForegroundColor Green
}


$list = @()
# Build list of Certificates which will expire in defined time
get-childitem $path | ForEach-Object{
    $cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $_.FullName
    if ($cert.NotAfter -lt (Get-Date).AddDays($days)) {
        Write-Host "Certificate $_" "will expire" $cert.NotAfter -ForegroundColor Yellow
        $list += $cert
    }
}

$list | select dnsnamelist, notafter

#Send mail for each certificate which is about to expire
foreach ($item in $list)
{
        $subject              = $item.subject.ToString()
        $subject              = $subject.Replace("CN=","")
        $expiration           = $item.NotAfter.ToString()
        $DNSName              = $item.DnsNameList.unicode.ToString()
        $EmailSubject         = "Certificate $subject will expire on $expiration"
        $EmialBody            = "
Please verify certificate expiration of $subject.

Certificate will expire on:             $expiration
Certificate DNS names:                  $DNSName

Please remember to replace newly generated certificate in monitored folder.
"

        $EmailPriority        = "Normal" # Normal, High

        # Send e-mail
        Send-MailMessage -To $EmailTo -From $EmailFrom -SmtpServer $EmailServer -Port $EmailServerPort `
        -Subject $EmailSubject -Priority $EmailPriority -Body $EmialBody
}