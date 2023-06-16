## Install Script Replace IPADDRESS and KEY
```
$ErrorActionPreference= 'silentlycontinue'

If (!(Test-Path c:\Temp)) {
  New-Item -ItemType Directory -Force -Path c:\Temp > null
}

cd c:\Temp

powershell Invoke-WebRequest "https://github.com/rustdesk/rustdesk/releases/download/nightly/rustdesk-1.2.0-x86_64.exe" -Outfile "rustdesk.exe"
Start-Process .\rustdesk.exe --silent-install -wait

$ServiceName = 'Rustdesk'
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($arrService -eq $null)
{
    Start-Sleep -seconds 20
}

while ($arrService.Status -ne 'Running')
{
    Start-Service $ServiceName
    Start-Sleep -seconds 5
    $arrService.Refresh()
}
net stop rustdesk

$username = ((Get-WMIObject -ClassName Win32_ComputerSystem).Username).Split('\')[1]
Remove-Item C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml
New-Item C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml
Set-Content C:\Users\$username\AppData\Roaming\RustDesk\config\RustDesk2.toml "rendezvous_server = 'IPADDRESS' `nnat_type = 1`nserial = 0`n`n[options]`ncustom-rendezvous-server = 'IPADDRESS'`nkey = 'KEY='`nrelay-server = 'IPADDRESS'`napi-server = 'https://IPADDRESS'"
Remove-Item C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml
New-Item C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml
Set-Content C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml "rendezvous_server = 'IPADDRESS' `nnat_type = 1`nserial = 0`n`n[options]`ncustom-rendezvous-server = 'IPADDRESS'`nkey = 'KEY='`nrelay-server = 'IPADDRESS'`napi-server = 'https://IPADDRESS'"

net start rustdesk
```

## RustDesk Get ID (batch) (Collector Script needs Custom Agent Field)
```
"c:\Program Files\RustDesk\RustDesk.exe" --get-id
 ```
## RustDesk Set and Get Password (Collector Script needs Custom Agent Field)
```
$ErrorActionPreference= 'silentlycontinue'

net stop rustdesk > null
taskkill /IM "rustdesk.exe" /F > null

$rustdesk_pw = (-join ((65..90) + (97..122) | Get-Random -Count 12 | % {[char]$_})) 
Start-Process "$env:ProgramFiles\RustDesk\RustDesk.exe" "--password $rustdesk_pw" -wait
Write-Output $rustdesk_pw

net start rustdesk > null

```
### RustDesk URL Action
```
rustdesk://connection/new/{{agent.rustdeskid}}?password={{agent.rustdeskpwd}}
 ```
## Add Custom Agent Field
`rustdeskid Type = Text`
`rustdeskpwd Type = Text`
