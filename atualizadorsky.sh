#!/bin/bash
# É GERADA UMA LISTA COM TODOS OS PROCESSOS RELACIONADOS A ARQUIVOS ABERTOS NO SAMBA
# COM O grep SOMENTE É FILTRADA AS LINHAS QUE POSSUEM A STRING INFORMADA, QUE NO CASO É O NOME DO SISTEMA (ex: imoveis, financeiro, notar...)
# O AWK FILTRA NÃO SÓ AS COLUNAS DESEJADAS, MAS TAMBÉM NÃO REPETE OS PIDS
# COMO EXTRA É MOSTRADO NA TELA O ANDAMENTO DO PROCESSO
#
# EXEMPLO DE USO: ./smbcloseopenfiles.sh imoveis
#
# PODE SER RESUMIDO A UM ÚNICO COMANDO
# for ptokill in $(smbstatus -L|grep $sistema|awk '{print $1}'|sort|uniq); do kill -9 "$ptokill" ; done
# onde $sistema É O NOME DO SISTEMA


export sistema=$1
export nversion=$2
export TESTE_AUTO="zzzconcluido.txt"
export fname=$(dirname $(find / -name "$sistema.exe" |grep "executaveis/$sistema/$sistema.exe"))

function closeof () {
	echo "FECHANDO PROCESSOS DE ARQUIVOS ABERTOS NO SERVIDOR"
	smbstatus -L|grep "$sistema"|awk '{$1=$2=$3=$4=$5=$6=""; print $0}'
	
	for ptokill in $(smbstatus -L |grep $sistema|awk '{print $1}'|sort|uniq);
	do 
		kill -9 $ptokill; 
	done
	echo && echo "PROCESSOS COM ARQUIVOS ABERTOS ENCERRADOS"
}

function renwait () {
	mv "$fname" "$fname-"
	while [ ! -f "$fname-/$TESTE_AUTO" ];
	do
	        sleep 1
	done
	sleep 2
	rm -f "$fname-/$TESTE_AUTO"
	mv "$fname-" "$fname"
}

function extnversion () {
	[ ! -f ""$fname"-/"$sistema""$nversion".zip" ] && echo "Arquivo zip com nova versão não encontrado" && exit 1
	cd "$fname-"
	echo && echo "Extraindo sistema ""$sistema""$nversion em $fname-"
	unzip -o ""$sistema""$nversion".zip"
#	> zzzconcluido.txt
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
		break
	done
}

which unzip >> /dev/null
[ $? -ne 0 ] && echo "Não foi encontrado unzip, aplicação será instalada" && installunzip
[ $# -ne 2 ] && echo "Infomar parametros: sistema versão" && exit 1
[ ! -d "$fname" ] && echo "Não foi encontrado diretório do sistema $sistema no Servidor" && exit 1


# ----- INÍCIO -----


closeof

#renwait 

sleep 2
echo && echo "renomeando $fname para $fname-"
mv "$fname" "$fname-"

sleep 2

extnversion
echo && echo "Renomeando $fname- para $fname"
mv "$fname-" "$fname"

closeof
chmod --preserve-root -R 777 "$fname"

