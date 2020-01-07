
def get(lex : JSON::Any, graph : GraphHolder) : Nil | Graph
    soul = lex["#"]
    key = lex["."]
    if !graph.graph.has_key?(soul)
        return nil
    end
    node = graph.graph[soul]
    new_node: JSON::Any = node
    if safeKey = key
        # look up key
        if !node.as_h.has_key?(safeKey)
            return nil
        end
        new_node = JSON.parse({
            "_" => node["_"].as(JSON::Any),
            "#{safeKey}" => node.as_h[safeKey].to_s
        }.to_json)
        new_node["_"].as_h[">"] = JSON.parse({
            "#{safeKey}" => node["_"][">"].as_h[safeKey]
        }.to_json)
        # puts node.as_h[safeKey].to_s
        # TODO: do stuff
    end
    ack = {"#{soul}" => new_node}
    return ack
end