using System;

namespace Pratica{
  class Program{
    static void Main(string[] args){
      switch(args[0]){
        case "1":
          var server = new Server();
          Log.WriteLog(Log.SERVER_CREATE);
          server.receive();
          break;
        case "2":
          var client = new Client();
          Log.WriteLog(Log.CLIENT_CREATE);
          client.send();
          break;
        default:
          Console.WriteLine("Opção inválida! Gentileza escolher novamente.\n");
          break;
      }
    }
  }
}
