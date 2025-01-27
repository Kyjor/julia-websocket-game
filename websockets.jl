using HTTP
using WebSockets

# Constants for the board
const BOARD_SIZE = 8
const EMPTY = 0
const RED = 1
const BLACK = 2
const RED_KING = 3
const BLACK_KING = 4

# Initialize the board
function initialize_board()
    board = zeros(Int, BOARD_SIZE, BOARD_SIZE)
    for row in 1:3
        for col in 1:BOARD_SIZE
            if (row + col) % 2 == 0
                board[row, col] = RED
            end
        end
    end
    for row in 6:8
        for col in 1:BOARD_SIZE
            if (row + col) % 2 == 0
                board[row, col] = BLACK
            end
        end
    end
    return board
end

# Check if a move is valid
function is_valid_move(board, from_row, from_col, to_row, to_col, player)
    # Basic checks
    if to_row < 1 || to_row > BOARD_SIZE || to_col < 1 || to_col > BOARD_SIZE
        return false
    end
    if board[to_row, to_col] != EMPTY
        return false
    end
    # Add more rules for checkers (e.g., capturing, kinging)
    return true
end

# Update the board after a move
function make_move(board, from_row, from_col, to_row, to_col, player)
    if is_valid_move(board, from_row, from_col, to_row, to_col, player)
        piece = board[from_row, from_col]
        board[from_row, from_col] = EMPTY
        board[to_row, to_col] = piece
        # Check for kinging
        if player == RED && to_row == BOARD_SIZE
            board[to_row, to_col] = RED_KING
        elseif player == BLACK && to_row == 1
            board[to_row, to_col] = BLACK_KING
        end
        return true
    end
    return false
end

# Store all connected clients and game state
clients = HTTP.WebSockets.WebSocket[]
board = initialize_board()
global current_player = RED

# Function to handle incoming WebSocket connections
function handle_connection(ws::HTTP.WebSockets.WebSocket)
    push!(clients, ws)
    println("New client connected. Total clients: ", length(clients))

    # Send the initial board state to the client
    HTTP.WebSockets.send(ws, "board $(join(board, " "))")

    try
        while true
            # Receive a message from the client
            msg = HTTP.WebSockets.receive(ws)
            println("Received message: ", msg)

            # Parse the message (e.g., "move 1 2 3 4")
            if startswith(msg, "move")
                parts = split(msg)
                from_row = parse(Int, parts[2])
                from_col = parse(Int, parts[3])
                to_row = parse(Int, parts[4])
                to_col = parse(Int, parts[5])

                # Validate and make the move
                if make_move(board, from_row, from_col, to_row, to_col, current_player) #TODO: current_player)
                    # Switch players
                    global current_player = current_player == RED ? BLACK : RED
                    # Broadcast the updated board to all clients
                    for client in clients
                        if !HTTP.WebSockets.isclosed(client)
                            HTTP.WebSockets.send(client, "board $(join(board, " "))")
                        end
                    end
                else
                    HTTP.WebSockets.send(ws, "error Invalid move")
                    println("Invalid move")
                end
            end
        end
    catch e
        if isa(e, Base.IOError) || isa(e, HTTP.WebSockets.WebSocketError)
            println("Client disconnected: ", e)
            Base.show_backtrace(stdout, catch_backtrace())
        else
            println("Unexpected error: ", e)
            Base.show_backtrace(stdout, catch_backtrace())
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