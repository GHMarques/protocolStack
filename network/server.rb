def ConvertBinary(number, numberOfBits)
    return number.to_i.to_s(2).rjust(numberOfBits,"0") 
end 

#Converte binario para decimal.
def ConvertBinarytoDecimal(number)
    return number.to_i(2);
end

def CallTransport()
    system("../transport/server.sh tcp")
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
#Lê os arquivos necessários.
if !File.exist?("../file/RouteTableServer.txt")
    File.new("../file/RouteTableServer.txt", "w")
end

received = File.open("../file/pduNetworkReceived.txt").read();

#Define o cabeçalho e o payload.
version = received[0..3];
ihl = received[4..7];
type = received[8..15];
totalLengh = received[16..31];
identification = received[32..47];
flag = received[48..63];
ttl = received[64..71];
protocol = received[72..79];
checksum = received[80..95];
ipSource = received[96..127];
ipDestination = received[128..159];
options = received[160..191];
payload = received[192..-1];

verifyChecksum = ConvertBinarytoDecimal(totalLengh) + 1;
if verifyChecksum == ConvertBinarytoDecimal(checksum)
    Log("Checksum válido");
else
    Log("Checksum inválido");
end

if !File.exist?("../file/pduTransportReceived.txt")
    File.new("../file/pduTransportReceived.txt", "w")
end

File.write("../file/pduTransportReceived.txt", payload);

Log("Diminui time to live.");
ttl = ConvertBinary((ConvertBinarytoDecimal(ttl) - 1), 8);

ipHeader = version+ihl+type+totalLengh+identification+flag+ttl+protocol+checksum+ipSource+ipDestination+options

Log("Servidor da camada de rede requisita a camada de transporte")
#Chama a camada de transporte.
CallTransport();

while File.open("../file/pduTransportResponse.txt").read() == nil
end

Log("Servidor da camada de rede obtém a resposta da camada de transporte.")
TransportResponse = File.open("../file/pduTransportResponse.txt").read();

if !File.exist?("../file/pduNetworkResponse.txt")
    File.new("../file/pduNetworkResponse.txt", "w")
end

File.write("../file/pduNetworkResponse.txt", ipHeader+TransportResponse);

