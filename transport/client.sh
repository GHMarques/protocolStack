#!/bin/bash

#global variables
convertDecimalTo16Bits=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1});
logFilePath='../file/logTransportLayer.txt';

#functions
: '
    log function
    how to use: log message
'
log(){
    echo $(date +'%Y-%m-%d %r') '-' $1 >> $logFilePath;
}

udp(){
    echo "udp function";
    srcPort=${convertDecimalTo16Bits[5001]};
    dstPort=${convertDecimalTo16Bits[5000]};
    segmentSize=${convertDecimalTo16Bits[10]};
    checksum=${convertDecimalTo16Bits[10]};
    log "mensagem";
    echo $srcPort$'\n'$dstPort;
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