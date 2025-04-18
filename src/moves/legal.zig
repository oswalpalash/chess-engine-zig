const b = @import("../board.zig");
const c = @import("../consts.zig");
const std = @import("std");
const board_helpers = @import("../utils/board_helpers.zig");
const king_moves = @import("./king.zig");
const queen_moves = @import("./queen.zig");
const rook_moves = @import("./rook.zig");
const bishop_moves = @import("./bishop.zig");
const knight_moves = @import("./knight.zig");
const pawn_moves = @import("./pawn.zig");

/// Returns true if the given square bitboard is attacked by any piece of attackerColor.
pub fn isSquareAttacked(square: u64, attackerColor: u8, board: b.Board) bool {
    // King attacks
    const attackerKing = if (attackerColor == 0) board.position.whitepieces.King else board.position.blackpieces.King;
    if (attackerKing.position != 0) {
        const king_row = board_helpers.rowfrombitmap(attackerKing.position);
        const king_col = board_helpers.colfrombitmap(attackerKing.position);
        const square_row = board_helpers.rowfrombitmap(square);
        const square_col = board_helpers.colfrombitmap(square);

        // King can attack squares that are at most 1 square away in any direction
        const row_diff = @abs(@as(i64, @intCast(king_row)) - @as(i64, @intCast(square_row)));
        const col_diff = @abs(@as(i64, @intCast(king_col)) - @as(i64, @intCast(square_col)));

        if (row_diff <= 1 and col_diff <= 1 and (attackerKing.position != square)) {
            return true;
        }
    }

    // Pawn attacks (diagonal only)
    const pawns = if (attackerColor == 0) board.position.whitepieces.Pawn else board.position.blackpieces.Pawn;
    for (pawns) |pawn| {
        if (pawn.position == 0) continue; // Skip captured pawns

        // Get rows and columns
        const pawn_row = board_helpers.rowfrombitmap(pawn.position);
        const pawn_col = board_helpers.colfrombitmap(pawn.position);
        const square_row = board_helpers.rowfrombitmap(square);
        const square_col = board_helpers.colfrombitmap(square);

        if (attackerColor == 0) {
            // White pawns attack diagonally upward: (row+1, col-1) and (row+1, col+1)
            if (pawn_row + 1 == square_row) {
                if (pawn_col - 1 == square_col or pawn_col + 1 == square_col) {
                    return true;
                }
            }
        } else {
            // Black pawns attack diagonally downward: (row-1, col-1) and (row-1, col+1)
            if (pawn_row - 1 == square_row) {
                if (pawn_col - 1 == square_col or pawn_col + 1 == square_col) {
                    return true;
                }
            }
        }
    }

    // Knight attacks
    const knights_array = if (attackerColor == 0) board.position.whitepieces.Knight else board.position.blackpieces.Knight;
    for (knights_array) |knight| {
        if (knight.position == 0) continue;

        const knight_row = board_helpers.rowfrombitmap(knight.position);
        const knight_col = board_helpers.colfrombitmap(knight.position);
        const square_row = board_helpers.rowfrombitmap(square);
        const square_col = board_helpers.colfrombitmap(square);

        // Knight moves in an L-shape: 2 squares in one direction and 1 square perpendicular
        const row_diff = @abs(@as(i64, @intCast(knight_row)) - @as(i64, @intCast(square_row)));
        const col_diff = @abs(@as(i64, @intCast(knight_col)) - @as(i64, @intCast(square_col)));

        if ((row_diff == 2 and col_diff == 1) or (row_diff == 1 and col_diff == 2)) {
            return true;
        }
    }

    // Queen attacks (handles both rook-like and bishop-like moves)
    const attackerQueen = if (attackerColor == 0) board.position.whitepieces.Queen else board.position.blackpieces.Queen;
    if (attackerQueen.position != 0) {
        const queen_row = board_helpers.rowfrombitmap(attackerQueen.position);
        const queen_col = board_helpers.colfrombitmap(attackerQueen.position);
        const square_row = board_helpers.rowfrombitmap(square);
        const square_col = board_helpers.colfrombitmap(square);

        // Check for rook-like moves (same row or column)
        const rook_like = queen_row == square_row or queen_col == square_col;

        // Check for bishop-like moves (diagonal)
        const row_diff_queen = @abs(@as(i64, @intCast(queen_row)) - @as(i64, @intCast(square_row)));
        const col_diff_queen = @abs(@as(i64, @intCast(queen_col)) - @as(i64, @intCast(square_col)));

        const bishop_like = row_diff_queen == col_diff_queen;

        if (rook_like or bishop_like) {
            // Check for obstacles
            const bitmap = board_helpers.bitmapfromboard(board);
            var path_clear = true;

            if (rook_like) {
                if (queen_row == square_row) {
                    // Same row, check columns
                    const min_col = @min(queen_col, square_col);
                    const max_col = @max(queen_col, square_col);

                    // If adjacent, no obstacle
                    if (max_col - min_col <= 1) {
                        return true;
                    }

                    // Check columns between
                    var col: u64 = min_col + 1;
                    while (col < max_col) : (col += 1) {
                        const pos = @as(u64, 1) << @intCast((queen_row - 1) * 8 + (8 - col));
                        if (bitmap & pos != 0) {
                            path_clear = false;
                            break;
                        }
                    }
                } else if (queen_col == square_col) {
                    // Same column, check rows
                    const min_row = @min(queen_row, square_row);
                    const max_row = @max(queen_row, square_row);

                    // If adjacent, no obstacle
                    if (max_row - min_row <= 1) {
                        return true;
                    }

                    // Check rows between
                    var row: u64 = min_row + 1;
                    while (row < max_row) : (row += 1) {
                        const pos = @as(u64, 1) << @intCast((row - 1) * 8 + (8 - queen_col));
                        if (bitmap & pos != 0) {
                            path_clear = false;
                            break;
                        }
                    }
                }
            } else if (bishop_like) {
                // Diagonal move
                const row_direction: i64 = if (queen_row < square_row) 1 else -1;
                const col_direction: i64 = if (queen_col < square_col) 1 else -1;

                // If adjacent, no obstacle
                if (row_diff_queen <= 1 and col_diff_queen <= 1) {
                    return true;
                }

                var r: i64 = @as(i64, @intCast(queen_row)) + row_direction;
                var col_index: i64 = @as(i64, @intCast(queen_col)) + col_direction;

                // Loop until we're one step away from the target square or off the board
                while (true) {
                    // Check if we're off the board
                    if (r < 1 or r > 8 or col_index < 1 or col_index > 8) {
                        path_clear = false;
                        break;
                    }

                    // Calculate the position of this square
                    const pos = @as(u64, 1) << @intCast((r - 1) * 8 + (8 - col_index));

                    // If we've reached the target square, stop checking for obstacles
                    if (r == square_row and col_index == square_col) {
                        break;
                    }

                    // Check if there's a piece on this square (not the target square)
                    if (bitmap & pos != 0) {
                        path_clear = false;
                        break;
                    }

                    // Move one more step along the diagonal
                    r += row_direction;
                    col_index += col_direction;
                }
            }

            if (path_clear) {
                return true;
            }
        }
    }

    // Rook attacks
    const rooks_array = if (attackerColor == 0) board.position.whitepieces.Rook else board.position.blackpieces.Rook;
    for (rooks_array) |rook| {
        if (rook.position == 0) continue; // Skip captured rooks

        // Check if the rook and the square are on the same row or column
        const rook_row = board_helpers.rowfrombitmap(rook.position);
        const rook_col = board_helpers.colfrombitmap(rook.position);
        const square_row = board_helpers.rowfrombitmap(square);
        const square_col = board_helpers.colfrombitmap(square);

        // If they're on the same row or column, check for obstacles between them
        if (rook_row == square_row or rook_col == square_col) {
            // Check if there are any pieces between the rook and the square
            const bitmap = board_helpers.bitmapfromboard(board);
            var path_clear = true;

            if (rook_row == square_row) {
                // Same row, check columns between
                const min_col = @min(rook_col, square_col);
                const max_col = @max(rook_col, square_col);

                // If they're adjacent, there's no obstacle
                if (max_col - min_col <= 1) {
                    return true;
                }

                // Check columns between
                var col: u64 = min_col + 1;
                while (col < max_col) : (col += 1) {
                    // Calculate the position of this square
                    const pos = @as(u64, 1) << @intCast((rook_row - 1) * 8 + (8 - col));
                    if (bitmap & pos != 0) {
                        path_clear = false;
                        break;
                    }
                }
            } else if (rook_col == square_col) {
                // Same column, check rows between
                const min_row = @min(rook_row, square_row);
                const max_row = @max(rook_row, square_row);

                // If they're adjacent, there's no obstacle
                if (max_row - min_row <= 1) {
                    return true;
                }

                // Check rows between
                var row: u64 = min_row + 1;
                while (row < max_row) : (row += 1) {
                    // Calculate the position of this square
                    const pos = @as(u64, 1) << @intCast((row - 1) * 8 + (8 - rook_col));
                    if (bitmap & pos != 0) {
                        path_clear = false;
                        break;
                    }
                }
            }

            if (path_clear) {
                return true;
            }
        }
    }

    // Bishop attacks
    const bishops_array = if (attackerColor == 0) board.position.whitepieces.Bishop else board.position.blackpieces.Bishop;
    for (bishops_array) |bishop| {
        if (bishop.position == 0) continue;

        // Check if the bishop and square are on the same diagonal
        const bishop_row = board_helpers.rowfrombitmap(bishop.position);
        const bishop_col = board_helpers.colfrombitmap(bishop.position);
        const square_row = board_helpers.rowfrombitmap(square);
        const square_col = board_helpers.colfrombitmap(square);

        // Bishops move on diagonals, so the absolute difference between row and column must be equal
        const row_diff = @abs(@as(i64, @intCast(bishop_row)) - @as(i64, @intCast(square_row)));
        const col_diff = @abs(@as(i64, @intCast(bishop_col)) - @as(i64, @intCast(square_col)));

        if (row_diff == col_diff) {
            // They are on the same diagonal, now check for obstacles
            const bitmap = board_helpers.bitmapfromboard(board);
            var path_clear = true;

            // Determine the direction
            const row_direction: i64 = if (bishop_row < square_row) 1 else -1;
            const col_direction: i64 = if (bishop_col < square_col) 1 else -1;

            // If they're adjacent, there's no obstacle
            if (row_diff <= 1) {
                return true;
            }

            var r: i64 = @as(i64, @intCast(bishop_row)) + row_direction;
            var col_index: i64 = @as(i64, @intCast(bishop_col)) + col_direction;

            // Loop until we're one step away from the target square or off the board
            while (true) {
                // Check if we're off the board
                if (r < 1 or r > 8 or col_index < 1 or col_index > 8) {
                    path_clear = false;
                    break;
                }

                // Calculate the position of this square
                const pos = @as(u64, 1) << @intCast((r - 1) * 8 + (8 - col_index));

                // If we've reached the target square, stop checking for obstacles
                if (r == square_row and col_index == square_col) {
                    break;
                }

                // Check if there's a piece on this square
                if (bitmap & pos != 0) {
                    path_clear = false;
                    break;
                }

                // Move one more step along the diagonal
                r += row_direction;
                col_index += col_direction;
            }

            if (path_clear) {
                return true;
            }
        }
    }

    return false;
}

/// Returns true if the king of kingColor is currently in check.
pub fn isKingInCheck(kingColor: u8, board: b.Board) bool {
    const kingPos = if (kingColor == 0) board.position.whitepieces.King.position else board.position.blackpieces.King.position;
    const attacker: u8 = kingColor ^ 1;
    return isSquareAttacked(kingPos, attacker, board);
}

/// Generates all legal moves for the side to move, filtering out those that leave the king in check.
pub fn getLegalMoves(colorToMove: u8, board: b.Board) []b.Board {
    var legal: [1024]b.Board = undefined;
    var count: usize = 0;
    const opponent: u8 = colorToMove ^ 1;

    // King moves
    if (colorToMove == 0) {
        for (king_moves.getValidKingMoves(board.position.whitepieces.King, board)) |nb_orig| {
            var nb = nb_orig; // Make mutable copy
            // Castling cannot pass through check
            const kDest = nb.position.whitepieces.King.position;
            if (kDest == c.G1) {
                if (isSquareAttacked(c.E1, opponent, board) or isSquareAttacked(c.F1, opponent, board)) continue;
            }
            // Update board state *before* check
            nb.move_count = board.move_count + 1;
            nb.sidetomove = opponent;
            if (!isKingInCheck(0, nb)) {
                legal[count] = nb;
                count += 1;
            }
        }
    } else {
        for (king_moves.getValidKingMoves(board.position.blackpieces.King, board)) |nb_orig| {
            var nb = nb_orig; // Make mutable copy
            const kDest = nb.position.blackpieces.King.position;
            if (kDest == c.G8) {
                if (isSquareAttacked(c.E8, opponent, board) or isSquareAttacked(c.F8, opponent, board)) continue;
            }
            // Update board state *before* check
            nb.move_count = board.move_count + 1;
            nb.sidetomove = opponent;
            if (!isKingInCheck(1, nb)) {
                legal[count] = nb;
                count += 1;
            }
        }
    }

    // If king is in check, only consider moves that resolve the check
    // Other pieces' moves

    // Queen moves
    if (colorToMove == 0) {
        for (queen_moves.getValidQueenMoves(board.position.whitepieces.Queen, board)) |nb_orig| {
            var nb = nb_orig; // Make mutable copy
            nb.move_count = board.move_count + 1;
            nb.sidetomove = opponent;
            // The king must not be in check after the move
            if (!isKingInCheck(0, nb)) {
                legal[count] = nb;
                count += 1;
            }
        }
    } else {
        for (queen_moves.getValidQueenMoves(board.position.blackpieces.Queen, board)) |nb_orig| {
            var nb = nb_orig; // Make mutable copy
            nb.move_count = board.move_count + 1;
            nb.sidetomove = opponent;
            if (!isKingInCheck(1, nb)) {
                legal[count] = nb;
                count += 1;
            }
        }
    }

    // Rook moves
    if (colorToMove == 0) {
        for (board.position.whitepieces.Rook) |rook| {
            for (rook_moves.getValidRookMoves(rook, board)) |nb_orig| {
                var nb = nb_orig; // Make mutable copy
                nb.move_count = board.move_count + 1;
                nb.sidetomove = opponent;
                if (!isKingInCheck(0, nb)) {
                    legal[count] = nb;
                    count += 1;
                }
            }
        }
    } else {
        for (board.position.blackpieces.Rook) |rook| {
            for (rook_moves.getValidRookMoves(rook, board)) |nb_orig| {
                var nb = nb_orig; // Make mutable copy
                nb.move_count = board.move_count + 1;
                nb.sidetomove = opponent;
                if (!isKingInCheck(1, nb)) {
                    legal[count] = nb;
                    count += 1;
                }
            }
        }
    }

    // Bishop moves
    if (colorToMove == 0) {
        for (board.position.whitepieces.Bishop) |bishop| {
            for (bishop_moves.getValidBishopMoves(bishop, board)) |nb_orig| {
                var nb = nb_orig; // Make mutable copy
                nb.move_count = board.move_count + 1;
                nb.sidetomove = opponent;
                if (!isKingInCheck(0, nb)) {
                    legal[count] = nb;
                    count += 1;
                }
            }
        }
    } else {
        for (board.position.blackpieces.Bishop) |bishop| {
            for (bishop_moves.getValidBishopMoves(bishop, board)) |nb_orig| {
                var nb = nb_orig; // Make mutable copy
                nb.move_count = board.move_count + 1;
                nb.sidetomove = opponent;
                if (!isKingInCheck(1, nb)) {
                    legal[count] = nb;
                    count += 1;
                }
            }
        }
    }

    // Knight moves
    if (colorToMove == 0) {
        for (board.position.whitepieces.Knight) |knight| {
            for (knight_moves.getValidKnightMoves(knight, board)) |nb_orig| {
                var nb = nb_orig; // Make mutable copy
                nb.move_count = board.move_count + 1;
                nb.sidetomove = opponent;
                if (!isKingInCheck(0, nb)) {
                    legal[count] = nb;
                    count += 1;
                }
            }
        }
    } else {
        for (board.position.blackpieces.Knight) |knight| {
            for (knight_moves.getValidKnightMoves(knight, board)) |nb_orig| {
                var nb = nb_orig; // Make mutable copy
                nb.move_count = board.move_count + 1;
                nb.sidetomove = opponent;
                if (!isKingInCheck(1, nb)) {
                    legal[count] = nb;
                    count += 1;
                }
            }
        }
    }

    // Pawn moves
    if (colorToMove == 0) {
        for (board.position.whitepieces.Pawn) |pawn| {
            if (pawn.position == 0) continue;
            for (pawn_moves.getValidPawnMoves(pawn, board)) |nb_orig| {
                var nb = nb_orig; // Make mutable copy
                nb.move_count = board.move_count + 1;
                nb.sidetomove = opponent;

                // Verify king is not in check after this move
                const kingStillInCheck = isKingInCheck(0, nb);

                // Only add the move if it resolves the check
                if (!kingStillInCheck) {
                    legal[count] = nb;
                    count += 1;
                }
            }
        }
    } else {
        for (board.position.blackpieces.Pawn) |pawn| {
            if (pawn.position == 0) continue;
            for (pawn_moves.getValidPawnMoves(pawn, board)) |nb_orig| {
                var nb = nb_orig; // Make mutable copy
                nb.move_count = board.move_count + 1;
                nb.sidetomove = opponent;

                // Verify king is not in check after this move
                const kingStillInCheck = isKingInCheck(1, nb);

                // Only add the move if it resolves the check
                if (!kingStillInCheck) {
                    legal[count] = nb;
                    count += 1;
                }
            }
        }
    }

    return legal[0..count];
}

test "isSquareAttacked - empty board" {
    const board = b.Board{ .position = b.Position.emptyboard() };
    try std.testing.expect(!isSquareAttacked(c.E4, 0, board)); // White attacking e4
    try std.testing.expect(!isSquareAttacked(c.E4, 1, board)); // Black attacking e4
}

test "isSquareAttacked - white rook attacks" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.A1;
    try std.testing.expect(isSquareAttacked(c.A8, 0, board)); // White rook attacks A8
    try std.testing.expect(isSquareAttacked(c.H1, 0, board)); // White rook attacks H1
    try std.testing.expect(!isSquareAttacked(c.B2, 0, board)); // White rook does not attack B2
    try std.testing.expect(!isSquareAttacked(c.A1, 1, board)); // Black does not attack A1
}

test "isSquareAttacked - black knight attacks" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Knight[0].position = c.G8;
    try std.testing.expect(isSquareAttacked(c.F6, 1, board)); // Black knight attacks F6
    try std.testing.expect(isSquareAttacked(c.H6, 1, board)); // Black knight attacks H6
    try std.testing.expect(isSquareAttacked(c.E7, 1, board)); // Black knight attacks E7
    try std.testing.expect(!isSquareAttacked(c.G7, 1, board)); // Black knight does not attack G7
    try std.testing.expect(!isSquareAttacked(c.F6, 0, board)); // White does not attack F6
}

test "isSquareAttacked - pawn attacks" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E4;
    board.position.blackpieces.Pawn[0].position = c.D5;
    try std.testing.expect(isSquareAttacked(c.D5, 0, board)); // White pawn attacks D5
    try std.testing.expect(isSquareAttacked(c.F5, 0, board)); // White pawn attacks F5
    try std.testing.expect(!isSquareAttacked(c.E5, 0, board)); // White pawn does not attack E5 (forward)
    try std.testing.expect(isSquareAttacked(c.C4, 1, board)); // Black pawn attacks C4
    try std.testing.expect(isSquareAttacked(c.E4, 1, board)); // Black pawn attacks E4
    try std.testing.expect(!isSquareAttacked(c.D4, 1, board)); // Black pawn does not attack D4 (forward)
}

test "isKingInCheck - initial position" {
    const board = b.Board{ .position = b.Position.init() };
    try std.testing.expect(!isKingInCheck(0, board)); // White king not in check
    try std.testing.expect(!isKingInCheck(1, board)); // Black king not in check
}

test "isKingInCheck - white king in check" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E1;
    board.position.blackpieces.Rook[0].position = c.E8;
    try std.testing.expect(isKingInCheck(0, board));
    try std.testing.expect(!isKingInCheck(1, board));
}

test "isKingInCheck - black king in check" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E8;
    board.position.whitepieces.Queen.position = c.H5;
    try std.testing.expect(isKingInCheck(1, board)); // Scholar's mate check
    try std.testing.expect(!isKingInCheck(0, board));
}

test "getLegalMoves - initial position" {
    const board = b.Board{ .position = b.Position.init(), .sidetomove = 0 };
    const moves = getLegalMoves(0, board);
    // White has 20 possible moves: 8 pawns * 2 moves + 2 knights * 2 moves
    try std.testing.expectEqual(@as(usize, 20), moves.len);
}

// Test checkmate scenario - King has no legal moves
test "getLegalMoves - checkmate" {
    // Fool's Mate setup with standard position
    var board = b.Board{ .position = b.Position.init(), .sidetomove = 0 };

    // Modify white pieces that moved
    board.position.whitepieces.Pawn[5].position = c.F3; // White f pawn to f3
    board.position.whitepieces.Pawn[6].position = c.G4; // White g pawn to g4

    // Modify black pieces that moved
    board.position.blackpieces.Pawn[4].position = c.E5; // Black e pawn to e5
    board.position.blackpieces.Queen.position = c.H4; // Black queen to h4 (checkmate)

    // Make sure the king is still at E1
    board.position.whitepieces.King.position = c.E1;

    // Print the board for debugging
    std.debug.print("\nFool's Mate position for checkmate test:\n", .{});
    _ = board.print();

    // Verify the king is in check
    const isChecked = isKingInCheck(0, board);
    std.debug.print("White king in check: {}\n", .{isChecked});

    // Get legal moves for white (should be none)
    const moves = getLegalMoves(0, board);
    std.debug.print("Number of legal moves: {}\n", .{moves.len});

    // If there are moves, print them for debugging
    if (moves.len > 0) {
        std.debug.print("Unexpected legal moves found:\n", .{});
        for (moves, 0..) |move, i| {
            std.debug.print("Move {}: ", .{i + 1});
            _ = move.print();
        }
    }

    // There should be no legal moves in a checkmate position
    try std.testing.expectEqual(@as(usize, 0), moves.len);
}

// Test pinned piece - Rook pinned to king cannot move along the pin axis
test "getLegalMoves - pinned piece" {
    var board = b.Board{ .position = b.Position.emptyboard(), .sidetomove = 0 };
    board.position.whitepieces.King.position = c.E1;
    board.position.whitepieces.Rook[0].position = c.E2;
    board.position.blackpieces.Rook[0].position = c.E8;

    const moves = getLegalMoves(0, board); // Get white's moves

    var rookMovedAlongPin = false;
    for (moves) |move| {
        const newRookPos = move.position.whitepieces.Rook[0].position;
        // Check if rook moved horizontally (which would be illegal)
        if (newRookPos == c.D2 or newRookPos == c.F2) {
            rookMovedAlongPin = true;
            break;
        }
    }
    try std.testing.expect(!rookMovedAlongPin);

    // Check that the rook can still move along the E-file (capture or block)
    var rookMovedVertically = false;
    for (moves) |move| {
        const newRookPos = move.position.whitepieces.Rook[0].position;
        if (newRookPos == c.E3 or newRookPos == c.E4 or newRookPos == c.E5 or newRookPos == c.E6 or newRookPos == c.E7 or newRookPos == c.E8) {
            rookMovedVertically = true;
            break;
        }
    }
    try std.testing.expect(rookMovedVertically);
}

// Test castling through check is illegal
test "getLegalMoves - castling through check" {
    var board = b.Board{ .position = b.Position.emptyboard(), .sidetomove = 0 };
    board.position.whitepieces.King.position = c.E1;
    board.position.whitepieces.Rook[1].position = c.H1;
    board.position.blackpieces.Rook[0].position = c.F8; // Attacks f1
    board.position.canCastleWhiteKingside = true;

    const moves = getLegalMoves(0, board);
    var foundCastling = false;
    for (moves) |move| {
        if (move.position.whitepieces.King.position == c.G1) {
            foundCastling = true;
            break;
        }
    }
    try std.testing.expect(!foundCastling); // Kingside castling should be illegal
}

// Test checkmate scenario with debugging
test "diagnosis_queen_attack" {
    // Set up a simplified position with just a queen and king
    var board = b.Board{ .position = b.Position.emptyboard(), .sidetomove = 0 };

    // Place black queen at h4
    board.position.blackpieces.Queen.position = c.H4;

    // Place white king at e1
    board.position.whitepieces.King.position = c.E1;

    // Print the board
    std.debug.print("\nSimplified position for queen attack diagnosis:\n", .{});
    _ = board.print();

    // Determine coordinates
    const queen_row = board_helpers.rowfrombitmap(c.H4);
    const queen_col = board_helpers.colfrombitmap(c.H4);
    const king_row = board_helpers.rowfrombitmap(c.E1);
    const king_col = board_helpers.colfrombitmap(c.E1);

    std.debug.print("Queen at h4: row {}, col {}\n", .{ queen_row, queen_col });
    std.debug.print("King at e1: row {}, col {}\n", .{ king_row, king_col });

    // Check row and column differences
    const row_diff = @abs(@as(i64, @intCast(queen_row)) - @as(i64, @intCast(king_row)));
    const col_diff = @abs(@as(i64, @intCast(queen_col)) - @as(i64, @intCast(king_col)));

    std.debug.print("Row diff: {}, Col diff: {}, Is diagonal: {}\n", .{ row_diff, col_diff, row_diff == col_diff });

    // Figure out the diagonal path
    const row_direction: i64 = if (queen_row < king_row) 1 else -1;
    const col_direction: i64 = if (queen_col < king_col) 1 else -1;

    std.debug.print("Row direction: {}, Col direction: {}\n", .{ row_direction, col_direction });

    // Trace the path
    var r: i64 = @as(i64, @intCast(queen_row));
    var col_pos: i64 = @as(i64, @intCast(queen_col));

    std.debug.print("Tracing diagonal path:\n", .{});
    std.debug.print("({}, {}) - starting at queen position\n", .{ r, col_pos });

    var step: i64 = 1;
    while (true) {
        r += row_direction;
        col_pos += col_direction;
        std.debug.print("Step {}: ({}, {})", .{ step, r, col_pos });

        if (r < 1 or r > 8 or col_pos < 1 or col_pos > 8) {
            std.debug.print(" - off board\n", .{});
            break;
        }

        // Calculate bit position and check if there's a piece here
        const pos = @as(u64, 1) << @intCast((r - 1) * 8 + (8 - col_pos));
        const bitmap = board_helpers.bitmapfromboard(board);
        if (bitmap & pos != 0) {
            std.debug.print(" - piece found at position\n", .{});
            break;
        }

        if (r == king_row and col_pos == king_col) {
            std.debug.print(" - reached king!\n", .{});
            break;
        }

        std.debug.print("\n", .{});
        step += 1;
    }

    // Test if the square is attacked
    const is_attacked = isSquareAttacked(c.E1, 1, board);
    std.debug.print("\nIs king square attacked by queen? {}\n", .{is_attacked});

    // Use the new check with expected result
    try std.testing.expect(is_attacked);
}

// Test the specific pawn move in the fool's mate position
test "h2_pawn_move_in_fools_mate" {
    // Set up the fool's mate position
    var board = b.Board{ .position = b.Position.init(), .sidetomove = 0 };

    // Modify white pieces that moved
    board.position.whitepieces.Pawn[5].position = c.F3; // White f pawn to f3
    board.position.whitepieces.Pawn[6].position = c.G4; // White g pawn to g4

    // Modify black pieces that moved
    board.position.blackpieces.Pawn[4].position = c.E5; // Black e pawn to e5
    board.position.blackpieces.Queen.position = c.H4; // Black queen to h4 (checkmate)

    // Make sure the king is still at E1
    board.position.whitepieces.King.position = c.E1;

    // Print the board
    std.debug.print("\nFool's mate position for h2-h3 test:\n", .{});
    _ = board.print();

    // Check if the king is in check
    const king_in_check = isKingInCheck(0, board);
    std.debug.print("King in check: {}\n", .{king_in_check});

    // Create a new board with the h2-h3 move
    var h_pawn_move_board = board;
    h_pawn_move_board.position.whitepieces.Pawn[7].position = c.H3; // Move h pawn to h3

    // Print the board after h2-h3
    std.debug.print("\nAfter h2-h3 move:\n", .{});
    _ = h_pawn_move_board.print();

    // Check if the king is still in check after the move
    const king_still_in_check = isKingInCheck(0, h_pawn_move_board);
    std.debug.print("King still in check: {}\n", .{king_still_in_check});

    // Analyze the attack path after the pawn move
    const king_pos = h_pawn_move_board.position.whitepieces.King.position;
    const queen_pos = h_pawn_move_board.position.blackpieces.Queen.position;
    const h_pawn_pos = h_pawn_move_board.position.whitepieces.Pawn[7].position;

    std.debug.print("\nPositions (bitboard values):\n", .{});
    std.debug.print("King at E1: {}\n", .{king_pos});
    std.debug.print("Queen at H4: {}\n", .{queen_pos});
    std.debug.print("H pawn at H3: {}\n", .{h_pawn_pos});

    // This move should not block the check, so the king should still be in check
    try std.testing.expect(king_still_in_check);
}
