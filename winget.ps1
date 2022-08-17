If(!(test-path C:\TEMP\TRMM))
{
      New-Item -ItemType Directory -Force -Path C:\TEMP\TRMM
}

cd c:\temp
Invoke-WebRequest https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile vclibs.appx
Invoke-WebRequest https://github.com/microsoft/winget-cli/releases/download/v1.4.2161-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -Outfile winget.msixbundle
Add-AppxPackage c:\temp\vclibs.appx
Add-AppxPackage c:\temp\winget.msixbundle

$wingetloc=(Get-Childitem -Path "C:\Program Files\WindowsApps" -Include winget.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -Last 1 | %{$_.FullName} | Split-Path)

echo $wingetloc

cd $wingetloc

.\winget.exe upgrade --all --accept-source-agreements

.\winget.exe" search packagename --accept-source-agreements

.\winget.exe" install package.name --accept-source-agreements --accept-package-agreements
