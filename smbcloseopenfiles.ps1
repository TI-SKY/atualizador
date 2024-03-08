# É usado o comando Get-SmbOpenFile para verificar os arquivos abertos no smb e o comando Close-SmbOpenFile para encerrar
# É filtrada apenas as linhas que contém a string com o nome do sistema no ShareRelativePath
# A string é informada em parâmetro
# Ex de uso: smbcloseopenfiles.ps1 -sistema imoveis
# Sendo windows, foi considerada a possibilidade de haver sistema aberto no servidor também, por isso os comandos 
# Get-Process e Stop-Process para encerrar processos
# Como extra o processo é mostrado na tela
#
# O script Pode ser resumido nos comandos
# Get-SmbOpenFile |Where-Object ShareRelativePath -like "*$sistema*" |Close-SmbOpenFile -Force
# Get-Process |Where-Object ProcessName -Like "$sistema*"|Stop-Process -Force

param ($sistema = $(throw "-sistema parameter is required. Ex: smbcloseopenfiles.ps1 -sistema imoveis"))

Write-Host Conferindo arquivos abertos no compartilhamento
foreach ($openfile in Get-SmbOpenFile |Where-Object ShareRelativePath -like "*$sistema*"|Select-Object FileId,Path) {
    Write-Host Ecerrando $openfile.Path
    Close-SmbOpenFile -Force $openfile.FileId
    }


Write-Host Conferindo processos locais abertos...
foreach ($openprocess in Get-Process |Where-Object ProcessName -Like "$sistema*"|Select-Object Id,ProcessName) {
    Write-Host Ecerrando $openprocess.ProcessName
   Stop-Process -Force -Id $openprocess.Id
    }
