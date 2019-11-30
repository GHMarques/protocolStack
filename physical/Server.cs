using System;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.IO;
using System.Reflection;
using System.Threading;

namespace Pratica{
  class Server{
    const string FILE_PATH_PDU_Transport = "../file/pduTransportReceived.txt";
    const string FILE_PATH_IP_RESPONSE = "../file/ipResponse.txt";
    const string FILE_PATH_TRANSPORT_RESPONSE = "../file/pduTransportResponse.txt";
    const int PORT_NO = 5000;
    const string SERVER_IP = "192.168.0.104";
    const int BINARY_SIZE = 8;
    const int MAC_ADDRESS_SIZE = 6;
    const int PAYLOAD_SIZE = 2;
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
        string dataReceived = Encoding.ASCII.GetString(buffer, 0, bytesRead);
        byte[] bytesReceive = buffer.Take(bytesRead).ToArray();

        //mac origem: 0-5 para hexa
        string macOrigem = convertMacAddress(dataReceived.Substring(0, BINARY_SIZE * MAC_ADDRESS_SIZE));
        Log.WriteLog(Log.SERVER_CONVERT_MAC_SOURCE + " (" + macOrigem + ")");
        
        //mac destino: 6-11 para hexa
        string macDestino = convertMacAddress(dataReceived.Substring(BINARY_SIZE * MAC_ADDRESS_SIZE, BINARY_SIZE * MAC_ADDRESS_SIZE));
        Log.WriteLog(Log.SERVER_CONVERT_MAC_DESTINY + " (" + macDestino + ")");
        
        //Converte de 12-13 Bytes para int
        string strPayloadSize = dataReceived.Substring(BINARY_SIZE*MAC_ADDRESS_SIZE*2, BINARY_SIZE*PAYLOAD_SIZE);
        int payloadSize = Convert.ToInt32(strPayloadSize, 2);
        Log.WriteLog(Log.SERVER_CONVERT_PAYLOAD_SIZE + " (" + payloadSize + ")");

        //Converte 14-sizeReceive para string
        //string payload = ASCIIEncoding.ASCII.GetString((bytesReceive.Skip(14).Take(bytesRead-14).ToArray()));
        int size = BINARY_SIZE*MAC_ADDRESS_SIZE*2+BINARY_SIZE*PAYLOAD_SIZE;
        string payload = dataReceived.Substring(size, dataReceived.Length-size);
        Log.WriteLog(Log.SERVER_CONVERT_PAYLOAD + " (" + payload + ")");
        
        //Salva o arquivo
        var pduBits = string.Concat(bytesReceive.Select(b => Convert.ToString(b, 2).PadLeft(8, '0')));
        Log.WriteLog(Log.PHYSICAL_SERVER_PDU + pduBits);
        if(!File.Exists(FILE_PATH_PDU_Transport))
          File.Create(FILE_PATH_PDU_Transport).Close();
        System.IO.File.WriteAllText(FILE_PATH_PDU_Transport, payload);
        
        //Exibe PDU
        Console.WriteLine("\tMAC Origem: " + macOrigem);
        Console.WriteLine("\tBits: {0}", payload);
        Console.WriteLine("\tMAC Destino: " + macDestino);
        Console.WriteLine("\tPayload size: {0}", payloadSize);
        Console.WriteLine("\tPayload: {0}", payload);

        ExecTransportLayer();
        //Permanece no loop ate que a camada superior envie uma resposta
        while(!File.Exists(FILE_PATH_TRANSPORT_RESPONSE)){}

        string content = System.IO.File.ReadAllText(FILE_PATH_TRANSPORT_RESPONSE);
        byte[] byData = System.Text.Encoding.ASCII.GetBytes(content);
        File.Delete(FILE_PATH_TRANSPORT_RESPONSE);
        nwStream.Write(byData, 0, byData.Length);

        Console.WriteLine("\nTransport PDU: {0}", content);
        //Encerra conexao
        client.Close();
        listener.Stop();
        Console.WriteLine("\nConexão encerrada.");
        Log.WriteLog(Log.SERVER_CLOSE_CLIENT);
      }
    }
    //convert string binary to hex
    protected string convertMacAddress(string binary){
      string toReturn = "";
      int exitLoop = 0;
      while(exitLoop < binary.Length){
        toReturn += Convert.ToByte(binary.Substring(exitLoop, 8),2).ToString("X2");
        exitLoop += 8;
        if(exitLoop != binary.Length)
          toReturn += ":";
      }
      return toReturn;
    }

    public string binaryToString(string receive){ 	
      // use your encoding here
      Encoding  encode = System.Text.Encoding.UTF8;                
      string binaryString = receive.Replace(" ","");
      var bytes = new byte[binaryString.Length / 8];
      var ilen = (int)(binaryString.Length / 8);			                
      for (var aux = 0; aux < ilen; aux++){                                       
        bytes[aux] = Convert.ToByte(binaryString.Substring(aux*8, 8), 2);
      }
      string str = encode.GetString(bytes);
      return str;
    }

    public void ExecPhpServer(){
      string macAddress = string.Empty;
      Log.WriteLog("Servidor Inicia aplicação DHCP");
      System.Diagnostics.Process pProcess = new System.Diagnostics.Process();
      pProcess.StartInfo.FileName = "php";
      pProcess.StartInfo.Arguments = "../application/server.php";
      pProcess.StartInfo.UseShellExecute = false;
      pProcess.StartInfo.RedirectStandardOutput = true;
      pProcess.StartInfo.CreateNoWindow = true;
      pProcess.Start();
      string strOutput = pProcess.StandardOutput.ReadToEnd().Trim(' ');
      //Console.WriteLine(strOutput);
    }

    public void ExecTransportLayer(){
      Log.WriteLog("Sevidor Requisita a camada de transporte.");
      System.Diagnostics.Process pProcess = new System.Diagnostics.Process();
      pProcess.StartInfo.FileName = "bash";
      pProcess.StartInfo.Arguments = "../transport/server.sh tcp";
      pProcess.StartInfo.UseShellExecute = false;
      pProcess.StartInfo.RedirectStandardOutput = true;
      pProcess.StartInfo.CreateNoWindow = true;
      pProcess.Start();
      string strOutput = pProcess.StandardOutput.ReadToEnd().Trim(' ');
      Console.WriteLine(strOutput);
    }
  }

  
}
