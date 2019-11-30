<?php 
    // Abre ou cria o arquivo log.txt
    // "a" representa que o arquivo é aberto para ser escrito
    $log = fopen("../file/log.txt", "a");
    fwrite($log, date("Y-m-d H:i:s")." - Cliente solicita requisição ao DHCP \n");

    $output = shell_exec('cd ..; cd transport/; client.sh tcp ');
    
    echo $output;

    echo "\n\n\tResponse\n";
    $responseDhcp = "../file/DhcpResponseIp.txt";
    //file into array
    $fileLines = null;
    while($fileLines == null){
        $fileLines = @file($responseDhcp);
    }
    
    echo "Mask: " . $fileLines[0];
    echo "DNS: " . $fileLines[1];
    echo "Router: " . $fileLines[2];
    echo "IP: " . $fileLines[3] . "\n";

    fwrite($log, date("Y-m-d H:i:s")." - Ciente recebe a resposta da requisição \n");

    $out = shell_exec('sudo -u root -S ifconfig rede '.$fileLines[3].' netmask 255.255.255.0 down < ~/.sudopass/sudopass.secret');
    $out = shell_exec('sudo -u root -S ifconfig rede '.$fileLines[3].' netmask 255.255.255.0 up < ~/.sudopass/sudopass.secret');
?> 