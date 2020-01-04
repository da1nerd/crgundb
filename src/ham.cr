# Based on the Hypothetical Amnesia Machine thought experiment
module HAM
    extend self

    struct HAMResult
        getter historical, defer, state, converge, current, incoming, err
        def initialize(@historical = false, @defer = false, @state = false, @converge = false, @current = false, @incoming = false, @err = "")
        end
    end

    def calc(machine_state : Float64, incoming_state : Float32, current_state : Float32, incoming_value, current_value): HAMResult
        if machine_state < incoming_state
            return HAMResult.new(defer: true)
        end
        if incoming_state < current_state
            return HAMResult.new(historical: true)
        end
        if current_state < incoming_state
            return HAMResult.new(converge: true, incoming: true)
        end
        if incoming_state == current_state
            incoming_lexical_value = incoming_value.to_json
            current_lexical_value = current_value.to_json
            if incoming_lexical_value == current_lexical_value
                return HAMResult.new(state: true)
            end
            if incoming_lexical_value < current_lexical_value
                return HAMResult.new(converge: true, current: true);
            end
            if current_lexical_value < incoming_lexical_value
                return HAMResult.new(converge: true, incoming: true);
            end
        end
        return HAMResult.new(err: "Invalid CRDT Data: #{incoming_lexical_value} to #{current_lexical_value} at #{incoming_state} to #{current_state}!")
    end

    # iterate over each node in the graph, and then for each key value within each node
    # we're then grabbing the vector states off of what we have in memory, and with the incoming update as well as the data
    def mix(change : JSON::Any, graph : GraphHolder)
        machine = (Time.utc - Time::UNIX_EPOCH).total_milliseconds
        diff = Graph.new
        change.as_h.each_key do |soul|
            node = change[soul]
            node.as_h.each_key do |key|
                val = node[key]
                next if "_" == key
                state = node["_"][">"][key].as_i64.to_f32
                was = -Float32::INFINITY
                if graph.graph.has_key?(soul) && graph.graph[soul]["_"][">"].as_h.has_key?(key)
                    was = graph.graph[soul]["_"][">"][key].as_f32
                end
                known = ""
                if graph.graph.has_key?(soul)
                    known = graph.graph[soul]
                end
                ham = HAM.calc(machine, state, was, val, known)
                if ham.err
                    puts ham.err
                end
                if !ham.incoming
                    if ham.defer
                        puts "DEFER #{key} #{val}"
                        # TODO: you'd need to implement this yourself.
                    end
                    next
                end
                if !diff.has_key?(soul)
                    diff[soul] = JSON.parse("{\"_\": {\"#\": \"#{soul}\", \">\": {}}}")
                end
                # diff[soul] = diff[soul] || JSON.parse("{'_': {'#': #{soul}, '>': {}}}")
                if !graph.graph.has_key?(soul)
                    graph.graph[soul] = JSON.parse("{\"_\": {\"#\": \"#{soul}\", \">\": {}}}")
                end
                # graph.graph[soul] = graph.graph[soul] || JSON.parse("{'_': {'#': #{soul}, '>': {} }}")
                graph.graph[soul].as_h[key] = val
                diff[soul].as_h[key] = val
                graph.graph[soul]["_"][">"].as_h[key] = JSON::Any.new(state.to_f64)
                diff[soul]["_"][">"].as_h[key] = JSON::Any.new(state.to_f64)
            end
        end
        # return diff
    end
end