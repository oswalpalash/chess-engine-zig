const b = @import("board.zig");
const c = @import("consts.zig");
const m = @import("moves.zig");
const std = @import("std");

// isCheck determines if the given board position has the king in check
// It does this by checking if any enemy piece can capture the king in the next move
pub fn isCheck(board: b.Board, isWhite: bool) bool {
    // Get the king's position based on color
    const kingPosition = if (isWhite) board.position.whitepieces.King.position else board.position.blackpieces.King.position;

    // For each enemy piece, check if it can capture the king
    // For white king in check, check all black pieces
    if (isWhite) {
        // Check black pawns
        for (board.position.blackpieces.Pawn) |pawn| {
            if (pawn.position == 0) continue;
            // Black pawns capture diagonally downward
            const captureLeft = pawn.position >> 9;
            const captureRight = pawn.position >> 7;
            if (captureLeft == kingPosition or captureRight == kingPosition) {
                return true;
            }
        }

        // Check black knights
        for (board.position.blackpieces.Knight) |knight| {
            if (knight.position == 0) continue;
            // Knight moves are special - check all possible knight moves from king position
            // and see if they intersect with enemy knight position
            const knightMoves = [8]u64{
                kingPosition << 6, // Up 1, Left 2
                kingPosition << 10, // Up 1, Right 2
                kingPosition << 15, // Up 2, Left 1
                kingPosition << 17, // Up 2, Right 1
                kingPosition >> 6, // Down 1, Right 2
                kingPosition >> 10, // Down 1, Left 2
                kingPosition >> 15, // Down 2, Right 1
                kingPosition >> 17, // Down 2, Left 1
            };
            for (knightMoves) |move| {
                if (move == knight.position) {
                    return true;
                }
            }
        }

        // Check black bishops
        for (board.position.blackpieces.Bishop) |bishop| {
            if (bishop.position == 0) continue;
            const moves = m.ValidBishopMoves(bishop, board);
            for (moves) |move| {
                if (move.position.blackpieces.Bishop[0].position == kingPosition) {
                    return true;
                }
            }
        }

        // Check black rooks
        for (board.position.blackpieces.Rook) |rook| {
            if (rook.position == 0) continue;
            const moves = m.ValidRookMoves(rook, board);
            for (moves) |move| {
                if (move.position.blackpieces.Rook[0].position == kingPosition) {
                    return true;
                }
            }
        }

        // Check black queen
        if (board.position.blackpieces.Queen.position != 0) {
            const moves = m.ValidQueenMoves(board.position.blackpieces.Queen, board);
            for (moves) |move| {
                if (move.position.blackpieces.Queen.position == kingPosition) {
                    return true;
                }
            }
        }
    } else {
        // For black king in check, check all white pieces
        // Check white pawns
        for (board.position.whitepieces.Pawn) |pawn| {
            if (pawn.position == 0) continue;
            // White pawns capture diagonally upward
            const captureLeft = pawn.position << 7;
            const captureRight = pawn.position << 9;
            if (captureLeft == kingPosition or captureRight == kingPosition) {
                return true;
            }
        }

        // Check white knights
        for (board.position.whitepieces.Knight) |knight| {
            if (knight.position == 0) continue;
            // Knight moves are special - check all possible knight moves from king position
            // and see if they intersect with enemy knight position
            const knightMoves = [8]u64{
                kingPosition << 6, // Up 1, Left 2
                kingPosition << 10, // Up 1, Right 2
                kingPosition << 15, // Up 2, Left 1
                kingPosition << 17, // Up 2, Right 1
                kingPosition >> 6, // Down 1, Right 2
                kingPosition >> 10, // Down 1, Left 2
                kingPosition >> 15, // Down 2, Right 1
                kingPosition >> 17, // Down 2, Left 1
            };
            for (knightMoves) |move| {
                if (move == knight.position) {
                    return true;
                }
            }
        }

        // Check white bishops
        for (board.position.whitepieces.Bishop) |bishop| {
            if (bishop.position == 0) continue;
            const moves = m.ValidBishopMoves(bishop, board);
            for (moves) |move| {
                if (move.position.whitepieces.Bishop[0].position == kingPosition) {
                    return true;
                }
            }
        }

        // Check white rooks
        for (board.position.whitepieces.Rook) |rook| {
            if (rook.position == 0) continue;
            const moves = m.ValidRookMoves(rook, board);
            for (moves) |move| {
                if (move.position.whitepieces.Rook[0].position == kingPosition) {
                    return true;
                }
            }
        }

        // Check white queen
        if (board.position.whitepieces.Queen.position != 0) {
            const moves = m.ValidQueenMoves(board.position.whitepieces.Queen, board);
            for (moves) |move| {
                if (move.position.whitepieces.Queen.position == kingPosition) {
                    return true;
                }
            }
        }
    }

    return false;
}

test "isCheck - initial board position is not check" {
    const board = b.Board{ .position = b.Position.init() };
    try std.testing.expect(!isCheck(board, true)); // White king not in check
    try std.testing.expect(!isCheck(board, false)); // Black king not in check
}

test "isCheck - white king in check by black queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Place white king on e1
    board.position.whitepieces.King.position = c.E1;
    // Place black queen on e8
    board.position.blackpieces.Queen.position = c.E8;

    // Print board state
    _ = board.print();

    // Create temp board for queen moves
    var tempBoard = b.Board{ .position = b.Position.emptyboard() };
    tempBoard.position.blackpieces.Queen = board.position.blackpieces.Queen;
    tempBoard.position.whitepieces.King = board.position.whitepieces.King;

    // Print queen moves
    const moves = m.ValidQueenMoves(board.position.blackpieces.Queen, tempBoard);
    for (moves) |move| {
        _ = move.print();
    }

    try std.testing.expect(isCheck(board, true));
}

test "isCheck - black king in check by white pawn" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Place black king on e8
    board.position.blackpieces.King.position = c.E8;
    // Place white pawn on d7
    board.position.whitepieces.Pawn[3].position = c.D7;
    try std.testing.expect(isCheck(board, false));
}

test "isCheck - white king in check by black knight" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Place white king on e4
    board.position.whitepieces.King.position = c.E4;
    // Place black knight on f6 (can attack e4)
    board.position.blackpieces.Knight[0].position = c.F6;
    try std.testing.expect(isCheck(board, true));
}

test "isCheck - black king in check by white bishop" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Place black king on e8
    board.position.blackpieces.King.position = c.E8;
    // Place white bishop on a4 (can attack e8)
    board.position.whitepieces.Bishop[0].position = c.A4;
    try std.testing.expect(isCheck(board, false));
}

test "isCheck - blocked check is not check" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Place white king on e1
    board.position.whitepieces.King.position = c.E1;
    // Place black queen on e8
    board.position.blackpieces.Queen.position = c.E8;
    // Place white pawn on e2 blocking the check
    board.position.whitepieces.Pawn[4].position = c.E2;
    try std.testing.expect(!isCheck(board, true));
}
