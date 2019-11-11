#!/bin/bash

#global variables
convertDecimalTo16Bits=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1});
logFilePath='../file/logTransportLayer.txt';
pduFilePath='../file/pduTransportLayer.txt';
fileToSend='../file/fileToSend.txt';
responseFile='../file/responseFile.txt';
seq=1;
flag='0000001010'

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

BitToDecimal(){
    convertion=$(echo "obase=10; ibase=2; $1" | bc);
    echo $convertion
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
    srcPort=${convertDecimalTo16Bits[5000]};
    dstPort=${convertDecimalTo16Bits[5000]};
    log "mensagem";

    sum=$(Sum $lenght $(Sum $srcPort $dstPort))
    checksum=$(TwosComplement $sum);
    payload="";
    file=$(cat $fileToSend | tr a-z A-Z);
    IFS=':' read -ra my_array <<< "$file"
    for i in "${my_array[@]}"
    do
        fileBit=$(HexaToBit $i);
        payload=$payload$fileBit;
    done
    size=$((8+$(echo $payload | wc -c)))
    lenght=${convertDecimalTo16Bits[$size]};

    echo $srcPort$dstPort$lenght$checksum$payload > $pduFilePath;

    #send;
    
}

tcp(){
    echo "tcp function";
    srcPort=${convertDecimalTo16Bits[5001]};
    dstPort=${convertDecimalTo16Bits[5000]};
    log "mensagem";

    sum=$(Sum $srcPort $dstPort);
    checksum=$(TwosComplement $sum);
    echo $checksum
    responseFile=$(cat $responseFile | tr a-z A-Z);
    payload="";
    # Verifica se existe um arquivo de resposta.
    if [ ${#responseFile} -ne 0 ]
    then
        echo "entrou";
        seqResponse=$(BitToDecimal ${responseFile:32:32}); 
        seq=$(($seqResponse+${#responseFile}));
        file=$(cat $fileToSend | tr a-z A-Z);
        IFS=':' read -ra my_array <<< "$file"
        for i in "${my_array[@]}"
        do
            fileBit=$(HexaToBit $i);
            payload=$payload$fileBit;
        done
    fi
    
    payloadSize=${#payload};
    sizeAtual=$((64+$payloadSize));
    confirmationSeq=$(($seq+$sizeAtual));
    confirmationSeqBits=$(printf '%032d' $( echo "obase=2; $confirmationSeq"| bc));
    seqBits=$(printf '%032d' $( echo "obase=2; $seq"| bc));
    echo $srcPort$dstPort$seqBits$confirmationSeqBits$flag$checksum$payload > $pduFilePath;

    send;
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