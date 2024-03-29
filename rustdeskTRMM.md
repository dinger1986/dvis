## To install Rustdesk and use it with Tactical RMM you need to the the following.

1. Create the following scripts (all are powershell other than the batch script to get the ID).
2. Create a [URL Action](https://docs.tacticalrmm.com/functions/url_actions/)
3. Create [custom fields](https://docs.tacticalrmm.com/functions/custom_fields/) for the RustDesk ID and password
4. Create [collector tasks](https://docs.tacticalrmm.com/functions/automated_tasks/#collector-tasks)
5. Enjoy :)

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

# Stop RustDesk first
net stop rustdesk > null
$ProcessActive = Get-Process rustdesk -ErrorAction SilentlyContinue
if($ProcessActive -ne $null)
{
stop-process -ProcessName rustdesk -Force
}

$rustdesk_pw = (-join ((65..90) + (97..122) | Get-Random -Count 12 | % {[char]$_})) 
Start-Process "$env:ProgramFiles\RustDesk\RustDesk.exe" "--password $rustdesk_pw" -wait
Write-Output $rustdesk_pw

net start rustdesk > null

```
### RustDesk URL Action
```
rustdesk://connection/new/{{agent.rustdeskid}}?password={{agent.rustdeskpwd}}
 ```
## Add Custom Agent Fields
`rustdeskid Type = Text` </br>
`rustdeskpwd Type = Text`
