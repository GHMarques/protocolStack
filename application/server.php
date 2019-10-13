<?php
    $configServerFile = "../file/server_config.txt";
    //file into array
    $configServerFileLines = @file($configServerFile);
    if($configServerFileLines != null){
        //if file exists, get values
        $mask = trim($configServerFileLines[0]);
        $dns = trim($configServerFileLines[1]);
        $router = trim($configServerFileLines[2]);
        //get mac address
        $macAddressFilePath = "../file/macAddress.txt";
        $macAddressFile = @file($macAddressFilePath);
        if($macAddressFile != null){
            $macAddress = trim($macAddressFile[0]);
            unlink($macAddressFilePath);
            //read dhcp file
            $dhcpFile = @fopen("../file/dhcp.txt","r");
            $ipToReturn = null;
            $line = 0;
            $countLines = 0;
            $exitLoop = false;
            if($dhcpFile){
                while(!feof($dhcpFile) && !$exitLoop)  {
                    $line = fgets($dhcpFile);
                    $countLines++;
                    $info = explode(" ", $line);
                    if($info[0] == $macAddress){
                        $ipToReturn = $info[1];
                        $exitLoop = true;
                    }
                }
                fclose($dhcpFile);
            }
            if($ipToReturn == null){
                $ipToReturn = generateIP($mask, $countLines, $line);
                if($ipToReturn == null){
                    echo "No ip available.";
                } else {
                    $fileAppend = fopen("../file/dhcp.txt", "a");
                    if($countLines != 0)
                        fwrite($fileAppend, "\n");
                    fwrite($fileAppend, $macAddress . " " . $ipToReturn); 
                    fclose($fileAppend);
                }
            }
            $fileResponse = fopen("../file/ipResponse.txt", "w");
            fwrite($fileResponse, $mask);
            fwrite($fileResponse, "\n");
            fwrite($fileResponse, $dns);
            fwrite($fileResponse, "\n");
            fwrite($fileResponse, $router);
            fwrite($fileResponse, "\n");
            fwrite($fileResponse, trim($ipToReturn));
            fclose($fileResponse);
        } else {
            //file does not exist
            echo "Mac Address file could not be opened.\n";
        }
    }
    else {
        //file does not exist
        echo "Config server file could not be opened.\n";
    }

    function netmask2cidr($netmaskInput){
        $lenght = 0;
        $netmask = explode(".", $netmaskInput);

        foreach($netmask as $octect)
            $lenght += strlen(str_replace("0", "", decbin($octect)));

        return $lenght;
    }

    function generateIp($mask, $countLines, $line){
        $prefix = netmask2cidr($mask);
        if($line == 0){
            if($prefix >= 16){
                //class B/C
                return "192.168.0.1";
            } else {
                //class A
                return "192.0.0.1";
            }
        } else {
            $maxHost = 2**(32 - $prefix) - 2;
            if($countLines < $maxHost){
                if($prefix < 16){
                    //class A
                    $explodeLastLine = explode(" ", $line);
                    $ip = explode(".", $explodeLastLine[1]);
                    if($ip[3] == 254){
                        $ip[3] = 0;
                        if($ip[2] == 255){
                            $ip[2] = 0;
                            $ip[1] = $ip[1] + 1;
                            return "192.".$ip[1].".".$ip[2].".".$ip[3];
                        } else {
                            $ip[2] = $ip[2] + 1;
                            return "192.".$ip[1].".".$ip[2].".".$ip[3];
                        }
                    } else {
                        $ip[3] = $ip[3] + 1;
                        return "192.".$ip[1].".".$ip[2].".".$ip[3];
                    }
                } else if($prefix >= 16 && $prefix < 24){
                    //class B
                    $explodeLastLine = explode(" ", $line);
                    $ip = explode(".", $explodeLastLine[1]);
                    if($ip[3] == 254){
                        $ip[3] = 0;
                        $ip[2] = $ip[2] + 1;
                        return "192.168".$ip[2].".".$ip[3];
                    } else {
                        $ip[3] = $ip[3] + 1;
                        return "192.168".$ip[2].".".$ip[3];
                    }
                } else {
                    //class C
                    $ip = $countLines+1;
                    return "192.168.0.".$ip;
                }
            } else {
                return null;
            }
        }
        

        

    }


?>