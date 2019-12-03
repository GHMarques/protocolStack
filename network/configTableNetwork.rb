if  ARGV.length == 1
    host = ARGV[0];

    table = File.new("../file/RouteTableClient.txt", "a");
    table.write("\n"+host);
else
    puts "How to use: ruby configTableNetwork.rb [HostIp]";
end

