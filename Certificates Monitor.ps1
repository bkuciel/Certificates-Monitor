# Variables
$EmailFrom = 'monitor@example.com'
$EmailTo = 'admins@example.com'
$EmailServer = "mailserver.domain.com" 
$EmailServerPort = "25"
$path = "$PSScriptRoot\Certificates" #Define your path to folder with certificates


$list = @()
# Build list of Certificates which will expire in 35 days
get-childitem $path | %{
    $cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $_.FullName
    if ($cert.NotAfter -lt (Get-Date).AddDays(35)) {
        Write-Host "Certificate $_" "will expire" $cert.NotAfter -ForegroundColor Yellow
        $list += $cert
    }
}

$list | select dnsnamelist, notafter


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