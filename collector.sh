#!/bin/bash  
export ENDERECO=<ip server>
export PORTA=2607
export URL=https://$ENDERECO:$PORTA/api/OME.svc/Devices 
export USUARIO=administrator
export SENHA=<ip password>
export TAG=INDENTIFICADOR
function inventario() {
	if [ $1 -eq 0 ] 
	then
		arqtemp=$(ARQTEMP criar)
		echo \{
		echo \"data\":[
		query $URL Id | \
		while read identificador
		do
			NOME=$(query $URL/$identificador SystemName| head -n 1)
			ID="$identificador"_$NOME
			echo \{ \"\{\#$TAG\}\":\"$ID\" }, >> $arqtemp
		done
		cat $arqtemp | \
		sed -e $(cat -n $arqtemp | \
		tail -n 1 | \
		awk '{print $1}')'s/,//g'
		echo ]
		echo \}
		ARQTEMP apagar $arqtemp
	else
		cat $0.txt
	fi
	}
function analise() {
	echo ID\;SystemName\;Name\;ServiceTag\;IDracName
	query $URL Id | \
	while read identificador
	do
		ID=$(query $URL/$identificador Id| head -n 1)
		NAMESN=$(query $URL/$identificador SystemName| head -n 1)
		NAME=$(query $URL/$identificador Name| head -n 2| tail -n 1)
		NAMEST=$(query $URL/$identificador ServiceTag| head -n 1)
		NAMEIDRAC=$(query $URL/$identificador IDracName| head -n 1)
		echo $ID\;$NAMESN\;$NAME\;$NAMEST\;$NAMEIDRAC
	done
}
function ARQTEMP() {
case $1 in
		criar) mktemp --suffix=-ftp
				;;
		apagar)
				rm -fr $2
				;;
esac
}
function coletar() {
	query $URL/$1 $2
}
function query() {
	/usr/bin/curl -k --basic --ntlm --user $USUARIO:$SENHA  $1  2> /dev/null| \
	xmllint --format - | \
	grep \<$2\> | \
	awk -F \> '{print $2}' | \
	awk -F \< '{print $1}'
}
function ajuda() {
	echo ERRO
	echo inventario
	echo gerainv
	echo coletar \<id\> \<TAG\>
	echo analise
	exit 1
}
if [ $# -ne 0 ]
then
	case $1 in
		inventario)
			inventario 1
			;;
		gerainv)
			inventario 0 > $0.txt
			;;
		analise)
			analise
			;;
		coletar)
			if [ $# -ne 3 ]
			then
				ajuda
			else
				coletar $(echo $2 | awk -F _ '{print $1}') $3 | \
				head -n 1
			fi
			;;
		*)
			ajuda
			;;
	esac
else
	ajuda
fi

#Filtrar os dados por caminho do XML
#/usr/bin/curl -k --basic --ntlm --user administrator:<ip password>  https://<ip server>:2607/api/OME.svc/Devices/46 2>/dev/null | xmllint --xpath 'string(/DeviceInventoryResponse/DeviceInventoryResult/Warranty/Warranty[*]/SystemName)'  -
#/usr/bin/curl -k --basic --ntlm --user administrator:<ip password>  https://<ip server>:2607/api/OME.svc/Devices/46 2>/dev/null | xmllint --xpath 'string(/DeviceInventoryResponse/DeviceInventoryResult/Device/GlobalStatus)' -


