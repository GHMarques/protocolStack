using System;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.IO;
using System.Reflection;

namespace Pratica{
  class Client{
    const int PORT_NO = 5000;
    const int COLISION_PERCENTAGE = 10;
    const string SERVER_IP = "192.168.0.101";
    const string FILE_PATH = "teste.txt";
    const string FILE_PATH_PDU_BITS = "pduBits.txt";
    string macOrigem = "";
    string macDestino = "";
    public void send(){
      Random random = new Random(); 
      //Tentar fazer a conexão
      TcpClient tcpClient = new TcpClient();
      bool outLoop = false;
      
      while (!outLoop){
        try {
          //verifica colisao
          var colision = random.Next(0, 100);

          if(COLISION_PERCENTAGE <= colision){
            Log.WriteLog(Log.CLIENT_WITHOUT_COLISION);
            //Tenta estabelecer conexão.
            tcpClient.Connect(SERVER_IP, PORT_NO);
            Log.WriteLog(Log.CLIENT_CONNECT);
            NetworkStream nwStream = tcpClient.GetStream();
            Console.WriteLine("\n\nConexão estabelecida:");
            //Pega Mac do destino e origem.
            macOrigem = GetMacAddress("192.168.0.100");
            macDestino = GetMacAddress("192.168.0.101");
            // macOrigem = "41:7f:83:e8:5e:ff";
            // macDestino = "41:7f:33:0e:65:b2";
            // Console.WriteLine(macOrigem);
            // Console.WriteLine(macDestino);
            string content = System.IO.File.ReadAllText(FILE_PATH);

            //Converte Head para byte.
            byte[] macOrigemByte = macOrigem.Split(':').Select(x => Convert.ToByte(x, 16)).ToArray();
            Log.WriteLog(Log.CLIENT_CONVERT_MAC_SOURCE);
            byte[] macDestinoByte = macDestino.Split(':').Select(x => Convert.ToByte(x, 16)).ToArray();
            Log.WriteLog(Log.CLIENT_CONVERT_MAC_DESTINY);
            byte[] payloadSizeByte = BitConverter.GetBytes(Convert.ToInt16(content.Length));
            Log.WriteLog(Log.CLIENT_CONVERT_PAYLOAD_SIZE);

            //Converte Payload para byte.
            byte[] payloadByte = ASCIIEncoding.ASCII.GetBytes(content);
            Log.WriteLog(Log.CLIENT_CONVERT_PAYLOAD);

            //Concatena o Head.
            byte[] bytesToSend = Concat(Concat(macOrigemByte,macDestinoByte),payloadSizeByte);

            //Concate o Head com o Payload
            bytesToSend = Concat(bytesToSend,payloadByte);

            
            var pduBits = string.Concat(bytesToSend.Select(b => Convert.ToString(b, 2).PadLeft(8, '0')));

            if(!File.Exists(FILE_PATH_PDU_BITS))
              File.Create(FILE_PATH_PDU_BITS).Close();
            System.IO.File.WriteAllText(FILE_PATH_PDU_BITS, pduBits);

            //Exibe PDU
            Console.WriteLine("\tMAC Origem: {0}", macOrigem);
            Console.WriteLine("\tMAC Destino: {0}", macDestino);
            Console.WriteLine("\tTamanho do payload: {0}", content.Length);
            Console.WriteLine("\tPayload: " + content);
            Console.WriteLine("\tPDU completa em bits: {0}", pduBits);

            //Faz o envio dos bits
            nwStream.Write(bytesToSend, 0, bytesToSend.Length);

            //Encerra a conexao
            tcpClient.Close();
            Console.WriteLine("\nConexão encerrada.");
            Log.WriteLog(Log.CLIENT_CLOSE);
            outLoop = true;
            
          } else {
            Log.WriteLog(Log.CLIENT_WITH_COLISION);
            var sleepTime = random.Next(0, 100);
            Thread.Sleep(sleepTime);
            Console.WriteLine("Colisão detectada! Será enviado novamente em {0} ms.", sleepTime);
          }
        } catch(SocketException) {
          Log.WriteLog(Log.CLIENT_CONNECT_PROBLEM);
          var sleepTime = random.Next(0, 100);
          Thread.Sleep(sleepTime);
          Console.WriteLine("Erro, tempo de espera é de : " + sleepTime + "ms");
        }
      } 
    }
    //Mac address
    public string GetMacAddress(string ipAddress){
        string macAddress = string.Empty;
        System.Diagnostics.Process ppProcess = new System.Diagnostics.Process();
        ppProcess.StartInfo.FileName = "ping";
        ppProcess.StartInfo.Arguments = "-c 4 " + ipAddress;
        ppProcess.StartInfo.UseShellExecute = false;
        ppProcess.StartInfo.RedirectStandardOutput = true;
        ppProcess.StartInfo.CreateNoWindow = true;
        ppProcess.Start();
        Thread.Sleep(100);
        System.Diagnostics.Process pProcess = new System.Diagnostics.Process();
        pProcess.StartInfo.FileName = "arp";
        pProcess.StartInfo.Arguments = "-a " + ipAddress;
        pProcess.StartInfo.UseShellExecute = false;
        pProcess.StartInfo.RedirectStandardOutput = true;
        pProcess.StartInfo.CreateNoWindow = true;
        pProcess.Start();
        string strOutput = pProcess.StandardOutput.ReadToEnd();
        string[] substrings = strOutput.Split(' ');
        if (substrings[3].Length > 0){
          return substrings[3];
        } else {
          return "MAC Address não encontrado.";
        }
    }

    //Concatena bytes
    public byte[] Concat(byte[] a, byte[] b){           
      byte[] output = new byte[a.Length + b.Length];
      for (int i = 0; i < a.Length; i++)
        output[i] = a[i];
      for (int j = 0; j < b.Length; j++)
        output[a.Length+j] = b[j];
      return output;           
    }
  }
}