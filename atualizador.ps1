# É usado o comando Get-SmbOpenFile para verificar os arquivos abertos no smb e o comando Close-SmbOpenFile para encerrar
# É filtrada apenas as linhas que contém a string com o nome do sistema no ShareRelativePath
#
# Ex de uso: atualizador.ps1 -sistema imoveis -namezip imoveis2024.01.26.0
# Sendo windows, foi considerada a possibilidade de haver sistema aberto no servidor também, por isso os comandos 
# Get-Process e Stop-Process para encerrar processos
#
# Também é verificado por arquivos na pasta do sistema sendo usados por processos
# Os handles em uso por esse processo na pasta são fechados
#
# Como extra o processo é mostrado na tela
#

param (
$sistema = $(throw "-sistema parâmetro é obrigatório. Ex: atualizador.ps1 -sistema imoveis -namezip imoveis2024.01.26.0"),
$namezip = $(throw "-namezip parâmetro é obrigatórioge. Ex: atualizador.ps1 -sistema imoveis -namezip imoveis2024.01.26.0")
)
$scdir = split-path -parent $MyInvocation.MyCommand.Definition
$skydir = Split-Path -Parent $scdir
$fname = (Get-ChildItem -Path "$skydir\*\$sistema" -Filter "$namezip.zip" -Recurse).DirectoryName
$tempdir="$fname-b"

#echo "scdir $scdir"; echo "sistema $sistema"; echo "namezip $namezip"; echo "skydir $skydir"; echo "fname $fname"#; exit

function closeof {
    Write-Host Conferindo arquivos abertos no compartilhamento
    foreach ($openfile in Get-SmbOpenFile |Where-Object ShareRelativePath -like "*$sistema*"|Select-Object FileId,Path) {
        Write-Host Ecerrando $openfile.Path
        Close-SmbOpenFile -Force $openfile.FileId
        }
}

function closeop {
    Write-Host Conferindo processos locais abertos...
    foreach ($openprocess in Get-Process |Where-Object ProcessName -Like "$sistema*"|Select-Object Id,ProcessName) {
        Write-Host Ecerrando $openprocess.ProcessName
        Stop-Process -Force -Id $openprocess.Id
        }
}

function closelof {
    rm -Force $scdir\handles.txt 2> $null
    foreach ( $pids in .\handle64.exe -NoBanner $fname | ForEach-Object { $_.split(":")[1] }|ForEach-Object { $_.split(" ")[1] }|Sort-Object -Unique ) {
        .\handle64.exe -NoBanner -p $pids | Select-String "$sistema"|Set-Content -Path $scdir\handles.txt
        echo "Encerrando handles de arquivos abertos no processo de pid $pids"; .\handle64.exe -NoBanner -p $pids | Select-String "$sistema"
        foreach ( $handles in Get-Content $scdir\handles.txt | ForEach-Object { $_.split(":")[0] } ) {
            .\handle64.exe -nobanner -p $pids -c $handles -y 2>> $null            
        }
    }
}

function extnversion {
    echo "Extraindo nova versão $namezip"
    Expand-Archive -Verbose -Force -LiteralPath "$tempdir/$namezip.zip" -DestinationPath "$tempdir"
}

function countdown {
    param ( $delay )
     
    while ($delay -ge 0) {
        start-sleep 1
        echo $delay
        $delay -= 1
    }
}
# --------------------------------------------------------------------------------
# ---------- TESTES ----------
# --------------------------------------------------------------------------------

#VERIFICANDO SE ESTÁ RODANDO COMO ADMIN
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
{
    echo "Atualização NÃO está rodando com privilégios administrativos no SERVIDOR, processo cancelado."
    Exit 1
}

#VERIFICANDO SE O DIRETÓRIO DE EXECUTÁVEL ENCONTRADO NA VAR EXISTE
if ( $null -eq $fname ) {
    echo "Não foi encontrado um diretório para o sistema: $sistema"
    exit
} 

# --------------------------------------------------------------------------------
# ---------- INÍCIO ----------
# --------------------------------------------------------------------------------
echo "INICIANDO ATUALIZAÇÃO DO SISTEMA $sistema PARA VERSÃO $namezip em"
Get-Date
echo ""; echo "Pasta de executáveis do $sistema do servidor é $fname"
cd $scdir

closeof
closeop

.\handle64.exe -accepteula ./ >> $null
if ( -not ( .\handle64.exe -nobanner $fname ).contains("No matching handles found")) {
    closelof
}

echo "Aguardando confirmação do sistema operacional do servidor..."
countdown 10

echo "Renomeando pasta $fname para $tempdir"
mv -force "$fname" "$tempdir"

extnversion

echo "Renomeando pasta $tempdir para $fname"
mv -force "$tempdir" "$fname"

echo "Processo finalizado em"
Get-Date
