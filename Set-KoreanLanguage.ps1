#Requires -RunAsAdministrator
<#
  Set-KoreanLanguage.ps1
  Azure Windows 11 Pro (English image) -> apply Korean automatically

  - Installs the Korean language pack and related Features on Demand (FOD)
  - Sets system-wide Korean (welcome screen / system locale / default UI language)
  - Registers a logon task that applies per-user Korean settings
    (Custom Script Extension runs as SYSTEM, so a logon task is required
     to apply settings to the actual interactive user)

  Requires: administrator rights, internet access (downloads the language pack)
  A restart is required after completion.

  ASCII-only on purpose: Windows PowerShell 5.1 reads a BOM-less .ps1 using the
  system ANSI code page, so any non-ASCII text can be mis-decoded and break.
#>

$ErrorActionPreference = 'Stop'
$lang  = 'ko-KR'
$geoId = 134            # South Korea

Write-Host '== Installing Korean language pack (may take several minutes) =='
Install-Language $lang -CopyToSettings

Write-Host '== System-wide settings (UI language / system locale) =='
Set-SystemPreferredUILanguage $lang
Set-WinSystemLocale $lang

Write-Host '== Current (SYSTEM) context user settings =='
Set-WinUILanguageOverride -Language $lang
Set-WinUserLanguageList (New-WinUserLanguageList $lang) -Force
Set-Culture $lang
Set-WinHomeLocation -GeoId $geoId

Write-Host '== Copy settings to welcome screen / new user accounts =='
Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true

Write-Host '== Register one-time per-user logon task =='
$perUser = 'C:\ProgramData\Set-KoreanForUser.ps1'

# Build the per-user script as a string array (no here-string; line-ending safe)
$perUserContent = @(
    '$marker = ''HKCU:\Software\KoreanLangApplied''',
    'if (-not (Test-Path $marker)) {',
    '    Set-WinUILanguageOverride -Language ko-KR',
    '    Set-WinUserLanguageList (New-WinUserLanguageList ''ko-KR'') -Force',
    '    Set-Culture ko-KR',
    '    Set-WinHomeLocation -GeoId 134',
    '    New-Item -Path $marker -Force | Out-Null',
    '}'
)
Set-Content -Path $perUser -Value $perUserContent -Encoding UTF8

$taskArg   = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $perUser + '"'
$action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $taskArg
$trigger   = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -GroupId 'BUILTIN\Users' -RunLevel Limited
Register-ScheduledTask -TaskName 'Apply-KoreanLanguage' -Action $action -Trigger $trigger -Principal $principal -Force

Write-Host ''
Write-Host 'Done. After a reboot and sign-in the UI will be in Korean.'
# Auto-reboot is not recommended (rebooting during CSE makes the extension report failure).
# Reboot separately with: az vm restart   after the extension succeeds.
