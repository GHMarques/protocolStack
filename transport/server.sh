#!/bin/bash

#global variables
logFilePath='../file/logTransportLayer.txt';
macAddressFilePath='../file/macAddress.txt';
pduTransportReceived='../file/pduTransportReceived.txt';
pduTransportResponse='../file/pduTransportResponse.txt';
pduApplicationResponse='../file/ipResponse.txt';
lenght='0000000000000000';
windowLimit=1000000000; #Decisao de projeto -> janela tem 512 bytes
oneComplement=0000000000000001;

#functions
: '
    log function
    how to use: log message
'
log(){
    echo $(date +'%Y-%m-%d %r') '-' $1 >> $logFilePath;
}

sum(){
    sum=$(echo "ibase=2;obase=2; $1+$2" | bc);
    size=${#sum};
    while [ $size -lt 16 ]
    do
        sum=0$sum
        size=${#sum};
    done
    
    echo $sum;
}

sum32(){
    sum=$(echo "ibase=2;obase=2; $1+$2" | bc);
    size=${#sum};
    while [ $size -lt 32 ]
    do
        sum=0$sum
        size=${#sum};
    done
    
    echo $sum;
}

minus(){
    sum=$(echo "ibase=2;obase=2; $1-$2" | bc);
    size=${#sum};
    while [ $size -lt 10 ]
    do
        sum=0$sum
        size=${#sum};
    done
    
    echo $sum;
}

payloadToMacAddress(){
    size=${#1};
    i=0;
    convertion="";
    while [ $i -lt $size ]
    do
        bits=$(echo ${1:i:16})
        i=$(($i+16))
        convertion=$convertion$(echo "obase=16; ibase=2; $bits" | bc):;
    done

    echo ${convertion::-1}
}

udp(){
    echo "udp function";    
}

tcp(){
    if [ -f "$pduTransportReceived" ];
    then
        log "Camada de transporte do servidor recebe PDU.";
        pdu=$(cat $pduTransportReceived);
        #portas de origem e destino (16 bits)
        srcPort=${pdu:0:16};
        dstPort=${pdu:16:16};
        #numero de sequencia e confirmacao (32 bits)
        sequence=${pdu:32:32};
        acknowledgement=${pdu:64:32};
        #janela (10 bits) - tamanho maximo que pode ser enviado
        window=${pdu:96:10};
        #flags (1 bit)
        urg=${pdu:106:1};
        ack=${pdu:107:1};
        psh=${pdu:108:1};
        rst=${pdu:109:1};
        syn=${pdu:110:1};
        fin=${pdu:111:1};
        #checksum (16 bits) = src + dst + lenght (resultado em bytes)
        checksum=${pdu:112:128}; #lenght inicial = 16 bytes
        #verifica se o checksum esta correto
        verifyChecksum=$(sum $srcPort $dstPort);
        verifyChecksum=$(sum $verifyChecksum $oneComplement);
        if [ $checksum == $verifyChecksum ];
        then
            log "Checksum válido";
        else
            log "Checksum inválido";
        fi
        if [ $syn == 1 ];
        then
            log "SYN recebido pela camada de transporte do servidor.";
            #recebeu o primeiro SYN
            #portas de origem e destino (16 bits)
            srcPortAux=$srcPort;
            srcPort=$dstPort;
            dstPort=$srcPortAux;
            #numero de sequencia e confirmacao (32 bits)
            sequence=00000000000000000000000000000000;
            acknowledgement=00000000000000000000000000000001;
            #janela (10 bits) - tamanho maximo que pode ser enviado
            window=$windowLimit;
            #flags (1 bit)
            urg=0;
            ack=1; #syn / ack
            psh=0;
            rst=0;
            syn=1; #syn / ack
            fin=0;
            #checksum (16 bits) = src + dst + lenght (resultado em bytes)
            checksum=$(sum $srcPort $dstPort);
            checksum=$(sum $checksum $oneComplement);
            payload=''; #payload inicialmente vazio
            #monta PDU
            newPdu=$srcPort$dstPort$sequence$acknowledgement$window$urg$ack$psh$rst$syn$fin$checksum;
            #escreve PDU no arquivo de log
            log "PDU camada de transporte do servidor $newPdu";
            #escreve PDU no arquivo
            echo $newPdu >| $pduTransportResponse;
            log "SYN / ACK enviado pela camada de transporte do servidor.";
        fi
        if [ $syn == 0 -a $ack == 1 ];
        then
            log "ACK recebido pela camada de transporte do servidor.";
            payload=${pdu:128:(-1)};
            converte=$(echo $payload | perl -lpe '$_=pack"B*",$_');
            echo $converte >| $macAddressFilePath;
            log $converte;
            #portas de origem e destino (16 bits)
            srcPortAux=$srcPort;
            srcPort=$dstPort;
            dstPort=$srcPortAux;
            #numero de sequencia e confirmacao (32 bits)
            sequence=00000000000000000000000000000001;
            acknowledgement=$(sum32 $sequence $window);
            #janela (10 bits) - tamanho maximo que pode ser enviado
            window=$(minus $windowLimit $window);
            #flags (1 bit)
            urg=0;
            ack=1; #ack
            psh=0;
            rst=0;
            syn=0;
            fin=0;
            #checksum (16 bits) = src + dst + lenght (resultado em bytes)
            checksum=$(sum $srcPort $dstPort);
            checksum=$(sum $checksum $oneComplement);
            log "Camada de transporte do servidor requisita camada de aplicação."
            /usr/bin/php ../application/server.php

            #permanece no loop enquanto a camada de aplicacao nao responde
            while [ ! -f $pduApplicationResponse ]
            do
                sleep 2; # or less like 0.2
            done
            pduApplication=$(cat $pduApplicationResponse);
            payload=$(echo $pduApplication | perl -lpe '$_=unpack"B*"');
            #monta PDU
            newPdu=$srcPort$dstPort$sequence$acknowledgement$window$urg$ack$psh$rst$syn$fin$checksum$payload;
            #escreve PDU no arquivo de log
            log "PDU camada de transporte do servidor $newPdu";
            #escreve PDU no arquivo
            echo $newPdu >| $pduTransportResponse;
            log "ACK enviado pela camada de transporte do servidor.";
            rm $pduApplicationResponse;
        fi
        rm $pduTransportReceived;
    else
        echo "$pduTransportReceived não encontrado";
        log "$pduTransportReceived não encontrado";
    fi
}

#Main
#first parameter defines connection type 
case $1 in
    udp)
        echo "udp";
        udp;
        ;;
    tcp)
        echo "tcp";
        tcp;
        ;;
    *)
        echo "How to use: './client udp' or './client tcp'";
        ;;
esac