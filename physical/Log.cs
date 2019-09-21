using System;
using System.IO;
using System.Reflection;

namespace Pratica{
  class Log{
    private static String FILE_PATH = "log.txt";
    //Mensagens
    //Server
    public static String SERVER_CREATE = "Servidor criado.";
    public static String SERVER_START = "Servidor iniciado.";
    public static String SERVER_READ_BUFFER = "Servidor lê o buffer via stream.";
    public static String SERVER_CONVERT_MAC_SOURCE = "Servidor converte MAC de origem.";
    public static String SERVER_CONVERT_MAC_DESTINY = "Servidor converte MAC de destino.";
    public static String SERVER_CONVERT_PAYLOAD_SIZE = "Servidor converte tamanho do payload.";
    public static String SERVER_CONVERT_PAYLOAD = "Servidor converte payload.";
    public static String SERVER_CLOSE_CLIENT = "Servidor encerra conexao com o cliente.";
    //Client
    public static String CLIENT_CREATE = "Cliente criado.";
    public static String CLIENT_WITH_COLISION = "Cliente detecta colisão.";
    public static String CLIENT_WITHOUT_COLISION = "Cliente não detecta colisão.";
    public static String CLIENT_CONVERT_MAC_SOURCE = "Cliente converte MAC de origem.";
    public static String CLIENT_CONVERT_MAC_DESTINY = "Cliente converte MAC de destino.";
    public static String CLIENT_CONVERT_PAYLOAD_SIZE = "Cliente converte tamanho do payload.";
    public static String CLIENT_CONVERT_PAYLOAD = "Cliente converte payload.";
    public static String CLIENT_CONNECT = "Cliente se conecta no servidor.";
    public static String CLIENT_SEND_BITS = "Cliente envia a PDU em bits.";
    public static String CLIENT_CLOSE = "Cliente encerra a conexão.";
    public static String CLIENT_CONNECT_PROBLEM = "Cliente não conseguiu se conectar.";
    public static void WriteLog(String message){
      try{
        if(!File.Exists(FILE_PATH))
          File.Create(FILE_PATH).Close();

          File.AppendAllText(FILE_PATH,"\n" + DateTime.Now.ToShortDateString() + " " + DateTime.Now.ToLongTimeString() + " - " + message);
      } catch(Exception){
        Console.WriteLine("Erro! Não foi possível registrar a ação no log.");
      }
    }
  }
}