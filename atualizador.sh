#!/bin/bash
# É GERADA UMA LISTA COM TODOS OS PROCESSOS RELACIONADOS A ARQUIVOS ABERTOS NO SAMBA
# COM O grep SOMENTE É FILTRADA AS LINHAS QUE POSSUEM A STRING INFORMADA, QUE NO CASO É O NOME DO SISTEMA (ex: imoveis, financeiro, notar...)
# O |awk|sort|uniq FILTRAM NÃO SÓ AS COLUNAS DESEJADAS, MAS TAMBÉM NÃO REPETEM OS PIDS
#
# EXEMPLO DE USO: ./atualizador.sh "imoveis" "imoveis2024.01.26.0"
# após encerrar os processoss dos arquivos abertos, é renomeada a pasta do executável
# o zip é extraído na nova pasta, a pasta é renomeada para o padrão
# a permissão 777 é aplicada na pasta
#
# A pasta do atulizador deverá ficar dentro do diretório sky, assim, informando o nome do zip a ser descompactado
# o script poderá navegar considerando a pasta sky como diretório root, facilitando a identicação da pasta correta do sistema e arquivo da nova versão
# 
# Antes de iniciar os comandos são feitas diversas validações
# No final é removido .zip mais antigos que 180 dias

export sistema=$1
export namezip=$2
export scdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
skydir=$(cd $scdir; cd ..; pwd)
export fname=$(dirname $(find / -wholename "$skydir*$namezip.zip" 2> /dev/null) 2> /dev/null)
export tempdir="$fname-b"
export daystoremove=180
#echo scdir $scdir; echo skydir $skydir; echo fname $fname; exit

function closeof () {
	echo "FECHANDO PROCESSOS DE ARQUIVOS ABERTOS NO COMPARTILHAMENTO DO SERVIDOR"
	smbstatus -L|grep "$sistema"|awk '{$1=$2=$3=$4=$5=$6=""; print $0}'
	
	for ptokill in $(smbstatus -L |grep $sistema|awk '{print $1}'|sort|uniq);
	do 
		kill -9 $ptokill; 
	done
	echo && echo "Processos com arquivos abertos no compartilhamento encerrados."
}

function closelof () {
	echo && echo "VERIFICANDO ARQUIVOS ABERTOS LOCALMENTE EM $fname"
	for lof in $(lsof -t +D $fname)
	do 
		echo && echo "Encerrando processo local de pid $lof"
		kill -9 $lof 
	done
}

function extnversion () {
	[ ! -f ""$tempdir"/"$namezip".zip" ] && echo "Arquivo zip com nova versão não encontrado" && exit 1
	cd "$tempdir"
	echo && echo "Extraindo sistema "$namezip" em $tempdir"
	unzip -o ""$namezip".zip"
	cd ..
}

function installunzip () {
	while true
	do
		which apt >> /dev/null
		[ $? -eq 0 ] && apt install -y unzip >> /dev/null && echo "apt install -y unzip" && break
	        which yum >> /dev/null
	        [ $? -eq 0 ] && yum install -y unzip >> /dev/null && echo "yum install -y unzip" && break
	        which apt >> /dev/null
	        [ $? -eq 0 ] && dnf install -y unzip >> /dev/null && echo "dnf install -y unzip" && break
		echo && echo "Não foi possível instalar o unzip"
		break
	done
}

function countdown () {
	delay=$1
	while [ $delay -ge 0 ]
	do
		echo $delay
		sleep 1
		((delay--))
	done
}

[ $# -ne 2 ] && echo "Infomar parametros: sistema e nome do zip (sem extensão)" && exit 1
which unzip >> /dev/null
[ $? -ne 0 ] && echo "Não foi encontrado unzip, aplicação será instalada" && installunzip
[ ! -f "$fname"/"$namezip".zip ] && echo "Não foi encontrado o zip da nova versão $namezip.zip no Servidor" && exit 1
which smbstatus >> /dev/null
[ $? -ne 0 ] && echo "Não foi encontrado comando smbstatus" && exit 1

# ----- INÍCIO -----
echo "INICIANDO ATUALIZAÇÃO DO SISTEMA $sistema PARA VERSÃO $namezip"

closeof

closelof

echo && echo "Aguardando confirmação..."
countdown 10

echo && echo "renomeando $fname para $tempdir"
mv "$fname" "$tempdir"

extnversion

echo && echo "Renomeando $tempdir para $fname"
mv "$tempdir" "$fname"

closeof
closelof

echo && echo "Dando permissão no diretório $fname e novos arquivos"
chmod --preserve-root -R 777 "$fname"

echo && echo "Apagando arquivos .zip antigos"
#find "$fname" -name ""$sistema"*zip" -mtime +$daystoremove -exec rm {} \;
