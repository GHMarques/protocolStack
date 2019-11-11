#!/bin/bash

#global variables
logFilePath='../file/logTransportLayer.txt';
macAddressFilePath='../file/macAddress.txt';
pduTransportReceived='../file/pduTransportReceived.txt';
#functions
: '
    log function
    how to use: log message
'
log(){
    echo $(date +'%Y-%m-%d %r') '-' $1 >> $logFilePath;
}

BitToDecimal(){
    convertion=$(echo "obase=10; ibase=2; $1" | bc);
    echo $convertion
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

Sum(){
    sum=$(echo "ibase=2;obase=2; $1+$2" | bc);
    size=${#sum};
    while [ $size -lt 16 ]
    do
        sum=0$sum
        size=${#sum};
    done
    
    echo $sum;
}

callServer(){
    /usr/bin/php ../application/server.php
}

udp(){
    echo "udp function";
    #Converte a pdu para suas respectivas variaveis.
    pdu=$(cat $pduTransportReceived);
    OrigemPort=${pdu:0:16};
    DestinationPort=${pdu:16:16};
    lenght=${pdu:32:16};
    checkSum=${pdu:48:16};
    payload=${pdu:64};
    
    #Verifica checkSum
    sum=$(Sum $lenght $(Sum $OrigemPort $DestinationPort))
    check=$(Sum $sum $checkSum);
    
    if [ ${check:1:16} -ne 0 ]
    then
        exit 0;
    fi
    
    echo $(payloadToMacAddress $payload) > $macAddressFilePath;
    callServer;
    
    }

tcp(){
    echo "tcp function";
    #Converte a pdu para suas respectivas variaveis.
    pdu=$(cat $pduTransportReceived);
    OrigemPort=${pdu:0:16};
    DestinationPort=${pdu:16:16};
    seqReceived=${pdu:32:32};
    confirmation=${pdu:64:32};
    flag=${pdu:96:10};
    checkSum=${pdu:106:16};
    payload=${pdu:112};
    
    #Verifica checkSum
    sum=$(Sum $OrigemPort $DestinationPort);
    check=$(Sum $sum $checkSum);

    if [ ${check:1:16} -ne 0 ]
    then
        exit 0;
    fi

    seqReceivedDecimal=$(echo "obase=10;ibase=2; $seqReceived" | bc)
    seq=$(($seqReceivedDecimal+${#pdu}))
    confirmationDecimal=$(echo "obase=10;ibase=2; $confirmation" | bc)

    if [ $confirmationDecimal -eq $seqReceivedDecimal ]
    then
        
    fi
    
    echo $(payloadToMacAddress $payload) > $macAddressFilePath;
    callServer;
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