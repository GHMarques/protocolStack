#Converte Decimal para binario;
def ConvertBinary(number, numberOfBits)
    return number.to_i.to_s(2).rjust(numberOfBits,"0") 
end 

def CallPhyscal()
    system("mono ../physical/physical.exe 2")
end

def ConvertBinarytoDecimal(number)
    return number.to_i(2);
end

def Log(message)
    data = Time.now.strftime("%Y-%m-%d %H:%M:%S");
    if !File.exist?("../file/logNetworkLayer.txt")
        File.new("../file/logNetworkLayer.txt", "w");
    end

    file = File.open("../file/logNetworkLayer.txt", "a");
    file.puts data + " - " + message;
    file.close();
end 

#----Main----
#Define o cabeçalho.
ipSource = "192.168.0.1";
ipDestination = "192.168.0.2";
version = "4";
ihl = "0101";
type = "00000000";
totalLengh = "0000000000000000";
identification = "0000000000000000";
flag = "0000000000000000";
ttl = "11111111";
protocol = "00000111";
options = "00000000000000000000000000000000";

checksum = "0000000000000000";
#Lê os arquivos necessários.
if !File.exist?("../file/RouteTableClient.txt")
    File.new("../file/RouteTableClient.txt", "w")
end

table = File.open("../file/RouteTableClient.txt").readlines.map(&:chomp);
pduTransportLayer = File.open("../file/pduTransportLayerClientRequest.txt").read();

#Calcula tamanhao total.
totalLengh = pduTransportLayer.size.to_i + identification.size.to_i + ihl.to_i(2);
totalLenghBinary = ConvertBinary(totalLengh, 16);

#Converte ips para 32 bits.
ipSourceBinary = ipSource.split(".").map { |f| ConvertBinary(f,8)}.join("");
ipDestinationBinary = ipDestination.split(".").map { |f| ConvertBinary(f,8)}.join("");

#Converte versão para binario.
versionBinary = ConvertBinary(version,4);

#Calcula checksum.
checksum = totalLengh + 1;
checksumBinary = ConvertBinary(checksum,16);

ipHeader = versionBinary.to_s+ihl+type+totalLenghBinary+identification+flag+ttl+protocol+checksumBinary+ipSourceBinary+ipDestinationBinary+options;

Log("Verifica se o destino está contido na tabela de roteamento.");
if  table.any?{ |f| f == ipDestination }
    Log("Ip de destino encontrado na tabela de roteamento.");
    if !File.exist?("../file/pduNetwork.txt")
        File.new("../file/pduNetwork.txt", "w")
    end
    File.write('../file/pduNetwork.txt', ipHeader+pduTransportLayer);
    puts "\nNetwork PDU: " + ipHeader + pduTransportLayer;

    Log("Camada de rede requisita a camada fisica");
    #Faz requisição
    CallPhyscal();

    #Entra em loop ate o arquivo de resposta ser escrito.
    while !File.open("../file/networkResponse.txt").read() == nil
    end
    Log("Camada de rede recebe resposta");
    response = File.open("../file/networkResponse.txt").read();
    puts "\nNetwork PDU: " + response;
    
    totalLengh = response[16..31];
    checksum = response[80..95];
    verifyChecksum = ConvertBinarytoDecimal(totalLengh) + 1;
    if verifyChecksum == ConvertBinarytoDecimal(checksum)
        Log("Checksum válido");
    else
        Log("Checksum inválido");
    end

    if !File.exist?("../file/pduTransportLayerServerResponse.txt")
        File.new("../file/pduTransportLayerServerResponse.txt", "w")
    end

    File.write('../file/pduTransportLayerServerResponse.txt', response[192..-1]);
    
else
    Log("Ip de destino não foi encontrado na tabela de roteamento");
end