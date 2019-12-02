using System;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.IO;
using System.Collections.Generic;


namespace Pratica{
  class Client{
    const int COLISION_PERCENTAGE = 10;
    const string FILE_PATH = "../file/macAddress.txt";
    const string FILE_PATH_RESPONSE = "../file/networkResponse.txt";
    const string FILE_PATH_Network_PDU_BITS = "../file/pduNetwork.txt";   
    const int PORT_NO = 5000;
    string macOrigem = "";
    string macDestino = "";
    private string SERVER_IP;
    private string CLIENT_IP;
    public void send(){
      this.LoadCofig();
      Random random = new Random(); 
      //Tentar fazer a conexão
      TcpClient tcpClient = new TcpClient();
      bool outLoop = false;
      
      while (!outLoop){
        try {
          //verifica colisao
          var colision = random.Next(0, 100);
          if(COLISION_PERCENTAGE <= colision){
            //Nao houve colisao
            Log.WriteLog(Log.CLIENT_WITHOUT_COLISION);
            //Tenta estabelecer conexão.
            tcpClient.Connect(SERVER_IP, PORT_NO);
            Log.WriteLog(Log.CLIENT_CONNECT);
            NetworkStream nwStream = tcpClient.GetStream();
            Console.WriteLine("\n\nConexão estabelecida:");
            //Pega Mac do destino e origem.
            macOrigem = GetClientMacAddress();
            macDestino = GetServerMacAddress(SERVER_IP);
            //macDestino = GetServerMacAddress("192.168.25.1");

            if(!File.Exists(FILE_PATH_Network_PDU_BITS))
              throw new Exception("PDU da camada de rede inválida");
            
            var payloadText = System.IO.File.ReadAllText(FILE_PATH_Network_PDU_BITS).Trim();
            //Converte Head para byte.
            byte[] macOrigemByte = macOrigem.Split(':').Select(x => Convert.ToByte(x, 16)).ToArray();
            Log.WriteLog(Log.CLIENT_CONVERT_MAC_SOURCE);
            byte[] macDestinoByte = macDestino.Split(':').Select(x => Convert.ToByte(x, 16)).ToArray();
            Log.WriteLog(Log.CLIENT_CONVERT_MAC_DESTINY);
            byte[] payloadSizeByte = BitConverter.GetBytes(Convert.ToInt16(payloadText.Length));
            Log.WriteLog(Log.CLIENT_CONVERT_PAYLOAD_SIZE);
            //Converte Payload para byte.
            //byte[] payloadByte =  Encoding.ASCII.GetBytes(payloadText);
            //Concatena o Head.
            byte[] bytesToSend = Concat(macOrigemByte,macDestinoByte);
            //Concate o Head com o Payload
            String pduBits = string.Concat(bytesToSend.Select(b => Convert.ToString(b, 2).PadLeft(8, '0')));
            pduBits += Convert.ToString(payloadText.Length, 2).PadLeft(16, '0');
            pduBits += payloadText;
            //Armazena a PDU da camada fisica no log
            Log.WriteLog(Log.PHYSICAL_CLIENT_PDU + pduBits);
            //Exibe PDU
            Console.WriteLine("\tMAC Origem: {0}", macOrigem);
            Console.WriteLine("\tMAC Destino: {0}", macDestino);
            Console.WriteLine("\tTamanho do payload: {0}", payloadText.Length);
            Console.WriteLine("\tPayload: " + payloadText);
            Console.WriteLine("\tPDU completa em bits: {0}", pduBits);

            //Faz o envio dos bits
            byte[] byData = System.Text.Encoding.ASCII.GetBytes(pduBits);
            nwStream.Write(byData, 0, byData.Length);

            //Resposta do servidor
            byte[] buffer = new byte[tcpClient.ReceiveBufferSize];
            int bytesRead = nwStream.Read(buffer, 0, tcpClient.ReceiveBufferSize);
            string dataReceived = Encoding.ASCII.GetString(buffer, 0, bytesRead);
            byte[] bytesReceive = buffer.Take(bytesRead).ToArray();
            if(!File.Exists(FILE_PATH_RESPONSE))
              File.Create(FILE_PATH_RESPONSE).Close();
            Log.WriteLog("Cliente salva payload recebido");
            System.IO.File.WriteAllText(FILE_PATH_RESPONSE, dataReceived);

            // string payload = binaryToString(dataReceived);
            // if(!File.Exists(FILE_PATH_RESPONSE))
            //   File.Create(FILE_PATH_RESPONSE).Close();

            // Log.WriteLog("Cliente salva payload recebido");
            // System.IO.File.WriteAllText(FILE_PATH_RESPONSE, payload);

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
        } catch (Exception ex) {
          Console.WriteLine("Erro! " + ex.ToString());
          outLoop = true;
        }
      } 
    }
    public void PingServer(string ipAddress){
      System.Diagnostics.Process pProcess = new System.Diagnostics.Process();
      pProcess.StartInfo.FileName = "ping";
      pProcess.StartInfo.Arguments = "-c 4 " + ipAddress;
      pProcess.StartInfo.UseShellExecute = false;
      pProcess.StartInfo.RedirectStandardOutput = true;
      pProcess.StartInfo.CreateNoWindow = true;
      pProcess.Start();
      Thread.Sleep(100);
    }
    //Server Mac address
    public string GetServerMacAddress(string ipAddress){
      string macAddress = string.Empty;
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
        if(substrings[3] == "entries"){
          PingServer(ipAddress);
          return GetServerMacAddress(ipAddress);
        } else {
          return substrings[3];
        }
      } else {
        return "MAC Address do servidor não encontrado.";
      }
    }
    //Get client mac address
    public string GetClientMacAddress(){
      string macAddress = string.Empty;
      System.Diagnostics.Process pProcess = new System.Diagnostics.Process();
      pProcess.StartInfo.FileName = "/bin/bash";
      pProcess.StartInfo.Arguments = "-c \" ifconfig | grep ether \"";
      pProcess.StartInfo.UseShellExecute = false;
      pProcess.StartInfo.RedirectStandardOutput = true;
      pProcess.StartInfo.CreateNoWindow = true;
      pProcess.Start();
      string strOutput = pProcess.StandardOutput.ReadToEnd().Trim(' ');
      string[] substrings = strOutput.Split(' ');
      var macs = substrings.Where(f => f.Contains(":")).ToArray();

      if (macs.LastOrDefault().Length > 0){
        return macs.LastOrDefault();
      } else {
        return "MAC Address do cliente não encontrado.";
      }
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

    //Concatena bytes
    public byte[] Concat(byte[] a, byte[] b){           
      byte[] output = new byte[a.Length + b.Length];
      for (int i = 0; i < a.Length; i++)
        output[i] = a[i];
      for (int j = 0; j < b.Length; j++)
        output[a.Length+j] = b[j];
      return output;           
    }

    //Carrega as configurações de ip.
    private void LoadCofig()
    {
      using(var sr = new StreamReader("../config.txt"))
      {
          string line = String.Empty;
          var config = new List<string>();

          while ((line = sr.ReadLine()) != null)
          {
            config.Add(line);
          }

          this.CLIENT_IP = config.FirstOrDefault(f => f.Contains("IPCLIENT"))?.Split('=')?.Last().Trim();
          this.SERVER_IP = config.FirstOrDefault(f => f.Contains("IPSERVER"))?.Split('=')?.Last().Trim();
      };
    }
    
  }
}