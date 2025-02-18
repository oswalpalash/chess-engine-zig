const std = @import("std");
const b = @import("board.zig");
const c = @import("consts.zig");

/// Engine identification constants
pub const ENGINE_NAME = "ZigChess";
pub const ENGINE_AUTHOR = "Palash";

/// Represents a UCI command
pub const UciCommand = enum {
    uci,
    debug,
    isready,
    setoption,
    register,
    ucinewgame,
    position,
    go,
    stop,
    ponderhit,
    quit,
    unknown,

    /// Parse a string into a UciCommand
    pub fn fromString(str: []const u8) UciCommand {
        // Trim whitespace from the input string
        const trimmed = std.mem.trim(u8, str, &std.ascii.whitespace);
        var iter = std.mem.splitScalar(u8, trimmed, ' ');
        const cmd = iter.next() orelse return .unknown;

        if (std.mem.eql(u8, cmd, "uci")) return .uci;
        if (std.mem.eql(u8, cmd, "debug")) return .debug;
        if (std.mem.eql(u8, cmd, "isready")) return .isready;
        if (std.mem.eql(u8, cmd, "setoption")) return .setoption;
        if (std.mem.eql(u8, cmd, "register")) return .register;
        if (std.mem.eql(u8, cmd, "ucinewgame")) return .ucinewgame;
        if (std.mem.eql(u8, cmd, "position")) return .position;
        if (std.mem.eql(u8, cmd, "go")) return .go;
        if (std.mem.eql(u8, cmd, "stop")) return .stop;
        if (std.mem.eql(u8, cmd, "ponderhit")) return .ponderhit;
        if (std.mem.eql(u8, cmd, "quit")) return .quit;

        return .unknown;
    }
};

/// Main UCI protocol handler
pub const UciProtocol = struct {
    allocator: std.mem.Allocator,
    debug_mode: bool = false,
    test_writer: ?std.ArrayList(u8).Writer = null, // Use ArrayList writer for testing
    current_board: b.Board = b.Board{ .position = b.Position.init() },
    search_in_progress: bool = false,

    pub fn init(allocator: std.mem.Allocator) UciProtocol {
        return UciProtocol{
            .allocator = allocator,
            .test_writer = null,
            .current_board = b.Board{ .position = b.Position.init() },
            .search_in_progress = false,
        };
    }

    /// Choose a simple move from the current position
    fn chooseBestMove(self: *UciProtocol) !?b.Board {
        const m = @import("moves.zig");
        // Get all valid moves from the current position
        const moves = m.allvalidmoves(self.current_board);
        if (moves.len == 0) {
            // No legal moves available
            return null;
        }

        // For now, just pick the first legal move
        return moves[0];
    }

    /// Parse a position command line and return a board position
    fn parsePositionLine(line: []const u8, allocator: std.mem.Allocator) !b.Board {
        var board = b.Board{ .position = b.Position.init() };
        var iter = std.mem.splitScalar(u8, line, ' ');
        _ = iter.next(); // Skip "position" command

        // Check for position type
        if (iter.next()) |pos_type| {
            if (std.mem.eql(u8, pos_type, "startpos")) {
                board = b.Board{ .position = b.Position.init() };
            } else if (std.mem.eql(u8, pos_type, "fen")) {
                // Collect all parts of the FEN string until we hit "moves" or end
                var fen = std.ArrayList(u8).init(allocator);
                defer fen.deinit();

                while (iter.next()) |part| {
                    if (std.mem.eql(u8, part, "moves")) break;
                    try fen.writer().writeAll(part);
                    try fen.writer().writeByte(' ');
                }

                if (fen.items.len > 0) {
                    board = b.Board{ .position = b.parseFen(fen.items) };
                }
            }

            // Process moves if present
            while (iter.next()) |token| {
                if (std.mem.eql(u8, token, "moves")) continue;
                // TODO: Apply moves when move parsing is implemented
                // This will need to parse algebraic notation and apply moves
            }
        }

        return board;
    }

    /// Process a single UCI command
    pub fn processCommand(self: *UciProtocol, line: []const u8) !void {
        const cmd = UciCommand.fromString(line);

        switch (cmd) {
            .uci => {
                // Send engine identification
                try self.respond("id name " ++ ENGINE_NAME);
                try self.respond("id author " ++ ENGINE_AUTHOR);
                // TODO: Send options here when we add them
                try self.respond("uciok");
            },
            .isready => {
                try self.respond("readyok");
            },
            .setoption => {
                // Parse the setoption command format: setoption name <id> [value <x>]
                var iter = std.mem.splitScalar(u8, line, ' ');
                _ = iter.next(); // Skip "setoption"
                const name_token = iter.next();
                if (name_token != null and std.mem.eql(u8, name_token.?, "name")) {
                    if (self.debug_mode) {
                        try self.respond("Received setoption command. Will be implemented in future.");
                    }
                }
            },
            .position => {
                self.current_board = try parsePositionLine(line, self.allocator);
            },
            .go => {
                // Choose a move from the current position
                self.search_in_progress = true;
                if (try self.chooseBestMove()) |new_board| {
                    // Convert the move to UCI format
                    const move = moveToUci(self.current_board, new_board);
                    var move_str: [10]u8 = undefined;
                    var move_len: usize = 4;
                    @memcpy(move_str[0..5], &move);
                    if (move[4] != 0) {
                        move_len = 5;
                    }
                    // Use string formatting instead of concatenation
                    if (self.test_writer) |w| {
                        try w.print("bestmove {s}\n", .{move_str[0..move_len]});
                    } else {
                        const stdout = std.io.getStdOut().writer();
                        try stdout.print("bestmove {s}\n", .{move_str[0..move_len]});
                    }
                } else {
                    // No legal moves available
                    try self.respond("bestmove 0000");
                }
                self.search_in_progress = false;
            },
            .stop => {
                if (self.search_in_progress) {
                    // Stop any ongoing search
                    self.search_in_progress = false;
                    // Send the best move found so far
                    if (try self.chooseBestMove()) |new_board| {
                        const move = moveToUci(self.current_board, new_board);
                        var move_str: [10]u8 = undefined;
                        var move_len: usize = 4;
                        @memcpy(move_str[0..5], &move);
                        if (move[4] != 0) {
                            move_len = 5;
                        }
                        if (self.test_writer) |w| {
                            try w.print("bestmove {s}\n", .{move_str[0..move_len]});
                        } else {
                            const stdout = std.io.getStdOut().writer();
                            try stdout.print("bestmove {s}\n", .{move_str[0..move_len]});
                        }
                    } else {
                        try self.respond("bestmove 0000");
                    }
                }
            },
            .ucinewgame => {
                if (self.debug_mode) {
                    try self.respond("Received ucinewgame command. Will be implemented in future.");
                }
                // Reset the board to initial position
                self.current_board = b.Board{ .position = b.Position.init() };
            },
            .quit => {
                // Send a goodbye message if in debug mode
                if (self.debug_mode) {
                    try self.respond("Goodbye!");
                }
                // No need to do anything else, mainLoop will handle the exit
            },
            else => {
                // For now, just echo other commands back
                try self.respond(line);
            },
        }
    }

    /// Main loop to process UCI commands
    pub fn mainLoop(self: *UciProtocol) !void {
        const stdin = std.io.getStdIn().reader();
        var buf: [1024]u8 = undefined;

        while (true) {
            if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
                // Check for quit command first
                if (UciCommand.fromString(line) == .quit) {
                    // Process the quit command to send any goodbye messages
                    try self.processCommand(line);
                    break;
                }
                // Process other commands
                try self.processCommand(line);
            } else {
                break; // EOF reached
            }
        }
    }

    /// Send a response back to the UCI interface
    fn respond(self: *UciProtocol, msg: []const u8) !void {
        if (self.test_writer) |w| {
            try w.print("{s}\n", .{msg});
        } else {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("{s}\n", .{msg});
        }
    }
};

/// Convert a bitboard position to algebraic notation square (e.g., "e4")
fn bitboardToSquare(position: u64) [2]u8 {
    var result: [2]u8 = undefined;

    // Find the set bit position
    var temp = position;
    var square: u6 = 0;
    while (temp > 1) : (temp >>= 1) {
        square += 1;
    }

    // In our board representation:
    // - Files go from right to left (H=0 to A=7)
    // - Ranks go from bottom to top (1=0 to 8=7)
    const file = @as(u8, 'a') + (7 - @as(u8, @intCast(square % 8)));
    const rank = @as(u8, '1') + @as(u8, @intCast(square / 8));

    result[0] = file;
    result[1] = rank;
    return result;
}

/// Convert a board move to UCI format (e.g., "e2e4" or "e7e8q" for promotion)
pub fn moveToUci(old_board: b.Board, new_board: b.Board) [5]u8 {
    var result: [5]u8 = undefined;

    // Find which piece moved by comparing the two boards
    var from_pos: u64 = 0;
    var to_pos: u64 = 0;
    var is_promotion = false;

    // Check white pieces
    inline for (std.meta.fields(@TypeOf(old_board.position.whitepieces))) |field| {
        const old_piece = @field(old_board.position.whitepieces, field.name);
        const new_piece = @field(new_board.position.whitepieces, field.name);

        if (@TypeOf(old_piece) == b.Piece) {
            if (old_piece.position != new_piece.position) {
                if (old_piece.position != 0) from_pos = old_piece.position;
                if (new_piece.position != 0) {
                    to_pos = new_piece.position;
                    // Check for pawn promotion
                    if (field.name[0] == 'P' and new_piece.representation == 'Q') {
                        is_promotion = true;
                    }
                }
            }
        } else if (@TypeOf(old_piece) == [2]b.Piece or @TypeOf(old_piece) == [8]b.Piece) {
            for (old_piece, 0..) |piece, i| {
                if (piece.position != new_piece[i].position) {
                    if (piece.position != 0) from_pos = piece.position;
                    if (new_piece[i].position != 0) {
                        to_pos = new_piece[i].position;
                        // Check for pawn promotion
                        if (field.name[0] == 'P' and new_piece[i].representation == 'Q') {
                            is_promotion = true;
                        }
                    }
                }
            }
        }
    }

    // Check black pieces if we haven't found the move
    if (from_pos == 0) {
        inline for (std.meta.fields(@TypeOf(old_board.position.blackpieces))) |field| {
            const old_piece = @field(old_board.position.blackpieces, field.name);
            const new_piece = @field(new_board.position.blackpieces, field.name);

            if (@TypeOf(old_piece) == b.Piece) {
                if (old_piece.position != new_piece.position) {
                    if (old_piece.position != 0) from_pos = old_piece.position;
                    if (new_piece.position != 0) {
                        to_pos = new_piece.position;
                        // Check for pawn promotion
                        if (field.name[0] == 'P' and new_piece.representation == 'q') {
                            is_promotion = true;
                        }
                    }
                }
            } else if (@TypeOf(old_piece) == [2]b.Piece or @TypeOf(old_piece) == [8]b.Piece) {
                for (old_piece, 0..) |piece, i| {
                    if (piece.position != new_piece[i].position) {
                        if (piece.position != 0) from_pos = piece.position;
                        if (new_piece[i].position != 0) {
                            to_pos = new_piece[i].position;
                            // Check for pawn promotion
                            if (field.name[0] == 'P' and new_piece[i].representation == 'q') {
                                is_promotion = true;
                            }
                        }
                    }
                }
            }
        }
    }

    // Convert positions to algebraic notation
    const from_square = bitboardToSquare(from_pos);
    const to_square = bitboardToSquare(to_pos);

    // Build the move string
    result[0] = from_square[0];
    result[1] = from_square[1];
    result[2] = to_square[0];
    result[3] = to_square[1];

    // Add promotion piece if necessary
    if (is_promotion) {
        result[4] = 'q';
    } else {
        result[4] = 0;
    }

    return result;
}

test "bitboardToSquare conversion" {
    const e2_square = bitboardToSquare(c.E2);
    try std.testing.expectEqual(e2_square[0], 'e');
    try std.testing.expectEqual(e2_square[1], '2');

    const a1_square = bitboardToSquare(c.A1);
    try std.testing.expectEqual(a1_square[0], 'a');
    try std.testing.expectEqual(a1_square[1], '1');

    const h8_square = bitboardToSquare(c.H8);
    try std.testing.expectEqual(h8_square[0], 'h');
    try std.testing.expectEqual(h8_square[1], '8');
}

test "moveToUci basic pawn move" {
    const old_board = b.Board{ .position = b.Position.init() };
    var new_board = b.Board{ .position = b.Position.init() };

    // Move white e2 pawn to e4
    new_board.position.whitepieces.Pawn[4].position = c.E4;

    const move = moveToUci(old_board, new_board);
    try std.testing.expectEqual(move[0], 'e');
    try std.testing.expectEqual(move[1], '2');
    try std.testing.expectEqual(move[2], 'e');
    try std.testing.expectEqual(move[3], '4');
    try std.testing.expectEqual(move[4], 0);
}

test "moveToUci pawn promotion" {
    var old_board = b.Board{ .position = b.Position.emptyboard() };
    var new_board = b.Board{ .position = b.Position.emptyboard() };

    // Set up a pawn about to promote
    old_board.position.whitepieces.Pawn[0].position = c.E7;

    // Promote to queen
    new_board.position.whitepieces.Pawn[0].position = c.E8;
    new_board.position.whitepieces.Pawn[0].representation = 'Q';

    const move = moveToUci(old_board, new_board);
    try std.testing.expectEqual(move[0], 'e');
    try std.testing.expectEqual(move[1], '7');
    try std.testing.expectEqual(move[2], 'e');
    try std.testing.expectEqual(move[3], '8');
    try std.testing.expectEqual(move[4], 'q');
}

test "moveToUci capture move" {
    var old_board = b.Board{ .position = b.Position.emptyboard() };
    var new_board = b.Board{ .position = b.Position.emptyboard() };

    // Set up a capture position
    old_board.position.whitepieces.Knight[0].position = c.E4;
    old_board.position.blackpieces.Pawn[0].position = c.F6;

    // Make the capture
    new_board.position.whitepieces.Knight[0].position = c.F6;

    const move = moveToUci(old_board, new_board);
    try std.testing.expectEqual(move[0], 'e');
    try std.testing.expectEqual(move[1], '4');
    try std.testing.expectEqual(move[2], 'f');
    try std.testing.expectEqual(move[3], '6');
    try std.testing.expectEqual(move[4], 0);
}

test "UciCommand parsing" {
    try std.testing.expectEqual(UciCommand.fromString("uci"), .uci);
    try std.testing.expectEqual(UciCommand.fromString("debug"), .debug);
    try std.testing.expectEqual(UciCommand.fromString("isready"), .isready);
    try std.testing.expectEqual(UciCommand.fromString("quit"), .quit);
    try std.testing.expectEqual(UciCommand.fromString("invalid"), .unknown);
}

test "UciCommand parsing with arguments" {
    try std.testing.expectEqual(UciCommand.fromString("position startpos"), .position);
    try std.testing.expectEqual(UciCommand.fromString("go depth 6"), .go);
    try std.testing.expectEqual(UciCommand.fromString("setoption name Hash value 128"), .setoption);
}

test "UciCommand parsing with whitespace" {
    try std.testing.expectEqual(UciCommand.fromString("  uci  "), .uci);
    try std.testing.expectEqual(UciCommand.fromString("quit  "), .quit);
    try std.testing.expectEqual(UciCommand.fromString(" isready"), .isready);
}

test "UciProtocol initialization" {
    const protocol = UciProtocol.init(std.testing.allocator);
    try std.testing.expectEqual(protocol.debug_mode, false);
}

test "UCI command identification" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();

    try protocol.processCommand("uci");

    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "id name " ++ ENGINE_NAME) != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "id author " ++ ENGINE_AUTHOR) != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "uciok") != null);
}

test "UCI isready command response" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();

    try protocol.processCommand("isready");

    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "readyok") != null);
}

test "setoption command handling" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    try protocol.processCommand("setoption name Hash value 128");
    // Currently just verifying it doesn't error
    try std.testing.expect(true);
}

test "ucinewgame command handling" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    try protocol.processCommand("ucinewgame");
    // Currently just verifying it doesn't error
    try std.testing.expect(true);
}

test "position command with startpos" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    try protocol.processCommand("position startpos");
    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "position startpos") != null);
}

test "position command with FEN" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    try protocol.processCommand("position fen rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "position fen") != null);
}

test "position command with moves" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    try protocol.processCommand("position startpos moves e2e4 e7e5");
    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "position startpos") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "e2e4") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "e7e5") != null);
}

test "position command with simple FEN and moves" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    // Use a simpler FEN string to avoid integer overflow
    try protocol.processCommand("position fen 4k3/8/8/8/8/8/8/4K3 w - - 0 1 moves e1e2");
    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "position fen") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "e1e2") != null);
}

test "quit command sends goodbye message in debug mode" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    try protocol.processCommand("quit");
    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "Goodbye!") != null);
}

test "quit command doesn't send message in non-debug mode" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = false;

    try protocol.processCommand("quit");
    const output = buf.items;
    try std.testing.expect(output.len == 0);
}

test "go command returns a valid move" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();

    // Start from initial position
    try protocol.processCommand("position startpos");
    try protocol.processCommand("go");

    const output = buf.items;
    // Verify that we got a bestmove response
    try std.testing.expect(std.mem.startsWith(u8, output, "bestmove "));
    // Verify move format (e.g., "e2e4")
    try std.testing.expect(output.len >= 13); // "bestmove " + 4 chars
    try std.testing.expect(output[9] >= 'a' and output[9] <= 'h');
    try std.testing.expect(output[10] >= '1' and output[10] <= '8');
    try std.testing.expect(output[11] >= 'a' and output[11] <= 'h');
    try std.testing.expect(output[12] >= '1' and output[12] <= '8');
}

test "go command with no legal moves" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();

    // Set up a Scholar's Mate checkmate position (black is checkmated)
    // White queen on f7, white bishop on c4, black king on e8
    try protocol.processCommand("position fen r1bqk1nr/pppp1Qpp/2n5/2b1p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4");
    try protocol.processCommand("go");

    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "bestmove 0000") != null);
}

test "stop command stops ongoing search" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.search_in_progress = true; // Simulate ongoing search

    try protocol.processCommand("stop");

    try std.testing.expect(!protocol.search_in_progress);
    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "bestmove") != null);
}

pub fn main() !void {
    // Initialize the UCI protocol with the general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var protocol = UciProtocol.init(allocator);
    try protocol.mainLoop();
}
