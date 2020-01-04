require "http/server"
require "json"
require "./dup"

dup = Dup.new

SOCKETS = [] of HTTP::WebSocket
ws_handler = HTTP::WebSocketHandler.new do |socket|
  puts "Socket opened"
  SOCKETS << socket
  socket.on_message do |data|
    # new message
    msg = JSON.parse(data)
    if !dup.check(msg["#"].as_s)
      dup.track(msg["#"].as_s)
      puts "received: #{msg}"
    end
  end
  socket.on_close do
    puts "Socket closed"
  end

  spawn do
    count = 0
    loop do
      sleep 1
      count += 1
      msg = { "#": dup.track(count.to_s) }
      socket.send(msg.to_json)
    end
  end
end
server = HTTP::Server.new([ws_handler])
address = server.bind_tcp "0.0.0.0", 8080
puts "Listening on http://#{address}"
server.listen
