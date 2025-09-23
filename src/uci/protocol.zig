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
    allocated_strings: std.ArrayList([]u8) = std.ArrayList([]u8).empty,
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
            .allocated_strings = std.ArrayList([]u8).empty,
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

    fn infof(self: *UciProtocol, comptime fmt: []const u8, args: anytype) !void {
        const msg = try std.fmt.allocPrint(self.allocator, "info string " ++ fmt, args);
        errdefer self.allocator.free(msg);
        try self.allocated_strings.append(self.allocator, msg);
        try self.respond(msg);
    }

    fn debugInfo(self: *UciProtocol, comptime fmt: []const u8, args: anytype) !void {
        if (!self.debug_mode) return;
        try self.infof(fmt, args);
    }

    fn determineSearchDepth(self: *UciProtocol, limit_depth: u8) u8 {
        var search_depth: u8 = 1;
        if (self.skill_level > 5 and self.skill_level <= 10) {
            search_depth = 2;
        } else if (self.skill_level > 10) {
            search_depth = 3;
        }

        if (limit_depth != 0) {
            search_depth = @min(search_depth, limit_depth);
        }

        if (search_depth == 0) {
            search_depth = 1;
        }

        return search_depth;
    }

    fn chooseBestMove(self: *UciProtocol, limit_depth: u8, search: ?*e.SearchState) !?b.Board {
        const search_depth = self.determineSearchDepth(limit_depth);
        try self.debugInfo("Searching with depth {d}", .{search_depth});
        if (e.findBestMove(self.current_board, search_depth, search)) |best_move| {
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

    fn parsePositionLine(self: *UciProtocol, line: []const u8) !b.Board {
        var board = b.Board{ .position = b.Position.init() };
        var iter = std.mem.splitScalar(u8, line, ' ');
        _ = iter.next();
        if (iter.next()) |pos_type| {
            if (std.mem.eql(u8, pos_type, "startpos")) {
                board = b.Board{ .position = b.Position.init() };
            } else if (std.mem.eql(u8, pos_type, "fen")) {
                var fen = std.ArrayList(u8){};
                defer fen.deinit(self.allocator);
                while (iter.next()) |part| {
                    if (std.mem.eql(u8, part, "moves")) break;
                    try fen.appendSlice(self.allocator, part);
                    try fen.append(self.allocator, ' ');
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
                    try self.debugInfo("Processing move {d}: {s}", .{ move_count, token });
                    const move = try m.parseUciMove(token);
                    board = try m.applyMove(board, move);
                    try self.debugInfo("Side to move after move {d}: {d}", .{ move_count, board.position.sidetomove });
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
                try self.debugInfo("Received position command: {s}", .{line});
                self.current_board = try self.parsePositionLine(line);
            },
            .go => {
                self.search_in_progress = true;
                var iter = std.mem.splitScalar(u8, line, ' ');
                _ = iter.next();

                var depth_override: ?u8 = null;
                var movetime: ?u64 = null;
                var wtime: ?u64 = null;
                var btime: ?u64 = null;
                var winc: ?u64 = null;
                var binc: ?u64 = null;
                var moves_to_go: ?u32 = null;
                var ponder_flag = false;
                var infinite = false;

                while (iter.next()) |raw_param| {
                    const param = std.mem.trimRight(u8, raw_param, "\r");
                    if (std.mem.eql(u8, param, "depth")) {
                        if (iter.next()) |raw_value| {
                            const depth_str = std.mem.trimRight(u8, raw_value, "\r");
                            if (std.fmt.parseInt(u8, depth_str, 10)) |depth| {
                                depth_override = depth;
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid depth value");
                            }
                        }
                    } else if (std.mem.eql(u8, param, "movetime")) {
                        if (iter.next()) |raw_value| {
                            const time_str = std.mem.trimRight(u8, raw_value, "\r");
                            if (std.fmt.parseInt(u64, time_str, 10)) |time_ms| {
                                movetime = time_ms;
                            } else |_| {
                                if (self.debug_mode) try self.respond("info string Invalid movetime value");
                            }
                        }
                    } else if (std.mem.eql(u8, param, "wtime")) {
                        if (iter.next()) |raw_value| {
                            const value_str = std.mem.trimRight(u8, raw_value, "\r");
                            wtime = std.fmt.parseInt(u64, value_str, 10) catch wtime;
                        }
                    } else if (std.mem.eql(u8, param, "btime")) {
                        if (iter.next()) |raw_value| {
                            const value_str = std.mem.trimRight(u8, raw_value, "\r");
                            btime = std.fmt.parseInt(u64, value_str, 10) catch btime;
                        }
                    } else if (std.mem.eql(u8, param, "winc")) {
                        if (iter.next()) |raw_value| {
                            const value_str = std.mem.trimRight(u8, raw_value, "\r");
                            winc = std.fmt.parseInt(u64, value_str, 10) catch winc;
                        }
                    } else if (std.mem.eql(u8, param, "binc")) {
                        if (iter.next()) |raw_value| {
                            const value_str = std.mem.trimRight(u8, raw_value, "\r");
                            binc = std.fmt.parseInt(u64, value_str, 10) catch binc;
                        }
                    } else if (std.mem.eql(u8, param, "movestogo")) {
                        if (iter.next()) |raw_value| {
                            const value_str = std.mem.trimRight(u8, raw_value, "\r");
                            moves_to_go = std.fmt.parseInt(u32, value_str, 10) catch moves_to_go;
                        }
                    } else if (std.mem.eql(u8, param, "ponder")) {
                        ponder_flag = true;
                    } else if (std.mem.eql(u8, param, "infinite")) {
                        infinite = true;
                    }
                }

                if (ponder_flag) {
                    self.ponder = true;
                }

                const depth_limit = depth_override orelse 3;
                const reported_depth = self.determineSearchDepth(depth_limit);

                try self.respond("info string Starting search");
                const start_time = std.time.milliTimestamp();
                var search_state = e.SearchState{};

                if (!infinite) {
                    const overhead = @as(u64, self.move_overhead);
                    if (movetime) |time_ms| {
                        const effective = if (time_ms > overhead) time_ms - overhead else 0;
                        const casted = std.math.cast(i128, effective) orelse std.math.maxInt(i128);
                        search_state.deadline = start_time + casted;
                    } else {
                        const side_time = if (self.current_board.position.sidetomove == 0) wtime else btime;
                        if (side_time) |remaining| {
                            const increment = if (self.current_board.position.sidetomove == 0) winc else binc;
                            var allocation = remaining;
                            if (moves_to_go) |mtg| {
                                if (mtg > 0) {
                                    allocation = remaining / mtg;
                                }
                            } else if (remaining > 0) {
                                allocation = remaining / 30;
                            }
                            if (increment) |inc| allocation += inc;
                            const effective = if (allocation > overhead) allocation - overhead else 0;
                            const casted = std.math.cast(i128, effective) orelse std.math.maxInt(i128);
                            search_state.deadline = start_time + casted;
                        }
                    }
                }

                if (try self.chooseBestMove(depth_limit, &search_state)) |new_board| {
                    const end_time = std.time.milliTimestamp();
                    const raw_time = end_time - start_time;
                    const search_time = if (raw_time < 0) 0 else raw_time;
                    const score = e.evaluate(new_board);
                    const info_msg = try std.fmt.allocPrint(self.allocator, "info depth {d} score cp {d} time {d}", .{ reported_depth, score, search_time });
                    try self.allocated_strings.append(self.allocator, info_msg);
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
                        var out_buf: [32]u8 = undefined;
                        const bestmove_line = try std.fmt.bufPrint(&out_buf, "bestmove {s}\n", .{move_str[0..move_len]});
                        const stdout_file = std.fs.File.stdout();
                        try stdout_file.writeAll(bestmove_line);
                    }
                } else {
                    try self.respond("bestmove 0000");
                }
                self.search_in_progress = false;
            },
            .stop => {
                if (self.search_in_progress) {
                    self.search_in_progress = false;
                    if (try self.chooseBestMove(3, null)) |new_board| {
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
                            var out_buf: [32]u8 = undefined;
                            const bestmove_line = try std.fmt.bufPrint(&out_buf, "bestmove {s}\n", .{move_str[0..move_len]});
                            const stdout_file = std.fs.File.stdout();
                            try stdout_file.writeAll(bestmove_line);
                        }
                    } else {
                        try self.respond("bestmove 0000");
                    }
                }
            },
            .ucinewgame => {
                try self.debugInfo("Received ucinewgame command. Will be implemented in future.", .{});
                self.current_board = b.Board{ .position = b.Position.init() };
            },
            .debug => {
                var iter = std.mem.splitScalar(u8, line, ' ');
                _ = iter.next();
                if (iter.next()) |state| {
                    if (std.mem.eql(u8, state, "on")) {
                        self.debug_mode = true;
                        try self.infof("Debug mode enabled", .{});
                    } else if (std.mem.eql(u8, state, "off")) {
                        self.debug_mode = false;
                        // debugInfo would not emit after turning off, so respond directly.
                        try self.infof("Debug mode disabled", .{});
                    } else {
                        try self.infof("Unknown debug argument: {s}", .{state});
                    }
                } else {
                    try self.infof("Debug command missing state", .{});
                }
            },
            .quit => {
                try self.debugInfo("Goodbye!", .{});
            },
            else => {
                try self.debugInfo("Ignoring unsupported command: {s}", .{line});
            },
        }
    }

    pub fn mainLoop(self: *UciProtocol) !void {
        var stdin_buffer: [1024]u8 = undefined;
        var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
        while (true) {
            const line = stdin_reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            if (UciCommand.fromString(line) == .quit) {
                try self.processCommand(line);
                break;
            }
            try self.processCommand(line);
        }
    }

    fn respond(self: *UciProtocol, msg: []const u8) !void {
        if (self.test_writer) |w| {
            try w.print("{s}\n", .{msg});
        } else {
            const stdout_file = std.fs.File.stdout();
            try stdout_file.writeAll(msg);
            try stdout_file.writeAll("\n");
        }
    }

    pub fn deinit(self: *UciProtocol) void {
        for (self.allocated_strings.items) |str| {
            self.allocator.free(str);
        }
        self.allocated_strings.deinit(self.allocator);
    }
};
