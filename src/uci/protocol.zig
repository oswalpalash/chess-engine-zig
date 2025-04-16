const std = @import("std");
const b = @import("../board.zig");
const c = @import("../consts.zig");
const m = @import("../moves.zig");
const e = @import("../eval.zig");
const helpers = @import("helpers.zig");
const UciCommand = @import("command.zig").UciCommand;

pub const ENGINE_NAME = "ZigChess";
pub const ENGINE_AUTHOR = "Palash";

pub const UciProtocol = struct {
    allocator: std.mem.Allocator,
    debug_mode: bool = false,
    test_writer: ?std.ArrayList(u8).Writer = null,
    current_board: b.Board = b.Board{ .position = b.Position.init() },
    search_in_progress: bool = false,
    allocated_strings: std.ArrayList([]u8) = undefined,
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

    fn chooseBestMove(self: *UciProtocol) !?b.Board {
        var search_depth: u8 = 1;
        if (self.skill_level > 5 and self.skill_level <= 10) {
            search_depth = 2;
        } else if (self.skill_level > 10) {
            search_depth = 3;
        }
        if (self.debug_mode) {
            const debug_msg = try std.fmt.allocPrint(self.allocator, "info string Searching with depth {d}", .{search_depth});
            try self.allocated_strings.append(debug_msg);
            try self.respond(debug_msg);
        }
        if (e.findBestMove(self.current_board, search_depth)) |best_move| {
            return best_move;
        } else {
            return self.chooseRandomMove();
        }
    }

    fn chooseRandomMove(self: *UciProtocol) !?b.Board {
        const moves = m.allvalidmoves(self.current_board);
        if (moves.len == 0) {
            return null;
        }
        return moves[std.crypto.random.int(u32) % moves.len];
    }

    pub fn parsePositionLine(line: []const u8, allocator: std.mem.Allocator) !b.Board {
        var board = b.Board{ .position = b.Position.init() };
        var iter = std.mem.splitScalar(u8, line, ' ');
        _ = iter.next();
        std.debug.print("\nInitial position:\n", .{});
        _ = board.print();
        if (iter.next()) |pos_type| {
            if (std.mem.eql(u8, pos_type, "startpos")) {
                board = b.Board{ .position = b.Position.init() };
            } else if (std.mem.eql(u8, pos_type, "fen")) {
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

    pub fn processCommand(self: *UciProtocol, line: []const u8) !void {
        const cmd = UciCommand.fromString(line);
        switch (cmd) {
            .uci => {
                try self.respond("id name " ++ ENGINE_NAME);
                try self.respond("id author " ++ ENGINE_AUTHOR);
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
                        } else {
                            if (self.debug_mode) {
                                const msg = std.fmt.allocPrint(self.allocator, "info string Unknown or unsupported option: {s}", .{option_name}) catch "info string Unknown or unsupported option";
                                try self.respond(msg);
                            }
                        }
                    } else {
                        if (self.debug_mode) try self.respond("info string Malformed setoption command: missing 'name'");
                    }
                } else {
                    if (self.debug_mode) try self.respond("info string Malformed setoption command: missing 'name'");
                }
            },
            .position => {
                if (self.debug_mode) {
                    try self.respond(line);
                }
                self.current_board = try UciProtocol.parsePositionLine(line, self.allocator);
            },
            .go => {
                self.search_in_progress = true;
                var max_depth: u8 = 3;
                var iter = std.mem.splitScalar(u8, line, ' ');
                _ = iter.next();
                while (iter.next()) |param| {
                    if (std.mem.eql(u8, param, "depth")) {
                        if (iter.next()) |depth_str| {
                            if (std.fmt.parseInt(u8, depth_str, 10)) |depth| {
                                max_depth = @min(depth, 5);
                            } else |_| {}
                        }
                    }
                }
                try self.respond("info string Starting search");
                const start_time = std.time.milliTimestamp();
                if (try self.chooseBestMove()) |new_board| {
                    const end_time = std.time.milliTimestamp();
                    const search_time = end_time - start_time;
                    const score = e.evaluate(new_board);
                    const info_msg = try std.fmt.allocPrint(self.allocator, "info depth {d} score cp {d} time {d}", .{ max_depth, score, search_time });
                    try self.allocated_strings.append(info_msg);
                    try self.respond(info_msg);
                    const move = helpers.moveToUci(self.current_board, new_board);
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
                self.search_in_progress = false;
            },
            .stop => {
                if (self.search_in_progress) {
                    self.search_in_progress = false;
                    if (try self.chooseBestMove()) |new_board| {
                        const move = helpers.moveToUci(self.current_board, new_board);
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
                self.current_board = b.Board{ .position = b.Position.init() };
            },
            .quit => {
                if (self.debug_mode) {
                    try self.respond("Goodbye!");
                }
            },
            else => {
                try self.respond(line);
            },
        }
    }

    pub fn mainLoop(self: *UciProtocol) !void {
        const stdin = std.io.getStdIn().reader();
        var buf: [1024]u8 = undefined;
        while (true) {
            if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
                if (UciCommand.fromString(line) == .quit) {
                    try self.processCommand(line);
                    break;
                }
                try self.processCommand(line);
            } else {
                break;
            }
        }
    }

    fn respond(self: *UciProtocol, msg: []const u8) !void {
        if (self.test_writer) |w| {
            try w.print("{s}\n", .{msg});
        } else {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("{s}\n", .{msg});
        }
    }

    pub fn deinit(self: *UciProtocol) void {
        for (self.allocated_strings.items) |str| {
            self.allocator.free(str);
        }
        self.allocated_strings.deinit();
    }
}; 