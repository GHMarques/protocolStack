using System;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.IO;
using System.Reflection;

namespace Pratica{
  class Server{
    const string FILE_PATH_PDU_BITS = "pduBitsReceive.txt";
    const int PORT_NO = 5000;
    const string SERVER_IP = "192.168.0.101";
    public void receive(){
      IPHostEntry ipHostInfo = Dns.GetHostEntry(Dns.GetHostName());  
      IPAddress ipAddress = IPAddress.Parse(SERVER_IP);
      Log.WriteLog(Log.SERVER_START);
      Console.WriteLine("Servidor ativo:");
      Console.WriteLine("\tIP: {0}\n\tPorta: {1}", ipAddress, PORT_NO);
      while(true){
        //Escuta a porta
        TcpListener listener = new TcpListener(ipAddress, PORT_NO);
        listener.Start();
        Log.WriteLog("Servidor de IP: " + ipAddress + " ouvindo a porta: " + PORT_NO);
        //Aceita conexão do cliente
        TcpClient client = listener.AcceptTcpClient();
        Log.WriteLog("Servidor aceita conexão com cliente: " + ((IPEndPoint)client.Client.RemoteEndPoint).Address.ToString());
        Console.WriteLine("Conexão aceita: \n\tIP: {0}", ((IPEndPoint)client.Client.RemoteEndPoint).Address.ToString());
        //Recebe os dados do cliente via stream
        NetworkStream nwStream = client.GetStream();
        byte[] buffer = new byte[client.ReceiveBufferSize];
        //Lê o que foi recebido
        int bytesRead = nwStream.Read(buffer, 0, client.ReceiveBufferSize);
        byte[] bytesReceive = buffer.Take(bytesRead).ToArray();
        //mac origem: 0-5 para hexa
        string macOrigem = BitConverter.ToString(bytesReceive.Take(6).ToArray()).Replace("-",":");
        Log.WriteLog(Log.SERVER_CONVERT_MAC_SOURCE + " (" + macOrigem + ")");
        //mac destino: 6-11 para hexa
        string macDestino = BitConverter.ToString(bytesReceive.Skip(6).Take(6).ToArray()).Replace("-",":");
        Log.WriteLog(Log.SERVER_CONVERT_MAC_DESTINY + " (" + macDestino + ")");
        //Converte de 12-13 Bytes para int
        int payloadSize = BitConverter.ToInt16(bytesReceive.Skip(12).Take(2).ToArray());
        Log.WriteLog(Log.SERVER_CONVERT_PAYLOAD_SIZE + " (" + payloadSize + ")");
        //Converte 14-sizeReceive para string
        string payload = ASCIIEncoding.ASCII.GetString((bytesReceive.Skip(14).Take(bytesRead-14).ToArray()));
        Log.WriteLog(Log.SERVER_CONVERT_PAYLOAD + " (" + payload + ")");
        //Salva o arquivo
        var pduBits = string.Concat(bytesReceive.Select(b => Convert.ToString(b, 2).PadLeft(8, '0')));
        if(!File.Exists(FILE_PATH_PDU_BITS))
          File.Create(FILE_PATH_PDU_BITS).Close();
        System.IO.File.WriteAllText(FILE_PATH_PDU_BITS, pduBits);
        //Exibe PDU
        Console.WriteLine("\tMAC Origem: " + macOrigem);
        Console.WriteLine("\tMAC Destino: " + macDestino);
        Console.WriteLine("\tTamanho do Payload: {0}", payloadSize);
        Console.WriteLine("\tPayload: {0}", payload);
        //Encerra conexao
        client.Close();
        listener.Stop();
        Log.WriteLog(Log.SERVER_CLOSE_CLIENT);
      }
    }
  }
}
