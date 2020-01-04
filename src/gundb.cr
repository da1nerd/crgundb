require "http/server"
require "json"
require "./dup"

dup = Dup.new

peers = [] of HTTP::WebSocket
ws_handler = HTTP::WebSocketHandler.new do |peer|
  peers << peer
  peer.on_message do |data|
    msg = JSON.parse(data)
    if !dup.check(msg["#"].as_s)
      dup.track(msg["#"].as_s)
      puts "received: #{msg}"
      peers.each do |p|
        begin
          p.send(data)
        rescue
          # puts e.message
        end
      end
    end
  end
  peer.on_close do
    # TODO: remove peer from array
  end
end
server = HTTP::Server.new([ws_handler])
address = server.bind_tcp "0.0.0.0", 8080
puts "Listening on http://#{address}"
server.listen
