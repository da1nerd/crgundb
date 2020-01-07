require "http/server"
require "json"
require "./dup"
require "./ham"
require "./get"

alias Graph = Hash(String, JSON::Any)

class GraphHolder
  getter graph
  def initialize()
    @graph = Graph.new
  end
end

class Gun

  def initialize
    @peers = [] of HTTP::WebSocket
    @graph = GraphHolder.new
    @dup = Dup.new
  end

  def emit(data : String)
    @peers.each do |p|
      begin
        p.send(data)
      rescue
        # puts e.message
      end
    end
  end

  def run
    # This is the json format we need to support.
    # {
    #   _: {
    #     "#": "UID",
    #     ">": { ...keys: int}
    #   }
    #   ...keys
    # }

    # configure socket handler
    ws_handler = HTTP::WebSocketHandler.new do |peer|
      @peers << peer
      peer.on_message do |data|
        msg = JSON.parse(data)
        # make sure we haven't seen this message before
        if !@dup.check(msg["#"].as_s)
          @dup.track(msg["#"].as_s)
          # watch for write requests
          if msg.as_h.has_key?("put")
            HAM.mix(msg["put"], @graph)
          end
          # watch for get requests
          if msg.as_h.has_key?("get")
            ack = get(msg["get"], @graph)
            if safe_ack = ack
              emit({
                "#": @dup.track(Dup.random()),
                "@": msg["#"],
                "put": safe_ack
              }.to_json)
            end
          end
          # pass data on to the rest of the network
          emit(data)
        end
      end
      peer.on_close do
        # TODO: remove peer from array
      end
    end

    # start the server
    server = HTTP::Server.new([ws_handler])
    address = server.bind_tcp "0.0.0.0", 8080
    puts "Listening on http://#{address}"
    server.listen
  end
end

Gun.new.run