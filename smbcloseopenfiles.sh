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


sistema=$1

echo "FECHANDO PROCESSOS DE ARQUIVOS ABERTOS NO SERVIDOR"
smbstatus -L|grep "$sistema"|awk '{$1=$2=$3=$4=$5=$6=""; print $0}'

for ptokill in $(smbstatus -L |grep $sistema|awk '{print $1}'|sort|uniq);
do 
	kill -9 $ptokill; 
done

echo "PROCESSOS COM ARQUIVOS ABERTOS ENCERRADOS"

