require "http/server"
require "json"
require "./dup"
require "./ham"

alias Graph = Hash(String, JSON::Any)

dup = Dup.new
peers = [] of HTTP::WebSocket
# graph = Graph.new

class GraphHolder
  getter graph
  def initialize()
    @graph = Graph.new
  end
end

graph = GraphHolder.new
# This is the json format we need to support.
# {
#   _: {
#     "#": "UID",
#     ">": { ...keys: int}
#   }
#   ...keys
# }

ws_handler = HTTP::WebSocketHandler.new do |peer|
  peers << peer
  peer.on_message do |data|
    msg = JSON.parse(data)
    if !dup.check(msg["#"].as_s)
      dup.track(msg["#"].as_s)
      if(msg["put"])
        HAM.mix(msg["put"], graph)
        puts "----------"
        puts graph.graph
      end
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
