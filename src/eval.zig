const std = @import("std");
const b = @import("board.zig");
const m = @import("moves.zig");
const s = @import("state.zig");
const c = @import("consts.zig");
const Board = b.Board;
const Piece = b.Piece;

// Constants for minimax algorithm
pub const MAX_DEPTH = 6; // Increased from 3 to 6
pub const INFINITY_SCORE: i32 = 1000000;
pub const CHECKMATE_SCORE: i32 = 900000;

// Time management constants
pub const DEFAULT_MOVE_TIME: i64 = 1000; // Default time per move in milliseconds
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
        if (bishop.position != 0) score += @as(i32, bishop.stdval) * 100;
    }
    inline for (board.position.whitepieces.Rook) |rook| {
        if (rook.position != 0) score += @as(i32, rook.stdval) * 100;
    }
    if (board.position.whitepieces.Queen.position != 0) {
        score += @as(i32, board.position.whitepieces.Queen.stdval) * 100;
    }
    if (board.position.whitepieces.King.position != 0) {
        score += @as(i32, board.position.whitepieces.King.stdval) * 100;
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
        if (bishop.position != 0) score -= @as(i32, bishop.stdval) * 100;
    }
    inline for (board.position.blackpieces.Rook) |rook| {
        if (rook.position != 0) score -= @as(i32, rook.stdval) * 100;
    }
    if (board.position.blackpieces.Queen.position != 0) {
        score -= @as(i32, board.position.blackpieces.Queen.stdval) * 100;
    }
    if (board.position.blackpieces.King.position != 0) {
        score -= @as(i32, board.position.blackpieces.King.stdval) * 100;
    }

    // Additional evaluation factors
    // Bonus for having both bishops
    if (board.position.whitepieces.Bishop[0].position != 0 and
        board.position.whitepieces.Bishop[1].position != 0)
    {
        score += 50; // Bishop pair bonus
    }
    if (board.position.blackpieces.Bishop[0].position != 0 and
        board.position.blackpieces.Bishop[1].position != 0)
    {
        score -= 50; // Bishop pair bonus for black
    }

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

/// Minimax algorithm with alpha-beta pruning
/// Returns the best score for the current position
pub fn minimax(board: Board, depth: u8, alpha: i32, beta: i32, maximizingPlayer: bool, stats: *SearchStats) i32 {
    // Increment node count
    stats.nodes_searched += 1;

    // Check if we should stop the search due to time constraints
    if (stats.nodes_searched % 1000 == 0 and shouldStopSearch(stats)) {
        return if (maximizingPlayer) -INFINITY_SCORE else INFINITY_SCORE;
    }

    // Base case: if we've reached the maximum depth or the game is over
    if (depth == 0) {
        return evaluate(board);
    }

    // Check for checkmate or stalemate
    const isWhite = board.position.sidetomove == 0;
    if (s.isCheckmate(board, isWhite)) {
        return if (maximizingPlayer) -CHECKMATE_SCORE else CHECKMATE_SCORE;
    }

    // Get all valid moves
    const moves = m.allvalidmoves(board);
    if (moves.len == 0) {
        // No legal moves - stalemate (draw)
        return 0;
    }

    if (maximizingPlayer) {
        var value: i32 = -INFINITY_SCORE;
        var alpha_local = alpha;

        for (moves) |move| {
            // Recursively evaluate the position
            const eval_score = minimax(move, depth - 1, alpha_local, beta, false, stats);
            value = @max(value, eval_score);

            // Alpha-beta pruning
            alpha_local = @max(alpha_local, value);
            if (beta <= alpha_local) {
                break; // Beta cutoff
            }

            // Check for time constraints
            if (shouldStopSearch(stats)) {
                break;
            }
        }
        return value;
    } else {
        var value: i32 = INFINITY_SCORE;
        var beta_local = beta;

        for (moves) |move| {
            // Recursively evaluate the position
            const eval_score = minimax(move, depth - 1, alpha, beta_local, true, stats);
            value = @min(value, eval_score);

            // Alpha-beta pruning
            beta_local = @min(beta_local, value);
            if (beta_local <= alpha) {
                break; // Alpha cutoff
            }

            // Check for time constraints
            if (shouldStopSearch(stats)) {
                break;
            }
        }
        return value;
    }
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

    // Iterative deepening - start from depth 1 and increase until max_depth or time runs out
    var current_depth: u8 = 1;
    while (current_depth <= max_depth and !shouldStopSearch(&stats)) {
        const best_move = findBestMoveAtDepth(board, current_depth, &stats);

        // If we found a valid move and didn't run out of time during the search,
        // update our best move
        if (best_move != null and !stats.should_stop) {
            stats.best_move = best_move;
            stats.depth_reached = current_depth;
        } else if (stats.should_stop) {
            // If we ran out of time, stop the iterative deepening
            break;
        }

        current_depth += 1;
    }

    return stats.best_move;
}

/// Find the best move at a specific depth
pub fn findBestMoveAtDepth(board: Board, depth: u8, stats: *SearchStats) ?Board {
    const moves = m.allvalidmoves(board);
    if (moves.len == 0) {
        return null; // No legal moves
    }

    // Define the move score struct type
    const MoveScore = struct { move: Board, score: i32 };

    // Create a list of moves with their scores for sorting
    var move_scores = std.ArrayList(MoveScore).init(std.heap.page_allocator);
    defer move_scores.deinit();

    // First, evaluate all moves with a shallow search to get initial scores
    for (moves) |move| {
        // Simple heuristic: captures are likely better
        var score: i32 = 0;

        // Check if this is a capture move by comparing piece counts
        const white_pieces_before = countPieces(board, true);
        const black_pieces_before = countPieces(board, false);
        const white_pieces_after = countPieces(move, true);
        const black_pieces_after = countPieces(move, false);

        if (board.position.sidetomove == 0) { // White's move
            if (black_pieces_before > black_pieces_after) {
                // White captured a black piece
                score = 1000; // Prioritize captures
            }
        } else { // Black's move
            if (white_pieces_before > white_pieces_after) {
                // Black captured a white piece
                score = 1000; // Prioritize captures
            }
        }

        // Check if move puts opponent in check
        if (board.position.sidetomove == 0) { // White's move
            if (s.isCheck(move, false)) {
                score += 500; // Prioritize checks
            }
        } else { // Black's move
            if (s.isCheck(move, true)) {
                score += 500; // Prioritize checks
            }
        }

        // Add the move and its score to our list
        move_scores.append(.{ .move = move, .score = score }) catch continue;
    }

    // Sort moves by score (descending)
    std.mem.sort(MoveScore, move_scores.items, {}, struct {
        fn compare(_: void, a: MoveScore, b_move: MoveScore) bool {
            return a.score > b_move.score;
        }
    }.compare);

    // Now perform the full minimax search on the sorted moves
    var bestScore: i32 = -INFINITY_SCORE;
    var bestMoveIndex: usize = 0;
    const maximizingPlayer = board.position.sidetomove == 0; // White is maximizing

    for (move_scores.items, 0..) |move_data, i| {
        // For each move, evaluate the resulting position
        const score = minimax(move_data.move, depth - 1, -INFINITY_SCORE, INFINITY_SCORE, !maximizingPlayer, stats);

        // Update best move if we found a better one
        if (score > bestScore) {
            bestScore = score;
            bestMoveIndex = i;
            stats.best_score = score;
        }

        // Check if we should stop due to time constraints
        if (shouldStopSearch(stats)) {
            break;
        }
    }

    if (move_scores.items.len > 0 and !stats.should_stop) {
        return move_scores.items[bestMoveIndex].move;
    } else if (moves.len > 0 and stats.best_move == null) {
        // Fallback if move scoring failed or we ran out of time on first depth
        return moves[0];
    } else {
        return null;
    }
}

/// Find the best move using the minimax algorithm (legacy function for compatibility)
pub fn findBestMove(board: Board, depth: u8) ?Board {
    return findBestMoveWithTime(board, depth, DEFAULT_MOVE_TIME);
}

/// Count the number of pieces for a side
fn countPieces(board: Board, white: bool) u32 {
    var count: u32 = 0;

    if (white) {
        // Count white pieces
        for (board.position.whitepieces.Pawn) |pawn| {
            if (pawn.position != 0) count += 1;
        }
        for (board.position.whitepieces.Knight) |knight| {
            if (knight.position != 0) count += 1;
        }
        for (board.position.whitepieces.Bishop) |bishop| {
            if (bishop.position != 0) count += 1;
        }
        for (board.position.whitepieces.Rook) |rook| {
            if (rook.position != 0) count += 1;
        }
        if (board.position.whitepieces.Queen.position != 0) count += 1;
        if (board.position.whitepieces.King.position != 0) count += 1;
    } else {
        // Count black pieces
        for (board.position.blackpieces.Pawn) |pawn| {
            if (pawn.position != 0) count += 1;
        }
        for (board.position.blackpieces.Knight) |knight| {
            if (knight.position != 0) count += 1;
        }
        for (board.position.blackpieces.Bishop) |bishop| {
            if (bishop.position != 0) count += 1;
        }
        for (board.position.blackpieces.Rook) |rook| {
            if (rook.position != 0) count += 1;
        }
        if (board.position.blackpieces.Queen.position != 0) count += 1;
        if (board.position.blackpieces.King.position != 0) count += 1;
    }

    return count;
}

test "evaluate initial position is balanced" {
    const board = Board{ .position = b.Position.init() };
    const score = evaluate(board);
    // The initial position might not be exactly 0 due to position evaluation
    try std.testing.expect(score >= -10 and score <= 10);
}

test "evaluate position with extra white pawn" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.blackpieces.Pawn[0].position = 0; // Remove a black pawn
    board.position = pos;
    const score = evaluate(board);
    // Score includes pawn value (100) plus position value
    try std.testing.expect(score >= 90); // At least the pawn value
}

test "evaluate position with extra white queen" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.blackpieces.Queen.position = 0; // Remove black queen
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= 900); // Queen value is at least 900
}

test "evaluate position with missing white king" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.whitepieces.King.position = 0; // Remove white king
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score <= -25000); // King value is very high
}

test "evaluate empty board" {
    const board = Board{ .position = b.Position.emptyboard() };
    const score = evaluate(board);
    try std.testing.expectEqual(score, 0);
}

test "evaluate position with multiple missing pieces" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.blackpieces.Pawn[0].position = 0; // Remove a black pawn
    pos.blackpieces.Knight[0].position = 0; // Remove a black knight
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= 400); // At least pawn (100) + knight (300)
}

test "evaluate position with pieces missing on both sides" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.blackpieces.Pawn[0].position = 0; // Remove a black pawn
    pos.whitepieces.Knight[0].position = 0; // Remove a white knight
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= -200 and score <= -100); // Black pawn removed (+100) and white knight removed (-300)
}

test "evaluate position with all pieces removed except kings" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Remove all pieces except kings
    for (&pos.whitepieces.Pawn) |*pawn| {
        pawn.position = 0;
    }
    for (&pos.whitepieces.Knight) |*knight| {
        knight.position = 0;
    }
    for (&pos.whitepieces.Bishop) |*bishop| {
        bishop.position = 0;
    }
    for (&pos.whitepieces.Rook) |*rook| {
        rook.position = 0;
    }
    pos.whitepieces.Queen.position = 0;

    for (&pos.blackpieces.Pawn) |*pawn| {
        pawn.position = 0;
    }
    for (&pos.blackpieces.Knight) |*knight| {
        knight.position = 0;
    }
    for (&pos.blackpieces.Bishop) |*bishop| {
        bishop.position = 0;
    }
    for (&pos.blackpieces.Rook) |*rook| {
        rook.position = 0;
    }
    pos.blackpieces.Queen.position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= -50 and score <= 50); // Kings should be roughly balanced
}

test "evaluate position with minor piece advantage" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Remove a black bishop and white knight to test different minor piece values
    pos.blackpieces.Bishop[0].position = 0;
    pos.whitepieces.Knight[0].position = 0;

    board.position = pos;
    const score = evaluate(board);
    // The score might not be exactly 0 due to position evaluation
    try std.testing.expect(score >= -100 and score <= 100); // Bishop and knight have similar value
}

test "evaluate position with multiple captures" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Simulate a position where white has captured several black pieces
    pos.blackpieces.Pawn[0].position = 0;
    pos.blackpieces.Pawn[1].position = 0;
    pos.blackpieces.Knight[0].position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= 500); // At least 2 pawns (200) + 1 knight (300)
}

test "evaluate position with queen trade" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Remove both queens
    pos.whitepieces.Queen.position = 0;
    pos.blackpieces.Queen.position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= -50 and score <= 50); // Should be roughly balanced
}

test "evaluate position with rook advantage" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Remove both black rooks
    pos.blackpieces.Rook[0].position = 0;
    pos.blackpieces.Rook[1].position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= 1000); // At least two rooks advantage (2 * 500)
}

test "evaluate position with complete material wipe" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Remove all black pieces except king
    for (&pos.blackpieces.Pawn) |*pawn| {
        pawn.position = 0;
    }
    for (&pos.blackpieces.Knight) |*knight| {
        knight.position = 0;
    }
    for (&pos.blackpieces.Bishop) |*bishop| {
        bishop.position = 0;
    }
    for (&pos.blackpieces.Rook) |*rook| {
        rook.position = 0;
    }
    pos.blackpieces.Queen.position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= 3900); // At least all pieces except king
}

test "evaluate position with pawn structure changes" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Create an imbalanced pawn structure
    pos.whitepieces.Pawn[0].position = 0;
    pos.whitepieces.Pawn[1].position = 0;
    pos.blackpieces.Pawn[7].position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expect(score >= -150 and score <= -50); // Black has one more pawn
}

test "minimax finds a move in checkmate position" {
    // Set up a position where white can checkmate in one move
    // White queen on h7, white rook on g1, black king on h8
    var board = Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.H7;
    board.position.whitepieces.Rook[0].position = c.G1;
    board.position.blackpieces.King.position = c.H8;
    board.position.sidetomove = 0; // White to move

    // Find the best move
    const best_move = findBestMove(board, 2);

    // Verify that a move was found
    try std.testing.expect(best_move != null);

    // Print the move for debugging
    if (best_move) |move| {
        std.debug.print("\nRook position in best move: {}\n", .{move.position.whitepieces.Rook[0].position});
        std.debug.print("Queen position in best move: {}\n", .{move.position.whitepieces.Queen.position});
    }
}

test "evaluate considers piece position" {
    // Create two boards with the same material but different piece positions
    var board1 = Board{ .position = b.Position.emptyboard() };
    var board2 = Board{ .position = b.Position.emptyboard() };

    // Place a white knight in the center (e4) on board1
    board1.position.whitepieces.Knight[0].position = c.E4;

    // Place a white knight on the edge (a1) on board2
    board2.position.whitepieces.Knight[0].position = c.A1;

    // Evaluate both positions
    const score1 = evaluate(board1);
    const score2 = evaluate(board2);

    // The knight in the center should be valued higher
    try std.testing.expect(score1 > score2);
}

test "findBestMoveWithTime returns a valid move" {
    const board = Board{ .position = b.Position.init() };

    // Find best move with a reasonable time limit
    const move = findBestMoveWithTime(board, 2, 500);

    // Should return a valid move
    try std.testing.expect(move != null);
}
