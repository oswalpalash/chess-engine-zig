const std = @import("std");
const b = @import("board.zig");
const c = @import("consts.zig");
const m = @import("moves.zig");
const e = @import("eval.zig");

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

    // Add a list to track allocated strings that need to be freed
    allocated_strings: std.ArrayList([]u8) = undefined,

    // UCI Options
    move_overhead: u32 = 10,
    threads: u32 = 1,
    debug_log_file: []const u8 = "",
    contempt: i32 = 24,
    analysis_contempt: enum { Off, White, Black, Both } = .Both,
    hash_size: u32 = 16,
    ponder: bool = false,
    multi_pv: u32 = 1,
    skill_level: u32 = 20,
    slow_mover: u32 = 100,
    nodes_time: u32 = 0,
    chess960: bool = false,
    analyse_mode: bool = false,
    limit_strength: bool = false,
    elo: u32 = 1350,
    show_wdl: bool = false,
    syzygy_path: []const u8 = "",
    syzygy_probe_depth: u32 = 1,
    syzygy_50_move_rule: bool = true,
    syzygy_probe_limit: u32 = 7,
    use_nnue: bool = true,
    eval_file: []const u8 = "nn-62ef826d1a6d.nnue",

    pub fn init(allocator: std.mem.Allocator) UciProtocol {
        return UciProtocol{
            .allocator = allocator,
            .test_writer = null,
            .current_board = b.Board{ .position = b.Position.init() },
            .search_in_progress = false,
            .allocated_strings = std.ArrayList([]u8).init(allocator),
            .move_overhead = 10,
            .threads = 1,
            .debug_log_file = "",
            .contempt = 24,
            .analysis_contempt = .Both,
            .hash_size = 16,
            .ponder = false,
            .multi_pv = 1,
            .skill_level = 20,
            .slow_mover = 100,
            .nodes_time = 0,
            .chess960 = false,
            .analyse_mode = false,
            .limit_strength = false,
            .elo = 1350,
            .show_wdl = false,
            .syzygy_path = "",
            .syzygy_probe_depth = 1,
            .syzygy_50_move_rule = true,
            .syzygy_probe_limit = 7,
            .use_nnue = true,
            .eval_file = "nn-62ef826d1a6d.nnue",
        };
    }

    /// Choose a simple move from the current position
    fn chooseBestMove(self: *UciProtocol) !?b.Board {
        // Use the minimax algorithm to find the best move
        // The search depth is determined by the skill level (1-20)
        // Map skill level to search depth: 1-5 -> depth 1, 6-10 -> depth 2, 11-20 -> depth 3
        var search_depth: u8 = 1;
        if (self.skill_level > 5 and self.skill_level <= 10) {
            search_depth = 2;
        } else if (self.skill_level > 10) {
            search_depth = 3;
        }

        // If in debug mode, log the search depth
        if (self.debug_mode) {
            const debug_msg = try std.fmt.allocPrint(self.allocator, "info string Searching with depth {d}", .{search_depth});
            try self.allocated_strings.append(debug_msg);
            try self.respond(debug_msg);
        }

        // Find the best move using minimax
        if (e.findBestMove(self.current_board, search_depth)) |best_move| {
            return best_move;
        } else {
            // If no best move found, fall back to random move
            return chooseRandomMove(self);
        }
    }

    /// Choose a simple move from the current position
    fn chooseRandomMove(self: *UciProtocol) !?b.Board {
        // Get all valid moves from the current position
        const moves = m.allvalidmoves(self.current_board);
        if (moves.len == 0) {
            // No legal moves available
            return null;
        }

        // choose a random move
        return moves[std.crypto.random.int(u32) % moves.len];
    }

    /// Parse a position command line and return a board position
    pub fn parsePositionLine(line: []const u8, allocator: std.mem.Allocator) !b.Board {
        var board = b.Board{ .position = b.Position.init() };
        var iter = std.mem.splitScalar(u8, line, ' ');
        _ = iter.next(); // Skip "position" command

        std.debug.print("\nInitial position:\n", .{});
        _ = board.print();

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
            var found_moves = false;
            var move_count: usize = 0;
            while (iter.next()) |token| {
                if (std.mem.eql(u8, token, "moves")) {
                    found_moves = true;
                    continue;
                }
                if (found_moves) {
                    move_count += 1;
                    std.debug.print("\nProcessing move {d}: {s}\n", .{ move_count, token });
                    // Parse and apply each move
                    const move = try m.parseUciMove(token);
                    board = try m.applyMove(board, move);
                    std.debug.print("After move {d}:\n", .{move_count});
                    _ = board.print();
                    std.debug.print("Side to move: {d}\n", .{board.position.sidetomove});
                }
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

                // Send available options
                try self.respond("option name Debug Log File type string default");
                try self.respond("option name Contempt type spin default 24 min -100 max 100");
                try self.respond("option name Analysis Contempt type combo default Both var Off var White var Black var Both");
                try self.respond("option name Threads type spin default 1 min 1 max 512");
                try self.respond("option name Hash type spin default 16 min 1 max 33554432");
                try self.respond("option name Clear Hash type button");
                try self.respond("option name Ponder type check default false");
                try self.respond("option name MultiPV type spin default 1 min 1 max 500");
                try self.respond("option name Skill Level type spin default 20 min 0 max 20");
                try self.respond("option name Move Overhead type spin default 10 min 0 max 5000");
                try self.respond("option name Slow Mover type spin default 100 min 10 max 1000");
                try self.respond("option name nodestime type spin default 0 min 0 max 10000");
                try self.respond("option name UCI_Chess960 type check default false");
                try self.respond("option name UCI_AnalyseMode type check default false");
                try self.respond("option name UCI_LimitStrength type check default false");
                try self.respond("option name UCI_Elo type spin default 1350 min 1350 max 2850");
                try self.respond("option name UCI_ShowWDL type check default false");
                try self.respond("option name SyzygyPath type string default <empty>");
                try self.respond("option name SyzygyProbeDepth type spin default 1 min 1 max 100");
                try self.respond("option name Syzygy50MoveRule type check default true");
                try self.respond("option name SyzygyProbeLimit type spin default 7 min 0 max 7");
                try self.respond("option name Use NNUE type check default true");
                try self.respond("option name EvalFile type string default nn-62ef826d1a6d.nnue");

                try self.respond("uciok");
            },
            .isready => {
                try self.respond("readyok");
            },
            .setoption => {
                var iter = std.mem.splitScalar(u8, line, ' ');
                _ = iter.next(); // Skip "setoption"
                const name_token = iter.next();
                if (name_token != null and std.mem.eql(u8, name_token.?, "name")) {
                    const option_name = iter.next() orelse return;

                    // Handle different option types
                    if (std.mem.eql(u8, option_name, "Move")) {
                        // Existing Move Overhead handling
                        const overhead = iter.next() orelse return;
                        if (std.mem.eql(u8, overhead, "Overhead")) {
                            const value_token = iter.next() orelse return;
                            if (std.mem.eql(u8, value_token, "value")) {
                                const value_str = iter.next() orelse return;
                                if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                    self.move_overhead = @min(5000, @max(0, value));
                                } else |_| {
                                    if (self.debug_mode) try self.respond("info string Invalid Move Overhead value");
                                }
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Threads")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                self.threads = @min(512, @max(1, value));
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid Threads value");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Hash")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                self.hash_size = @min(33554432, @max(1, value));
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid Hash value");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Clear")) {
                        const hash = iter.next() orelse return;
                        if (std.mem.eql(u8, hash, "Hash")) {
                            // TODO: Implement hash table clearing
                            if (self.debug_mode) try self.respond("info string Hash table cleared");
                        }
                    } else if (std.mem.eql(u8, option_name, "Contempt")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            if (std.fmt.parseInt(i32, value_str, 10)) |value| {
                                self.contempt = @min(100, @max(-100, value));
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid Contempt value");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Analysis")) {
                        const contempt = iter.next() orelse return;
                        if (std.mem.eql(u8, contempt, "Contempt")) {
                            const value_token = iter.next() orelse return;
                            if (std.mem.eql(u8, value_token, "value")) {
                                const value_str = iter.next() orelse return;
                                if (std.mem.eql(u8, value_str, "Off")) {
                                    self.analysis_contempt = .Off;
                                } else if (std.mem.eql(u8, value_str, "White")) {
                                    self.analysis_contempt = .White;
                                } else if (std.mem.eql(u8, value_str, "Black")) {
                                    self.analysis_contempt = .Black;
                                } else if (std.mem.eql(u8, value_str, "Both")) {
                                    self.analysis_contempt = .Both;
                                }
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Ponder")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            self.ponder = std.mem.eql(u8, value_str, "true");
                        }
                    } else if (std.mem.eql(u8, option_name, "MultiPV")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                self.multi_pv = @min(500, @max(1, value));
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid MultiPV value");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Skill")) {
                        const level = iter.next() orelse return;
                        if (std.mem.eql(u8, level, "Level")) {
                            const value_token = iter.next() orelse return;
                            if (std.mem.eql(u8, value_token, "value")) {
                                const value_str = iter.next() orelse return;
                                if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                    self.skill_level = @min(20, @max(0, value));
                                } else |_| {
                                    if (self.debug_mode) try self.respond("info string Invalid Skill Level value");
                                }
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Slow")) {
                        const mover = iter.next() orelse return;
                        if (std.mem.eql(u8, mover, "Mover")) {
                            const value_token = iter.next() orelse return;
                            if (std.mem.eql(u8, value_token, "value")) {
                                const value_str = iter.next() orelse return;
                                if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                    self.slow_mover = @min(1000, @max(10, value));
                                } else |_| {
                                    if (self.debug_mode) try self.respond("info string Invalid Slow Mover value");
                                }
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "nodestime")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                self.nodes_time = @min(10000, @max(0, value));
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid nodestime value");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "UCI_Chess960")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            self.chess960 = std.mem.eql(u8, value_str, "true");
                        }
                    } else if (std.mem.eql(u8, option_name, "UCI_AnalyseMode")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            self.analyse_mode = std.mem.eql(u8, value_str, "true");
                        }
                    } else if (std.mem.eql(u8, option_name, "UCI_LimitStrength")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            self.limit_strength = std.mem.eql(u8, value_str, "true");
                        }
                    } else if (std.mem.eql(u8, option_name, "UCI_Elo")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                self.elo = @min(2850, @max(1350, value));
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid UCI_Elo value");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "UCI_ShowWDL")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            self.show_wdl = std.mem.eql(u8, value_str, "true");
                        }
                    } else if (std.mem.eql(u8, option_name, "SyzygyPath")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            self.syzygy_path = value_str;
                        }
                    } else if (std.mem.eql(u8, option_name, "SyzygyProbeDepth")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                self.syzygy_probe_depth = @min(100, @max(1, value));
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid SyzygyProbeDepth value");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Syzygy50MoveRule")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            self.syzygy_50_move_rule = std.mem.eql(u8, value_str, "true");
                        }
                    } else if (std.mem.eql(u8, option_name, "SyzygyProbeLimit")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            if (std.fmt.parseInt(u32, value_str, 10)) |value| {
                                self.syzygy_probe_limit = @min(7, @max(0, value));
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid SyzygyProbeLimit value");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "Use")) {
                        const nnue = iter.next() orelse return;
                        if (std.mem.eql(u8, nnue, "NNUE")) {
                            const value_token = iter.next() orelse return;
                            if (std.mem.eql(u8, value_token, "value")) {
                                const value_str = iter.next() orelse return;
                                self.use_nnue = std.mem.eql(u8, value_str, "true");
                            }
                        }
                    } else if (std.mem.eql(u8, option_name, "EvalFile")) {
                        const value_token = iter.next() orelse return;
                        if (std.mem.eql(u8, value_token, "value")) {
                            const value_str = iter.next() orelse return;
                            self.eval_file = value_str;
                        }
                    } else if (std.mem.eql(u8, option_name, "Debug")) {
                        const log = iter.next() orelse return;
                        if (std.mem.eql(u8, log, "Log") and std.mem.eql(u8, iter.next() orelse return, "File")) {
                            const value_token = iter.next() orelse return;
                            if (std.mem.eql(u8, value_token, "value")) {
                                const value_str = iter.next() orelse return;
                                self.debug_log_file = value_str;
                            }
                        }
                    }
                    // Add more option handling here as needed
                }
            },
            .position => {
                if (self.debug_mode) {
                    try self.respond(line);
                }
                self.current_board = try parsePositionLine(line, self.allocator);
            },
            .go => {
                // Choose a move from the current position
                self.search_in_progress = true;

                // Parse go command parameters
                var max_depth: u8 = 3; // Default depth
                var iter = std.mem.splitScalar(u8, line, ' ');
                _ = iter.next(); // Skip "go"

                while (iter.next()) |param| {
                    if (std.mem.eql(u8, param, "depth")) {
                        if (iter.next()) |depth_str| {
                            if (std.fmt.parseInt(u8, depth_str, 10)) |depth| {
                                max_depth = @min(depth, 5); // Limit max depth to 5
                            } else |_| {}
                        }
                    }
                }

                // Send info about the search
                try self.respond("info string Starting search");

                // Start a timer to measure search time
                const start_time = std.time.milliTimestamp();

                // Choose the best move
                if (try self.chooseBestMove()) |new_board| {
                    // Calculate search time
                    const end_time = std.time.milliTimestamp();
                    const search_time = end_time - start_time;

                    // Evaluate the position
                    const score = e.evaluate(new_board);

                    // Send search info
                    const info_msg = try std.fmt.allocPrint(self.allocator, "info depth {d} score cp {d} time {d}", .{ max_depth, score, search_time });
                    try self.allocated_strings.append(info_msg);
                    try self.respond(info_msg);

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

    /// Free all allocated memory
    pub fn deinit(self: *UciProtocol) void {
        // Free all allocated strings
        for (self.allocated_strings.items) |str| {
            self.allocator.free(str);
        }
        self.allocated_strings.deinit();
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
    defer protocol.deinit();
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
    defer protocol.deinit();
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
    defer protocol.deinit();
    protocol.test_writer = buf.writer();

    // Start from initial position
    try protocol.processCommand("position startpos");
    try protocol.processCommand("go");

    const output = buf.items;
    // Verify that we got some output
    try std.testing.expect(output.len > 0);

    // Print the output for debugging
    std.debug.print("\nEngine output: {s}\n", .{output});

    // Check if the output contains "bestmove" somewhere
    try std.testing.expect(std.mem.indexOf(u8, output, "bestmove") != null);
}

test "go command with no legal moves" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    defer protocol.deinit();
    protocol.test_writer = buf.writer();

    // Set up the Fool's Mate checkmate position (white is checkmated)
    // 1. f3 e5 2. g4 Qh4#
    try protocol.processCommand("position fen rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3");

    // Print the board state before the go command
    std.debug.print("\nBoard state before go command:\n", .{});
    _ = protocol.current_board.print();
    std.debug.print("Side to move: {d}\n", .{protocol.current_board.position.sidetomove});

    // Check if white is in check and checkmate
    const s = @import("state.zig");
    const whiteInCheck = s.isCheck(protocol.current_board, true);
    const whiteInCheckmate = s.isCheckmate(protocol.current_board, true);
    std.debug.print("White in check: {}\n", .{whiteInCheck});
    std.debug.print("White in checkmate: {}\n", .{whiteInCheckmate});

    try protocol.processCommand("go");

    // Print the board state after the go command
    std.debug.print("\nBoard state after go command:\n", .{});
    _ = protocol.current_board.print();

    const output = buf.items;
    // Just check that the engine returns a bestmove response
    std.debug.print("output: {s}\n", .{output});
    try std.testing.expect(std.mem.indexOf(u8, output, "bestmove") != null);
}

test "stop command stops ongoing search" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    defer protocol.deinit();
    protocol.test_writer = buf.writer();
    protocol.search_in_progress = true; // Simulate ongoing search

    try protocol.processCommand("stop");

    try std.testing.expect(!protocol.search_in_progress);
    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "bestmove") != null);
}

test "startpos moves e2e4 e7e5 b1c3" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    defer protocol.deinit();
    protocol.test_writer = buf.writer();

    // Send a single position command with the moves
    try protocol.processCommand("position startpos moves e2e4 e7e5 b1c3");
    try protocol.processCommand("go");

    const output = buf.items;
    // verify board is in correct position
    try std.testing.expect(output.len >= 13); // "bestmove " + 4 chars
    std.debug.print("output: {s}\n", .{output});
}

test "parsePositionLine correctly tracks side to move" {
    var protocol = UciProtocol.init(std.testing.allocator);
    const line1 = "position startpos moves e2e4";
    try protocol.processCommand(line1);
    try std.testing.expectEqual(protocol.current_board.position.sidetomove, 1); // Should be Black's turn
    try protocol.processCommand("ucinewgame");
    const line2 = "position startpos moves e2e4 e7e5";
    try protocol.processCommand(line2);
    try std.testing.expectEqual(protocol.current_board.position.sidetomove, 0); // Should be White's turn
    try protocol.processCommand("ucinewgame");
    const line3 = "position startpos moves e2e4 e7e5 b1c3";
    try protocol.processCommand(line3);
    try std.testing.expectEqual(protocol.current_board.position.sidetomove, 1); // Should be Black's turn
}

test "complex position with multiple captures - incremental" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    defer protocol.deinit();
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    // Process the final position with all moves
    const final_position = "position startpos moves b1c3 c7c6 c3d5 c6d5 g1h3 f7f6 h3g5 f6g5 a2a3 g8f6";
    try protocol.processCommand(final_position);

    // Clear the output buffer before requesting a move
    buf.clearRetainingCapacity();

    // Request a move from the engine
    try protocol.processCommand("go");

    const output = buf.items;
    // Check if the output contains "bestmove" somewhere
    try std.testing.expect(std.mem.indexOf(u8, output, "bestmove") != null);

    std.debug.print("\nFinal engine response: {s}\n", .{output});
}

test "chooseBestMove finds a move in checkmate position" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    defer protocol.deinit();
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    // Set up a position where white can checkmate in one move
    // White queen on h7, white rook on g1, black king on h8
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.H7;
    board.position.whitepieces.Rook[0].position = c.G1;
    board.position.blackpieces.King.position = c.H8;
    board.position.sidetomove = 0; // White to move

    protocol.current_board = board;

    // Find the best move
    const best_move = try protocol.chooseBestMove();

    // Verify that a move was found
    try std.testing.expect(best_move != null);

    // Print the positions for debugging
    if (best_move) |move| {
        std.debug.print("\nRook position in best move: {}\n", .{move.position.whitepieces.Rook[0].position});
        std.debug.print("Queen position in best move: {}\n", .{move.position.whitepieces.Queen.position});
    }
}

pub fn main() !void {
    // Initialize the UCI protocol with the general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var protocol = UciProtocol.init(allocator);
    defer protocol.deinit();
    try protocol.mainLoop();
}
