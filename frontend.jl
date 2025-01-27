using HTTP

# Start the WebSocket server
# Serve the HTML file
function serve_html(req::HTTP.Request)
    return HTTP.Response(200, read("index.html", String))
end

# Start the server
function start_server(port=8081)
    println("Starting server on port $port...")
    HTTP.serve(; port) do req::HTTP.Request
        # Serve the HTML file
        serve_html(req)
    end
end

# Run the server
start_server()