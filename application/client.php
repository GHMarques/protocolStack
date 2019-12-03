<?php 
    // Abre ou cria o arquivo log.txt
    // "a" representa que o arquivo é aberto para ser escrito
    $log = fopen("../file/logApplicationLayer.txt", "a");
    fwrite($log, date("Y-m-d H:i:s")." - Cliente solicita requisição ao DHCP \n");

    $output = shell_exec('cd ..; cd transport/; ./client.sh tcp ');
    
    echo $output;

    echo "\n\n\tResponse\n";
    $responseDhcp = "../file/DhcpResponseIp.txt";
    //file into array
    $fileLines = null;
    while($fileLines == null){
        $fileLines = @file($responseDhcp);
    }
    if ($fileLines[0] == "0"){
        echo "\nEndereço inválido\n";
    }else{
        $answer = explode(" ", $fileLines[0]);
        echo "Mask: " . $answer[0] . "\n";
        echo "DNS: " . $answer[1] . "\n";
        echo "Router: " . $answer[2] . "\n";
        echo "IP: " . $answer[3] . "\n";
    }
    fwrite($log, date("Y-m-d H:i:s")." - Ciente recebe a resposta da requisição \n");
    $ip=preg_replace("/\r|\n/", "", $answer[3]);

    $out = shell_exec('sudo -u root -S ifconfig rede '.$ip.' netmask '.$answer[0].' down < ~/.sudopass/sudopass.secret');
    $out = shell_exec('sudo -u root -S ifconfig rede '.$ip.' netmask '.$answer[0].' up < ~/.sudopass/sudopass.secret');
?> 