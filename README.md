# ko_language_set
한글패치

# Command Sample
```
# Optional
az vm extension delete -g {리소스그룹명} --vm-name {가상머신명} --name CustomScriptExtension

az vm extension set \
  --resource-group {리소스그룹명} --vm-name {가상머신명} \
  --publisher Microsoft.Compute --name CustomScriptExtension --version 1.10 \
  --settings '{"fileUris":["https://raw.githubusercontent.com/peterlah/ko_language_set/main/Set-KoreanLanguage.ps1"]}' \
  --protected-settings '{"commandToExecute":"powershell -ExecutionPolicy Bypass -File Set-KoreanLanguage.ps1"}'
```
