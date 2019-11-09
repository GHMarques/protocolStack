#!/bin/bash

#global variables
convertDecimalTo16Bits=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1});
logFilePath='../file/logTransportLayer.txt';
pduFilePath='../file/pduTransportLayer.txt';
fileToSend='../file/fileToSend.txt';
lenght='0000000000000000'
#functions
: '
    log function
    how to use: log message
'
log(){
    echo $(date +'%Y-%m-%d %r') '-' $1 >> $logFilePath;
}

TwosComplement(){
    inverted=$(tr 01 10 <<< "$1")
    sum=$(Sum 1 $inverted)

    echo $sum
}

HexaToBit(){
    convertion=$(echo "obase=10; ibase=16; $1" | bc);
    echo ${convertDecimalTo16Bits[$convertion]}
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

send(){
    cd ..; 
    cd physical/; 
    mono physical.exe 2;
}

udp(){
    echo "udp function";
    srcPort=${convertDecimalTo16Bits[5001]};
    dstPort=${convertDecimalTo16Bits[5000]};
    log "mensagem";

    sum=$(Sum $srcPort $dstPort);
    checksum=$(TwosComplement $sum);
    payload="";
    file=$(cat $fileToSend | tr a-z A-Z);
    IFS=':' read -ra my_array <<< "$file"
    for i in "${my_array[@]}"
    do
        fileBit=$(HexaToBit $i);
        payload=$payload$fileBit;
    done
    echo $srcPort$dstPort$lenght$checksum$payload > $pduFilePath;

    send;
    
    }

tcp(){
    echo "tcp function";
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