using HTTP
using WebSockets

# Store all connected clients
clients = HTTP.WebSockets.WebSocket[]

# Function to handle incoming WebSocket connections
function handle_connection(ws::HTTP.WebSockets.WebSocket)
    push!(clients, ws)
    println("New client connected. Total clients: ", length(clients))

    try
        while true
            # Read a message from the WebSocket
            msg = HTTP.WebSockets.receive(ws)
            println("Received message: ", msg)

            # Broadcast the message to all connected clients
            for client in clients
                if client != ws && isopen(client)
                    write(client, msg)
                end
            end
        end
    catch e
        if isa(e, Base.IOError) || isa(e, HTTP.WebSockets.WebSocketError)
            println("Client disconnected: ", e)
        else
            println("Unexpected error: ", e)
        end
    finally
        filter!(x -> x != ws, clients)
        println("Client disconnected. Total clients: ", length(clients))
    end
end

# Start the WebSocket server
function start_server(port=8080)
    println("Starting WebSocket server on port $port...")
    HTTP.WebSockets.listen("0.0.0.0", port) do ws
        handle_connection(ws)
    end
end

# Run the server
start_server()