#!/bin/bash

#global variables
convertDecimalTo16Bits=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1});
convertDecimalTo10Bits=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1});
sourcePort=5001;
destinyPort=5000;
oneComplement=0000000000000001;
logFilePath='../file/logTransportLayer.txt';
pduFilePath='../file/pduTransportLayerClientRequest.txt';
pduServerResponseFilePath='../file/pduTransportLayerServerResponse.txt';
fileToSend='../file/fileToSend.txt';
responseDhcp='../file/DhcpResponseIp.txt';

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

send(){
    cd ..; 
    cd physical/; 
    mono physical.exe 2;
}

hexaToBit(){
    convertion=$(echo "obase=10; ibase=16; $1" | bc);
    echo ${convertDecimalTo16Bits[$convertion]}
}

udp(){
    echo "udp function";
}

tcp(){
    log "Início da comunicação orientada a conexão";
    #portas de origem e destino (16 bits)
    srcPort=${convertDecimalTo16Bits[$sourcePort]};
    dstPort=${convertDecimalTo16Bits[$destinyPort]};
    #numero de sequencia e confirmacao (32 bits)
    sequence=00000000000000000000000000000000;
    acknowledgement=00000000000000000000000000000000;
    #janela (10 bits) - tamanho maximo que pode ser enviado
    window=0000000000;
    #flags (1 bit)
    urg=0;
    ack=0;
    psh=0;
    rst=0;
    syn=1; #inicia comunicacao
    fin=0;
    #checksum (16 bits) = src + dst + lenght (resultado em bytes)
    checksum=$(sum $srcPort $dstPort);
    checksum=$(sum $checksum $oneComplement);
    payload=''; #payload inicialmente vazio
    #monta PDU
    pdu=$srcPort$dstPort$sequence$acknowledgement$window$urg$ack$psh$rst$syn$fin$checksum;
    #escreve PDU no arquivo de log
    log "PDU camada de transporte do cliente $pdu";
    #escreve PDU no arquivo
    echo $pdu >| $pduFilePath;
    log "SYN enviado pela camada de transporte do cliente";
    #envia PDU inicial
    send;
    cd ../file; #volta para o diretorio raiz
    #permanece no loop enquanto o servidor nao responde
    while [ ! -f $pduServerResponseFilePath ]
    do
        sleep 2; # or less like 0.2
    done
    pdu=$(cat $pduServerResponseFilePath);
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
    checksum=${pdu:112:128};

    #verifica se o checksum esta correto
    verifyChecksum=$(sum $srcPort $dstPort);
    verifyChecksum=$(sum $verifyChecksum $oneoneComplement);
    if [[ $checksum == $verifyChecksum ]];
    then
        log "Checksum válido";
    else
        log "Checksum inválido";
    fi

    if [ $syn == 1 -a $ack == 1 ];
    then
        echo $(cat /sys/class/net/wlp1s0/address) >| $fileToSend;
        log "SYN / ACK recebido pela camada de transporte do cliente";
        #portas de origem e destino (16 bits)
        srcPort=${convertDecimalTo16Bits[$sourcePort]};
        dstPort=${convertDecimalTo16Bits[$destinyPort]};
        #numero de sequencia e confirmacao (32 bits)
        sequence=00000000000000000000000000000001;
        acknowledgement=00000000000000000000000000000001;
        #janela (10 bits) - tamanho maximo que pode ser enviado
        window=0000000000;
        file=$(cat $fileToSend | tr a-z A-Z);
        payload=$(echo $file | perl -lpe '$_=unpack"B*"');
        log "Mac no arquivo: $file";
        log "Conversao: $payload";
        size=$((8+$(echo $payload | wc -c)))
        length=${convertDecimalTo10Bits[$size]};
        window=$length;
        #flags (1 bit)
        urg=0;
        ack=1;
        psh=0;
        rst=0;
        syn=0; #inicia comunicacao
        fin=0;
        #checksum (16 bits) = src + dst + lenght (resultado em bytes)
        checksum=$(sum $srcPort $dstPort);
        checksum=$(sum $checksum $length);
        checksum=$(sum $checksum $oneComplement);
        
        #monta PDU
        pdu=$srcPort$dstPort$sequence$acknowledgement$window$urg$ack$psh$rst$syn$fin$checksum$payload;
        #escreve PDU no arquivo de log
        log "PDU camada de transporte do cliente $pdu";
        #escreve PDU no arquivo
        echo $pdu >| $pduFilePath;
        send;
        cd ../file; #volta para o diretorio raiz
        #permanece no loop enquanto o servidor nao responde
        while [ ! -f $pduServerResponseFilePath ]
        do
            sleep 2; # or less like 0.2
        done
        log "Camada de transporte recebe resposta final.";
        pdu=$(cat $pduServerResponseFilePath);
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
        checksum=${pdu:112:128};
        payload=${pdu:128:(-1)};
        log "Resposta DHCP: $payload";
        serverAnswer=$(echo $payload | perl -lpe '$_=pack"B*",$_');
        echo $serverAnswer >| $responseDhcp;
        #verifica se o checksum esta correto
        verifyChecksum=$(sum $srcPort $dstPort);
        verifyChecksum=$(sum $verifyChecksum $oneoneComplement);
        if [[ $checksum == $verifyChecksum ]];
        then
            log "Checksum válido";
        else
            log "Checksum inválido";
        fi
    fi

}

#Main
#first parameter defines connection type 
case $1 in
    udp)
        udp;
        ;;
    tcp)
        tcp;
        ;;
    *)
        echo "How to use: './client udp' or './client tcp'";
        ;;
esac