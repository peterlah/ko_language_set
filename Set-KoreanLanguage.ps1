햐#Requires -RunAsAdministrator
<#
  Set-KoreanLanguage.ps1
  Azure Windows 11 Pro (영어 이미지) -> 한국어 자동 적용

  - 한국어 언어팩 + 관련 기능(FOD) 설치
  - 시스템 전역(로그온 화면 / 시스템 로캘 / 기본 UI 언어) 한국어 설정
  - 로그온하는 사용자에게 한국어 사용자 설정을 적용하는 작업 등록
    (Custom Script Extension은 SYSTEM 권한으로 실행되므로,
     실제 로그온 사용자에게 적용하려면 로그온 작업이 필요)

  요구사항: 관리자 권한, 인터넷 연결(언어팩 다운로드)
  적용 완료 후 재부팅 필요
  (here-string/백틱은 LF 줄바꿈에서 깨질 수 있어 의도적으로 사용하지 않음)
#>

$ErrorActionPreference = 'Stop'
$lang  = 'ko-KR'
$geoId = 134            # 대한민국

Write-Host '== 한국어 언어팩 설치 중 (수 분 소요 가능) =='
Install-Language $lang -CopyToSettings

Write-Host '== 시스템 전역 설정 (UI 언어 / 시스템 로캘) =='
Set-SystemPreferredUILanguage $lang
Set-WinSystemLocale $lang

Write-Host '== 현재(SYSTEM) 컨텍스트 사용자 설정 =='
Set-WinUILanguageOverride -Language $lang
Set-WinUserLanguageList (New-WinUserLanguageList $lang) -Force
Set-Culture $lang
Set-WinHomeLocation -GeoId $geoId

Write-Host '== 환영 화면 / 신규 사용자 계정에 설정 복사 =='
Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true

Write-Host '== 로그온 사용자용 1회 적용 작업 등록 =='
$perUser = 'C:\ProgramData\Set-KoreanForUser.ps1'

# here-string 대신 문자열 배열로 작성 (줄바꿈 형식에 영향 없음)
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
Write-Host '완료. 재부팅 후 로그온하면 한국어 UI가 적용됩니다.'
# 자동 재부팅은 권장하지 않음 (CSE 실행 중 재부팅하면 확장이 실패로 보고됨).
# 확장 성공 후 az vm restart 로 따로 재부팅하세요.
