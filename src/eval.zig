const std = @import("std");
const b = @import("board.zig");
const m = @import("moves.zig");
const s = @import("state.zig");
const c = @import("consts.zig");
const Board = b.Board;
const Piece = b.Piece;

// Transposition table entry
const TTEntry = struct {
    key: u64,
    depth: u8,
    score: i32,
    from_pos: u64, // Starting position of the move
    to_pos: u64, // Ending position of the move
    node_type: NodeType,
};

const NodeType = enum {
    Exact,
    LowerBound,
    UpperBound,
};

// Global transposition table
var transposition_table: ?[]TTEntry = null;
var tt_allocator: ?std.mem.Allocator = null;
var tt_mutex = std.Thread.Mutex{};
var tt_initialized = false;

/// Initialize the transposition table with the given size
pub fn initTranspositionTable(size: usize, allocator: std.mem.Allocator) !void {
    tt_mutex.lock();
    defer tt_mutex.unlock();

    // Free existing table if any
    if (tt_initialized) {
        if (transposition_table) |table| {
            if (tt_allocator) |alloc| {
                alloc.free(table);
            }
        }
        transposition_table = null;
        tt_allocator = null;
        tt_initialized = false;
    }

    // Allocate new table
    const new_table = try allocator.alloc(TTEntry, size);
    errdefer allocator.free(new_table);

    // Initialize all entries
    for (new_table) |*entry| {
        entry.* = TTEntry{
            .key = 0,
            .depth = 0,
            .score = 0,
            .from_pos = 0,
            .to_pos = 0,
            .node_type = .Exact,
        };
    }

    transposition_table = new_table;
    tt_allocator = allocator;
    tt_initialized = true;
}

/// Clean up the transposition table
pub fn deinitTranspositionTable() void {
    tt_mutex.lock();
    defer tt_mutex.unlock();

    if (tt_initialized) {
        if (transposition_table) |table| {
            if (tt_allocator) |alloc| {
                alloc.free(table);
            }
        }
        transposition_table = null;
        tt_allocator = null;
        tt_initialized = false;
    }
}

/// Reset the transposition table without deallocating memory
pub fn clearTranspositionTable() void {
    tt_mutex.lock();
    defer tt_mutex.unlock();

    if (tt_initialized and transposition_table != null) {
        if (transposition_table) |table| {
            for (table) |*entry| {
                entry.* = TTEntry{
                    .key = 0,
                    .depth = 0,
                    .score = 0,
                    .from_pos = 0,
                    .to_pos = 0,
                    .node_type = .Exact,
                };
            }
        }
    }
}

/// Get the size of the transposition table
pub fn getTranspositionTableSize() usize {
    tt_mutex.lock();
    defer tt_mutex.unlock();

    if (tt_initialized and transposition_table != null) {
        if (transposition_table) |table| {
            return table.len;
        }
    }
    return 0;
}

/// Check if the transposition table is initialized
pub fn isTranspositionTableInitialized() bool {
    tt_mutex.lock();
    defer tt_mutex.unlock();

    return tt_initialized and transposition_table != null and tt_allocator != null;
}

/// Get a Zobrist hash key for the board position
fn getZobristKey(board: Board) u64 {
    var key: u64 = 0;

    // Hash white pieces
    inline for (std.meta.fields(@TypeOf(board.position.whitepieces))) |field| {
        const piece = @field(board.position.whitepieces, field.name);
        if (@TypeOf(piece) == b.Piece) {
            if (piece.position != 0) {
                key ^= piece.position;
            }
        } else {
            for (piece) |p| {
                if (p.position != 0) {
                    key ^= p.position;
                }
            }
        }
    }

    // Hash black pieces
    inline for (std.meta.fields(@TypeOf(board.position.blackpieces))) |field| {
        const piece = @field(board.position.blackpieces, field.name);
        if (@TypeOf(piece) == b.Piece) {
            if (piece.position != 0) {
                key ^= piece.position << 1;
            }
        } else {
            for (piece) |p| {
                if (p.position != 0) {
                    key ^= p.position << 1;
                }
            }
        }
    }

    // Hash side to move
    if (board.position.sidetomove == 1) {
        key ^= 0xFFFFFFFFFFFFFFFF;
    }

    return key;
}

/// Store a position in the transposition table
fn storePosition(board: Board, depth: u8, score: i32, move: ?Board, node_type: NodeType) void {
    tt_mutex.lock();
    defer tt_mutex.unlock();

    if (tt_initialized and transposition_table != null) {
        if (transposition_table) |table| {
            const key = getZobristKey(board);
            const index = key % table.len;

            // Always replace with deeper search or same depth but more accurate node type
            if (table[index].depth <= depth or
                (table[index].depth == depth and node_type == .Exact))
            {
                var from_pos: u64 = 0;
                var to_pos: u64 = 0;

                if (move) |next_board| {
                    // Find the moved piece by comparing board positions
                    inline for (std.meta.fields(@TypeOf(board.position.whitepieces))) |field| {
                        const old_piece = @field(board.position.whitepieces, field.name);
                        const new_piece = @field(next_board.position.whitepieces, field.name);

                        if (@TypeOf(old_piece) == b.Piece) {
                            if (old_piece.position != new_piece.position) {
                                if (old_piece.position != 0) from_pos = old_piece.position;
                                if (new_piece.position != 0) to_pos = new_piece.position;
                            }
                        } else {
                            for (old_piece, 0..) |piece, i| {
                                if (piece.position != new_piece[i].position) {
                                    if (piece.position != 0) from_pos = piece.position;
                                    if (new_piece[i].position != 0) to_pos = new_piece[i].position;
                                }
                            }
                        }
                    }

                    if (from_pos == 0) {
                        inline for (std.meta.fields(@TypeOf(board.position.blackpieces))) |field| {
                            const old_piece = @field(board.position.blackpieces, field.name);
                            const new_piece = @field(next_board.position.blackpieces, field.name);

                            if (@TypeOf(old_piece) == b.Piece) {
                                if (old_piece.position != new_piece.position) {
                                    if (old_piece.position != 0) from_pos = old_piece.position;
                                    if (new_piece.position != 0) to_pos = new_piece.position;
                                }
                            } else {
                                for (old_piece, 0..) |piece, i| {
                                    if (piece.position != new_piece[i].position) {
                                        if (piece.position != 0) from_pos = piece.position;
                                        if (new_piece[i].position != 0) to_pos = new_piece[i].position;
                                    }
                                }
                            }
                        }
                    }
                }

                table[index] = TTEntry{
                    .key = key,
                    .depth = depth,
                    .score = score,
                    .from_pos = from_pos,
                    .to_pos = to_pos,
                    .node_type = node_type,
                };
            }
        }
    }
}

/// Probe the transposition table for a position
fn probePosition(board: Board, depth: u8) ?TTEntry {
    tt_mutex.lock();
    defer tt_mutex.unlock();

    if (tt_initialized and transposition_table != null) {
        if (transposition_table) |table| {
            const key = getZobristKey(board);
            const index = key % table.len;

            if (table[index].key == key and table[index].depth >= depth) {
                return table[index];
            }
        }
    }
    return null;
}

// Constants for minimax algorithm
pub const MAX_DEPTH = 15; // Increased from 6 to 15
pub const INFINITY_SCORE: i32 = 1000000;
pub const CHECKMATE_SCORE: i32 = 900000;

// Time management constants
pub const DEFAULT_MOVE_TIME: i64 = 5000; // Increased from 1000 to 5000 milliseconds
pub const MIN_MOVE_TIME: i64 = 100; // Minimum time per move in milliseconds
pub const SAFETY_MARGIN: i64 = 50; // Time safety margin in milliseconds

// Search statistics
pub const SearchStats = struct {
    nodes_searched: u64 = 0,
    start_time: i64 = 0,
    max_time: i64 = DEFAULT_MOVE_TIME,
    depth_reached: u8 = 0,
    best_move: ?Board = null,
    best_score: i32 = -INFINITY_SCORE,
    should_stop: bool = false,
};

/// Calculate the total material value on the board
fn calculateTotalMaterial(board: Board) i32 {
    var total: i32 = 0;

    // White pieces
    inline for (board.position.whitepieces.Pawn) |pawn| {
        if (pawn.position != 0) total += @as(i32, pawn.stdval) * 100;
    }
    inline for (board.position.whitepieces.Knight) |knight| {
        if (knight.position != 0) total += @as(i32, knight.stdval) * 100;
    }
    inline for (board.position.whitepieces.Bishop) |bishop| {
        if (bishop.position != 0) total += @as(i32, bishop.stdval) * 100;
    }
    inline for (board.position.whitepieces.Rook) |rook| {
        if (rook.position != 0) total += @as(i32, rook.stdval) * 100;
    }
    if (board.position.whitepieces.Queen.position != 0) {
        total += @as(i32, board.position.whitepieces.Queen.stdval) * 100;
    }

    // Black pieces
    inline for (board.position.blackpieces.Pawn) |pawn| {
        if (pawn.position != 0) total += @as(i32, pawn.stdval) * 100;
    }
    inline for (board.position.blackpieces.Knight) |knight| {
        if (knight.position != 0) total += @as(i32, knight.stdval) * 100;
    }
    inline for (board.position.blackpieces.Bishop) |bishop| {
        if (bishop.position != 0) total += @as(i32, bishop.stdval) * 100;
    }
    inline for (board.position.blackpieces.Rook) |rook| {
        if (rook.position != 0) total += @as(i32, rook.stdval) * 100;
    }
    if (board.position.blackpieces.Queen.position != 0) {
        total += @as(i32, board.position.blackpieces.Queen.stdval) * 100;
    }

    return total;
}

/// Check if we're in the endgame phase based on material
fn isEndgame(board: Board) bool {
    return calculateTotalMaterial(board) < c.ENDGAME_MATERIAL_THRESHOLD;
}

/// Get all pawns for a side on a specific file
fn getPawnsOnFile(board: Board, file_mask: u64, is_white: bool) u32 {
    var count: u32 = 0;

    if (is_white) {
        inline for (board.position.whitepieces.Pawn) |pawn| {
            if (pawn.position != 0 and (pawn.position & file_mask) != 0) {
                count += 1;
            }
        }
    } else {
        inline for (board.position.blackpieces.Pawn) |pawn| {
            if (pawn.position != 0 and (pawn.position & file_mask) != 0) {
                count += 1;
            }
        }
    }

    return count;
}

/// Check if a pawn is isolated (no friendly pawns on adjacent files)
fn isIsolatedPawn(board: Board, pawn_position: u64, is_white: bool) bool {
    // Determine the file of the pawn
    var file_index: u6 = 0;
    var temp = pawn_position;
    while (temp > 1) : (temp >>= 1) {
        file_index += 1;
    }
    file_index = file_index % 8;

    // Create masks for adjacent files
    var adjacent_files: u64 = 0;
    const file_mask: u64 = @as(u64, 0x0101010101010101);

    if (file_index > 0) { // Has file to the left
        const left_shift: u6 = 7 - (file_index - 1);
        adjacent_files |= file_mask << left_shift;
    }

    if (file_index < 7) { // Has file to the right
        const right_shift: u6 = 7 - (file_index + 1);
        adjacent_files |= file_mask << right_shift;
    }

    // Check if there are any friendly pawns on adjacent files
    var has_adjacent_pawn = false;

    if (is_white) {
        inline for (board.position.whitepieces.Pawn) |pawn| {
            if (pawn.position != 0 and pawn.position != pawn_position and (pawn.position & adjacent_files) != 0) {
                has_adjacent_pawn = true;
                break;
            }
        }
    } else {
        inline for (board.position.blackpieces.Pawn) |pawn| {
            if (pawn.position != 0 and pawn.position != pawn_position and (pawn.position & adjacent_files) != 0) {
                has_adjacent_pawn = true;
                break;
            }
        }
    }

    return !has_adjacent_pawn;
}

/// Check if a pawn is passed (no enemy pawns ahead on same or adjacent files)
fn isPassedPawn(board: Board, pawn_position: u64, is_white: bool) bool {
    // Determine the file and rank of the pawn
    var bit_pos: u6 = 0;
    var temp = pawn_position;
    while (temp > 1) : (temp >>= 1) {
        bit_pos += 1;
    }

    const file_index = bit_pos % 8;
    const rank_index = bit_pos / 8;

    // Create masks for the pawn's file and adjacent files
    var files_mask: u64 = 0;

    // Current file
    const file_shift: u6 = 7 - file_index;
    const file_mask: u64 = @as(u64, 0x0101010101010101);
    files_mask |= file_mask << file_shift;

    if (file_index > 0) { // Has file to the left
        const left_shift: u6 = 7 - (file_index - 1);
        files_mask |= file_mask << left_shift;
    }

    if (file_index < 7) { // Has file to the right
        const right_shift: u6 = 7 - (file_index + 1);
        files_mask |= file_mask << right_shift;
    }

    // Create mask for squares ahead of the pawn
    var ahead_mask: u64 = 0;

    if (is_white) {
        // For white pawns, "ahead" means higher ranks
        for (rank_index + 1..8) |r| {
            const rank_shift: u6 = @intCast(r * 8);
            const rank_mask: u64 = @as(u64, 0xFF);
            ahead_mask |= rank_mask << rank_shift;
        }
    } else {
        // For black pawns, "ahead" means lower ranks
        for (0..rank_index) |r| {
            const rank_shift: u6 = @intCast(r * 8);
            const rank_mask: u64 = @as(u64, 0xFF);
            ahead_mask |= rank_mask << rank_shift;
        }
    }

    // Combine masks to get squares ahead on same and adjacent files
    const check_mask = files_mask & ahead_mask;

    // Check if there are any enemy pawns in these squares
    var has_enemy_pawn = false;

    if (is_white) {
        // Check for black pawns
        inline for (board.position.blackpieces.Pawn) |pawn| {
            if (pawn.position != 0 and (pawn.position & check_mask) != 0) {
                has_enemy_pawn = true;
                break;
            }
        }
    } else {
        // Check for white pawns
        inline for (board.position.whitepieces.Pawn) |pawn| {
            if (pawn.position != 0 and (pawn.position & check_mask) != 0) {
                has_enemy_pawn = true;
                break;
            }
        }
    }

    return !has_enemy_pawn;
}

/// Evaluate pawn structure
fn evaluatePawnStructure(board: Board) i32 {
    var score: i32 = 0;

    // File masks for checking doubled pawns
    const file_masks = [8]u64{
        @as(u64, 0x0101010101010101) << @as(u6, 7), // A file
        @as(u64, 0x0101010101010101) << @as(u6, 6), // B file
        @as(u64, 0x0101010101010101) << @as(u6, 5), // C file
        @as(u64, 0x0101010101010101) << @as(u6, 4), // D file
        @as(u64, 0x0101010101010101) << @as(u6, 3), // E file
        @as(u64, 0x0101010101010101) << @as(u6, 2), // F file
        @as(u64, 0x0101010101010101) << @as(u6, 1), // G file
        0x0101010101010101, // H file
    };

    // Check for doubled pawns
    for (file_masks) |file_mask| {
        // Doubled pawns
        const white_pawns_on_file = getPawnsOnFile(board, file_mask, true);
        const black_pawns_on_file = getPawnsOnFile(board, file_mask, false);

        if (white_pawns_on_file > 1) {
            // Convert to i32 before multiplication with penalty
            const penalty = @as(i32, @intCast(white_pawns_on_file - 1)) * c.DOUBLED_PAWN_PENALTY;
            score += penalty;
        }

        if (black_pawns_on_file > 1) {
            const penalty = @as(i32, @intCast(black_pawns_on_file - 1)) * c.DOUBLED_PAWN_PENALTY;
            score -= penalty;
        }
    }

    // Check each pawn for isolated and passed status
    inline for (board.position.whitepieces.Pawn) |pawn| {
        if (pawn.position != 0) {
            if (isIsolatedPawn(board, pawn.position, true)) {
                score += c.ISOLATED_PAWN_PENALTY;
            }

            if (isPassedPawn(board, pawn.position, true)) {
                score += c.PASSED_PAWN_BONUS;
            }
        }
    }

    inline for (board.position.blackpieces.Pawn) |pawn| {
        if (pawn.position != 0) {
            if (isIsolatedPawn(board, pawn.position, false)) {
                score -= c.ISOLATED_PAWN_PENALTY;
            }

            if (isPassedPawn(board, pawn.position, false)) {
                score -= c.PASSED_PAWN_BONUS;
            }
        }
    }

    return score;
}

/// Evaluate king safety
fn evaluateKingSafety(board: Board) i32 {
    var score: i32 = 0;
    const end_game = isEndgame(board);

    // White king safety
    if (board.position.whitepieces.King.position != 0) {
        // Get king position
        var king_pos: u6 = 0;
        var temp = board.position.whitepieces.King.position;
        while (temp > 1) : (temp >>= 1) {
            king_pos += 1;
        }

        // Use appropriate king position table based on game phase
        if (end_game) {
            score += getPiecePositionValue(board.position.whitepieces.King.position, c.KING_ENDGAME_TABLE, true);
        } else {
            score += getPiecePositionValue(board.position.whitepieces.King.position, c.KING_MIDDLEGAME_TABLE, true);

            // Check for pawn shield in front of the king (only in middlegame)
            const king_file = king_pos % 8;
            const king_rank = king_pos / 8;

            // Define the area in front of the king where we want pawns
            var shield_area: u64 = 0;

            // King on the kingside (files f, g, h)
            if (king_file >= 5) {
                shield_area |= c.F2 | c.G2 | c.H2;
                if (king_rank == 0) { // King on first rank
                    shield_area |= c.F3 | c.G3 | c.H3;
                }
            }
            // King on the queenside (files a, b, c)
            else if (king_file <= 2) {
                shield_area |= c.A2 | c.B2 | c.C2;
                if (king_rank == 0) { // King on first rank
                    shield_area |= c.A3 | c.B3 | c.C3;
                }
            }

            // Count pawns in the shield area
            var shield_pawns: u32 = 0;
            inline for (board.position.whitepieces.Pawn) |pawn| {
                if (pawn.position != 0 and (pawn.position & shield_area) != 0) {
                    shield_pawns += 1;
                }
            }

            // Bonus for each pawn in the shield
            score += @as(i32, @intCast(shield_pawns)) * c.KING_PAWN_SHIELD_BONUS;
        }
    }

    // Black king safety
    if (board.position.blackpieces.King.position != 0) {
        // Get king position
        var king_pos: u6 = 0;
        var temp = board.position.blackpieces.King.position;
        while (temp > 1) : (temp >>= 1) {
            king_pos += 1;
        }

        // Use appropriate king position table based on game phase
        if (end_game) {
            score -= getPiecePositionValue(board.position.blackpieces.King.position, c.KING_ENDGAME_TABLE, false);
        } else {
            score -= getPiecePositionValue(board.position.blackpieces.King.position, c.KING_MIDDLEGAME_TABLE, false);

            // Check for pawn shield in front of the king (only in middlegame)
            const king_file = king_pos % 8;
            const king_rank = king_pos / 8;

            // Define the area in front of the king where we want pawns
            var shield_area: u64 = 0;

            // King on the kingside (files f, g, h)
            if (king_file >= 5) {
                shield_area |= c.F7 | c.G7 | c.H7;
                if (king_rank == 7) { // King on eighth rank
                    shield_area |= c.F6 | c.G6 | c.H6;
                }
            }
            // King on the queenside (files a, b, c)
            else if (king_file <= 2) {
                shield_area |= c.A7 | c.B7 | c.C7;
                if (king_rank == 7) { // King on eighth rank
                    shield_area |= c.A6 | c.B6 | c.C6;
                }
            }

            // Count pawns in the shield area
            var shield_pawns: u32 = 0;
            inline for (board.position.blackpieces.Pawn) |pawn| {
                if (pawn.position != 0 and (pawn.position & shield_area) != 0) {
                    shield_pawns += 1;
                }
            }

            // Bonus for each pawn in the shield
            score -= @as(i32, @intCast(shield_pawns)) * c.KING_PAWN_SHIELD_BONUS;
        }
    }

    return score;
}

/// Evaluate control of the center
fn evaluateCenterControl(board: Board) i32 {
    var score: i32 = 0;

    // Count pieces controlling center squares
    inline for (board.position.whitepieces.Pawn) |pawn| {
        if (pawn.position != 0) {
            // Check if pawn attacks center squares
            const attacks_left = pawn.position << 7;
            const attacks_right = pawn.position << 9;

            if ((attacks_left & c.CENTER_SQUARES) != 0) {
                score += c.CENTER_CONTROL_BONUS;
            }

            if ((attacks_right & c.CENTER_SQUARES) != 0) {
                score += c.CENTER_CONTROL_BONUS;
            }

            // Bonus for pawns in extended center
            if ((pawn.position & c.EXTENDED_CENTER) != 0) {
                score += c.CENTER_CONTROL_BONUS;
            }
        }
    }

    inline for (board.position.blackpieces.Pawn) |pawn| {
        if (pawn.position != 0) {
            // Check if pawn attacks center squares
            const attacks_left = pawn.position >> 9;
            const attacks_right = pawn.position >> 7;

            if ((attacks_left & c.CENTER_SQUARES) != 0) {
                score -= c.CENTER_CONTROL_BONUS;
            }

            if ((attacks_right & c.CENTER_SQUARES) != 0) {
                score -= c.CENTER_CONTROL_BONUS;
            }

            // Bonus for pawns in extended center
            if ((pawn.position & c.EXTENDED_CENTER) != 0) {
                score -= c.CENTER_CONTROL_BONUS;
            }
        }
    }

    // Knights in or controlling center
    inline for (board.position.whitepieces.Knight) |knight| {
        if (knight.position != 0) {
            // Bonus for knights in extended center
            if ((knight.position & c.EXTENDED_CENTER) != 0) {
                score += c.CENTER_CONTROL_BONUS * 2;
            }

            // Check knight moves that control center
            const moves = m.getValidKnightMoves(knight, board);
            for (moves) |move| {
                if ((move.position.whitepieces.Knight[0].position & c.CENTER_SQUARES) != 0 or
                    (move.position.whitepieces.Knight[1].position & c.CENTER_SQUARES) != 0)
                {
                    score += c.CENTER_CONTROL_BONUS;
                    break;
                }
            }
        }
    }

    inline for (board.position.blackpieces.Knight) |knight| {
        if (knight.position != 0) {
            // Bonus for knights in extended center
            if ((knight.position & c.EXTENDED_CENTER) != 0) {
                score -= c.CENTER_CONTROL_BONUS * 2;
            }

            // Check knight moves that control center
            const moves = m.getValidKnightMoves(knight, board);
            for (moves) |move| {
                if ((move.position.blackpieces.Knight[0].position & c.CENTER_SQUARES) != 0 or
                    (move.position.blackpieces.Knight[1].position & c.CENTER_SQUARES) != 0)
                {
                    score -= c.CENTER_CONTROL_BONUS;
                    break;
                }
            }
        }
    }

    return score;
}

/// Evaluate piece mobility (number of legal moves)
fn evaluateMobility(board: Board) i32 {
    var score: i32 = 0;

    // White pieces mobility
    inline for (board.position.whitepieces.Knight) |knight| {
        if (knight.position != 0) {
            const moves = m.getValidKnightMoves(knight, board);
            score += @as(i32, @intCast(moves.len)) * c.MOBILITY_FACTOR;
        }
    }

    inline for (board.position.whitepieces.Bishop) |bishop| {
        if (bishop.position != 0) {
            const moves = m.getValidBishopMoves(bishop, board);
            score += @as(i32, @intCast(moves.len)) * c.MOBILITY_FACTOR;
        }
    }

    return score;
}

/// Check if we should stop the search based on time constraints
fn shouldStopSearch(stats: *SearchStats) bool {
    if (stats.should_stop) return true;

    const current_time = std.time.milliTimestamp();
    const elapsed_time = current_time - stats.start_time;

    // Stop if we've used up our allocated time minus safety margin
    if (elapsed_time >= stats.max_time - SAFETY_MARGIN) {
        stats.should_stop = true;
        return true;
    }

    return false;
}

/// Find the best move at a fixed depth
pub fn findBestMove(board: Board, depth: u8) ?Board {
    var stats = SearchStats{
        .nodes_searched = 0,
        .start_time = std.time.milliTimestamp(),
        .max_time = DEFAULT_MOVE_TIME,
        .depth_reached = 0,
        .best_move = null,
        .best_score = -INFINITY_SCORE,
        .should_stop = false,
    };

    // Get all valid moves
    const moves = m.allvalidmoves(board);
    if (moves.len == 0) {
        return null;
    }

    var best_score = -INFINITY_SCORE;
    var best_move: ?Board = null;

    // Evaluate each move
    for (moves) |move| {
        const score = minimax(move, depth - 1, -INFINITY_SCORE, INFINITY_SCORE, false, &stats);
        if (score > best_score) {
            best_score = score;
            best_move = move;
        }
    }

    return best_move;
}

/// Find the best move using iterative deepening
pub fn findBestMoveWithTime(board: Board, max_depth: u8, max_time_ms: i64) ?Board {
    var stats = SearchStats{
        .nodes_searched = 0,
        .start_time = std.time.milliTimestamp(),
        .max_time = max_time_ms,
        .depth_reached = 0,
        .best_move = null,
        .best_score = -INFINITY_SCORE,
        .should_stop = false,
    };

    // Get all valid moves
    const moves = m.allvalidmoves(board);
    if (moves.len == 0) {
        return null;
    }

    // Initialize best move to first legal move as a fallback
    stats.best_move = moves[0];

    // Iterative deepening - start from depth 1 and increase until max_depth or time runs out
    var current_depth: u8 = 1;
    while (current_depth <= max_depth and !shouldStopSearch(&stats)) : (current_depth += 1) {
        var best_score = -INFINITY_SCORE;
        var alpha = -INFINITY_SCORE;
        const beta = INFINITY_SCORE;

        // Search each move at the current depth
        for (moves) |move| {
            const score = minimax(move, current_depth - 1, alpha, beta, false, &stats);
            if (score > best_score) {
                best_score = score;
                stats.best_move = move;
                stats.best_score = score;
            }
            alpha = @max(alpha, best_score);

            if (shouldStopSearch(&stats)) {
                break;
            }
        }

        // Store the best move in the transposition table
        if (!shouldStopSearch(&stats)) {
            const node_type: NodeType = if (best_score <= alpha)
                .UpperBound
            else if (best_score >= beta)
                .LowerBound
            else
                .Exact;
            storePosition(board, current_depth, best_score, stats.best_move, node_type);
        }

        stats.depth_reached = current_depth;
    }

    return stats.best_move;
}

/// Minimax algorithm with alpha-beta pruning
/// Returns the best score for the current position
pub fn minimax(board: Board, depth: u8, alpha: i32, beta: i32, maximizingPlayer: bool, stats: *SearchStats) i32 {
    // Increment node count
    stats.nodes_searched += 1;

    // Check if we should stop the search due to time constraints
    if (stats.nodes_searched % 1000 == 0 and shouldStopSearch(stats)) {
        return if (maximizingPlayer) -INFINITY_SCORE else INFINITY_SCORE;
    }

    // Check transposition table
    if (probePosition(board, depth)) |tt_entry| {
        switch (tt_entry.node_type) {
            .Exact => return tt_entry.score,
            .LowerBound => {
                if (tt_entry.score >= beta) {
                    return tt_entry.score;
                }
            },
            .UpperBound => {
                if (tt_entry.score <= alpha) {
                    return tt_entry.score;
                }
            },
        }
    }

    // Base case: if we've reached the maximum depth or the game is over
    if (depth == 0) {
        const score = evaluate(board);
        storePosition(board, depth, score, null, .Exact);
        return score;
    }

    // Check for checkmate or stalemate
    const isWhite = board.position.sidetomove == 0;
    if (s.isCheckmate(board, isWhite)) {
        const score = if (maximizingPlayer) -CHECKMATE_SCORE else CHECKMATE_SCORE;
        storePosition(board, depth, score, null, .Exact);
        return score;
    }

    // Get all valid moves
    const moves = m.allvalidmoves(board);
    if (moves.len == 0) {
        // No legal moves - stalemate (draw)
        storePosition(board, depth, 0, null, .Exact);
        return 0;
    }

    if (maximizingPlayer) {
        var value: i32 = -INFINITY_SCORE;
        var alpha_local = alpha;
        var best_move: ?Board = null;

        for (moves) |move| {
            // Recursively evaluate the position
            const eval_score = minimax(move, depth - 1, alpha_local, beta, false, stats);
            if (eval_score > value) {
                value = eval_score;
                best_move = move;
            }

            // Alpha-beta pruning
            alpha_local = @max(alpha_local, value);
            if (beta <= alpha_local) {
                // Store lower bound in transposition table
                storePosition(board, depth, value, best_move, .LowerBound);
                break; // Beta cutoff
            }

            // Check for time constraints
            if (shouldStopSearch(stats)) {
                break;
            }
        }

        // Store the result in the transposition table
        const node_type: NodeType = if (value <= alpha)
            .UpperBound
        else if (value >= beta)
            .LowerBound
        else
            .Exact;
        storePosition(board, depth, value, best_move, node_type);
        return value;
    } else {
        var value: i32 = INFINITY_SCORE;
        var beta_local = beta;
        var best_move: ?Board = null;

        for (moves) |move| {
            // Recursively evaluate the position
            const eval_score = minimax(move, depth - 1, alpha, beta_local, true, stats);
            if (eval_score < value) {
                value = eval_score;
                best_move = move;
            }

            // Alpha-beta pruning
            beta_local = @min(beta_local, value);
            if (beta_local <= alpha) {
                // Store upper bound in transposition table
                storePosition(board, depth, value, best_move, .UpperBound);
                break; // Alpha cutoff
            }

            // Check for time constraints
            if (shouldStopSearch(stats)) {
                break;
            }
        }

        // Store the result in the transposition table
        const node_type: NodeType = if (value <= alpha)
            .UpperBound
        else if (value >= beta)
            .LowerBound
        else
            .Exact;
        storePosition(board, depth, value, best_move, node_type);
        return value;
    }
}

/// Get the position value for a piece from a position table
fn getPiecePositionValue(position: u64, table: [64]i32, is_white: bool) i32 {
    // Find the bit position (0-63)
    var bit_pos: u6 = 0;
    var temp = position;
    while (temp > 1) : (temp >>= 1) {
        bit_pos += 1;
    }

    // For white pieces, use the position directly
    // For black pieces, flip the position vertically (63 - bit_pos)
    const table_index = if (is_white) bit_pos else 63 - bit_pos;

    return table[table_index];
}

/// Evaluate the position
pub fn evaluate(board: Board) i32 {
    var score: i32 = 0;

    // Material evaluation
    // White pieces
    inline for (board.position.whitepieces.Pawn) |pawn| {
        if (pawn.position != 0) {
            score += @as(i32, pawn.stdval) * 100;
            // Add position value for pawns
            score += getPiecePositionValue(pawn.position, c.PAWN_POSITION_TABLE, true);
        }
    }
    inline for (board.position.whitepieces.Knight) |knight| {
        if (knight.position != 0) {
            score += @as(i32, knight.stdval) * 100;
            // Add position value for knights
            score += getPiecePositionValue(knight.position, c.KNIGHT_POSITION_TABLE, true);
        }
    }
    inline for (board.position.whitepieces.Bishop) |bishop| {
        if (bishop.position != 0) {
            score += @as(i32, bishop.stdval) * 100;
            // Add position value for bishops
            score += getPiecePositionValue(bishop.position, c.BISHOP_POSITION_TABLE, true);
        }
    }
    inline for (board.position.whitepieces.Rook) |rook| {
        if (rook.position != 0) {
            score += @as(i32, rook.stdval) * 100;
            // Add position value for rooks
            score += getPiecePositionValue(rook.position, c.ROOK_POSITION_TABLE, true);
        }
    }
    if (board.position.whitepieces.Queen.position != 0) {
        score += @as(i32, board.position.whitepieces.Queen.stdval) * 100;
        // Add position value for queen
        score += getPiecePositionValue(board.position.whitepieces.Queen.position, c.QUEEN_POSITION_TABLE, true);
    }
    if (board.position.whitepieces.King.position != 0) {
        score += @as(i32, board.position.whitepieces.King.stdval) * 100;
        // King position value is handled in evaluateKingSafety
    }

    // Black pieces
    inline for (board.position.blackpieces.Pawn) |pawn| {
        if (pawn.position != 0) {
            score -= @as(i32, pawn.stdval) * 100;
            // Add position value for pawns (inverted for black)
            score -= getPiecePositionValue(pawn.position, c.PAWN_POSITION_TABLE, false);
        }
    }
    inline for (board.position.blackpieces.Knight) |knight| {
        if (knight.position != 0) {
            score -= @as(i32, knight.stdval) * 100;
            // Add position value for knights (inverted for black)
            score -= getPiecePositionValue(knight.position, c.KNIGHT_POSITION_TABLE, false);
        }
    }
    inline for (board.position.blackpieces.Bishop) |bishop| {
        if (bishop.position != 0) {
            score -= @as(i32, bishop.stdval) * 100;
            // Add position value for bishops (inverted for black)
            score -= getPiecePositionValue(bishop.position, c.BISHOP_POSITION_TABLE, false);
        }
    }
    inline for (board.position.blackpieces.Rook) |rook| {
        if (rook.position != 0) {
            score -= @as(i32, rook.stdval) * 100;
            // Add position value for rooks (inverted for black)
            score -= getPiecePositionValue(rook.position, c.ROOK_POSITION_TABLE, false);
        }
    }
    if (board.position.blackpieces.Queen.position != 0) {
        score -= @as(i32, board.position.blackpieces.Queen.stdval) * 100;
        // Add position value for queen (inverted for black)
        score -= getPiecePositionValue(board.position.blackpieces.Queen.position, c.QUEEN_POSITION_TABLE, false);
    }
    if (board.position.blackpieces.King.position != 0) {
        score -= @as(i32, board.position.blackpieces.King.stdval) * 100;
        // King position value is handled in evaluateKingSafety
    }

    // Additional evaluation factors
    // Bonus for having both bishops
    if (board.position.whitepieces.Bishop[0].position != 0 and
        board.position.whitepieces.Bishop[1].position != 0)
    {
        score += c.BISHOP_PAIR_BONUS;
    }
    if (board.position.blackpieces.Bishop[0].position != 0 and
        board.position.blackpieces.Bishop[1].position != 0)
    {
        score -= c.BISHOP_PAIR_BONUS;
    }

    // Evaluate pawn structure
    score += evaluatePawnStructure(board);

    // Evaluate king safety
    score += evaluateKingSafety(board);

    // Evaluate center control
    score += evaluateCenterControl(board);

    // Evaluate piece mobility
    score += evaluateMobility(board);

    // Check and checkmate evaluation
    if (s.isCheckmate(board, true)) {
        score = -CHECKMATE_SCORE; // White is checkmated
    } else if (s.isCheckmate(board, false)) {
        score = CHECKMATE_SCORE; // Black is checkmated
    } else if (s.isCheck(board, true)) {
        score -= 50; // White is in check
    } else if (s.isCheck(board, false)) {
        score += 50; // Black is in check
    }

    return score;
}
