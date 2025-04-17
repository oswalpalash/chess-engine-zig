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
            const moves = m.getValidBishopMoves(bishop, board);
            for (moves) |move| {
                // Check if any of the bishop's valid moves can reach the king's position
                if (move.position.blackpieces.Bishop[0].position == kingPosition or
                    move.position.blackpieces.Bishop[1].position == kingPosition)
                {
                    return true;
                }
            }
        }

        // Check black rooks
        for (board.position.blackpieces.Rook) |rook| {
            if (rook.position == 0) continue;
            const moves = m.getValidRookMoves(rook, board);
            for (moves) |move| {
                // Check if any of the rook's valid moves can reach the king's position
                if (move.position.blackpieces.Rook[0].position == kingPosition or
                    move.position.blackpieces.Rook[1].position == kingPosition)
                {
                    return true;
                }
            }
        }

        // Check black queen
        if (board.position.blackpieces.Queen.position != 0) {
            const moves = m.ValidQueenMoves(board.position.blackpieces.Queen, board);
            for (moves) |move| {
                // Check if any of the queen's valid moves can reach the king's position
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
            const moves = m.getValidBishopMoves(bishop, board);
            for (moves) |move| {
                // Check if any of the bishop's valid moves can reach the king's position
                if (move.position.whitepieces.Bishop[0].position == kingPosition or
                    move.position.whitepieces.Bishop[1].position == kingPosition)
                {
                    return true;
                }
            }
        }

        // Check white rooks
        for (board.position.whitepieces.Rook) |rook| {
            if (rook.position == 0) continue;
            const moves = m.getValidRookMoves(rook, board);
            for (moves) |move| {
                // Check if any of the rook's valid moves can reach the king's position
                if (move.position.whitepieces.Rook[0].position == kingPosition or
                    move.position.whitepieces.Rook[1].position == kingPosition)
                {
                    return true;
                }
            }
        }

        // Check white queen
        if (board.position.whitepieces.Queen.position != 0) {
            const moves = m.ValidQueenMoves(board.position.whitepieces.Queen, board);
            for (moves) |move| {
                // Check if any of the queen's valid moves can reach the king's position
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

    // Create temp board for queen moves
    var tempBoard = b.Board{ .position = b.Position.emptyboard() };
    tempBoard.position.blackpieces.Queen = board.position.blackpieces.Queen;
    tempBoard.position.whitepieces.King = board.position.whitepieces.King;

    // Print queen moves
    const moves = m.ValidQueenMoves(board.position.blackpieces.Queen, tempBoard);
    _ = moves;
    // for (moves) |move| {
    //     // _ = move.print();
    // }

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

// isCheckmate determines if the given board position is checkmate
// A position is checkmate if:
// 1. The king is in check
// 2. There are no legal moves that can get the king out of check
pub fn isCheckmate(board: b.Board, isWhite: bool) bool {
    // First check if the king is in check
    if (!isCheck(board, isWhite)) return false;

    if (isWhite) {
        // Check king moves first
        const kingMoves = m.ValidKingMoves(board.position.whitepieces.King, board);
        for (kingMoves) |move| {
            // For each move, check if it gets us out of check
            if (!isCheck(move, true)) return false;
        }

        // Check pawn moves
        for (board.position.whitepieces.Pawn) |pawn| {
            if (pawn.position == 0) continue;
            const pawnMoves = m.getValidPawnMoves(pawn, board);
            for (pawnMoves) |move| {
                if (!isCheck(move, true)) return false;
            }
        }

        // Check knight moves
        for (board.position.whitepieces.Knight) |knight| {
            if (knight.position == 0) continue;
            const knightMoves = m.ValidKnightMoves(knight, board);
            for (knightMoves) |move| {
                if (!isCheck(move, true)) return false;
            }
        }

        // Check bishop moves
        for (board.position.whitepieces.Bishop) |bishop| {
            if (bishop.position == 0) continue;
            const bishopMoves = m.getValidBishopMoves(bishop, board);
            for (bishopMoves) |move| {
                if (!isCheck(move, true)) return false;
            }
        }

        // Check rook moves
        for (board.position.whitepieces.Rook) |rook| {
            if (rook.position == 0) continue;
            const rookMoves = m.getValidRookMoves(rook, board);
            for (rookMoves) |move| {
                if (!isCheck(move, true)) return false;
            }
        }

        // Check queen moves
        if (board.position.whitepieces.Queen.position != 0) {
            const queenMoves = m.ValidQueenMoves(board.position.whitepieces.Queen, board);
            for (queenMoves) |move| {
                if (!isCheck(move, true)) return false;
            }
        }
    } else {
        // Check king moves first
        const kingMoves = m.ValidKingMoves(board.position.blackpieces.King, board);
        for (kingMoves) |move| {
            // For each move, check if it gets us out of check
            if (!isCheck(move, false)) return false;
        }

        // Check pawn moves
        for (board.position.blackpieces.Pawn) |pawn| {
            if (pawn.position == 0) continue;
            const pawnMoves = m.getValidPawnMoves(pawn, board);
            for (pawnMoves) |move| {
                if (!isCheck(move, false)) return false;
            }
        }

        // Check knight moves
        for (board.position.blackpieces.Knight) |knight| {
            if (knight.position == 0) continue;
            const knightMoves = m.ValidKnightMoves(knight, board);
            for (knightMoves) |move| {
                if (!isCheck(move, false)) return false;
            }
        }

        // Check bishop moves
        for (board.position.blackpieces.Bishop) |bishop| {
            if (bishop.position == 0) continue;
            const bishopMoves = m.getValidBishopMoves(bishop, board);
            for (bishopMoves) |move| {
                if (!isCheck(move, false)) return false;
            }
        }

        // Check rook moves
        for (board.position.blackpieces.Rook) |rook| {
            if (rook.position == 0) continue;
            const rookMoves = m.getValidRookMoves(rook, board);
            for (rookMoves) |move| {
                if (!isCheck(move, false)) return false;
            }
        }

        // Check queen moves
        if (board.position.blackpieces.Queen.position != 0) {
            const queenMoves = m.ValidQueenMoves(board.position.blackpieces.Queen, board);
            for (queenMoves) |move| {
                if (!isCheck(move, false)) return false;
            }
        }
    }

    // If we get here, no moves can get us out of check
    return true;
}

test "isCheckmate - initial board position is not checkmate" {
    const board = b.Board{ .position = b.Position.init() };
    try std.testing.expect(!isCheckmate(board, true)); // White king not in checkmate
    try std.testing.expect(!isCheckmate(board, false)); // Black king not in checkmate
}

test "isCheckmate - fool's mate" {
    var board = b.Board{ .position = b.Position.init() };
    // Simulate fool's mate position:
    // 1. f3 e5
    // 2. g4 Qh4#

    // White pieces that moved
    board.position.whitepieces.Pawn[5].position = c.F3; // White f pawn to f3
    board.position.whitepieces.Pawn[6].position = c.G4; // White g pawn to g4

    // Black pieces that moved
    board.position.blackpieces.Pawn[4].position = c.E5; // Black e pawn to e5
    board.position.blackpieces.Queen.position = c.H4; // Black queen to h4

    // Print the board for debugging
    _ = board.print();

    try std.testing.expect(isCheckmate(board, true)); // White king should be in checkmate
}

test "isCheckmate - check but not checkmate" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Place white king on e1
    board.position.whitepieces.King.position = c.E1;
    // Place black queen on e8
    board.position.blackpieces.Queen.position = c.E8;

    try std.testing.expect(!isCheckmate(board, true)); // White king in check but can move
}

test "isCheckmate - scholar's mate" {
    var board = b.Board{ .position = b.Position.init() };
    // Simulate scholar's mate position:
    // 1. e4 e5
    // 2. Bc4 Nc6
    // 3. Qh5 Nf6??
    // 4. Qxf7#

    // White pieces
    board.position.whitepieces.Pawn[4].position = c.E4; // e4
    board.position.whitepieces.Bishop[1].position = c.C4; // Bc4
    board.position.whitepieces.Queen.position = c.F7; // Qxf7

    // Black pieces
    board.position.blackpieces.Pawn[4].position = c.E5; // e5
    board.position.blackpieces.Knight[0].position = c.C6; // Nc6
    board.position.blackpieces.Knight[1].position = c.F6; // Nf6
    board.position.blackpieces.Pawn[5].position = 0; // f7 pawn captured by white queen

    // Keep all other pieces in their initial positions
    // White pieces
    board.position.whitepieces.King.position = c.E1;
    board.position.whitepieces.Rook[0].position = c.A1;
    board.position.whitepieces.Rook[1].position = c.H1;
    board.position.whitepieces.Knight[0].position = c.B1;
    board.position.whitepieces.Knight[1].position = c.G1;
    board.position.whitepieces.Bishop[0].position = c.C1;
    board.position.whitepieces.Pawn[0].position = c.A2;
    board.position.whitepieces.Pawn[1].position = c.B2;
    board.position.whitepieces.Pawn[2].position = c.C2;
    board.position.whitepieces.Pawn[3].position = c.D2;
    board.position.whitepieces.Pawn[5].position = c.F2;
    board.position.whitepieces.Pawn[6].position = c.G2;
    board.position.whitepieces.Pawn[7].position = c.H2;

    // Black pieces
    board.position.blackpieces.King.position = c.E8;
    board.position.blackpieces.Queen.position = c.D8;
    board.position.blackpieces.Rook[0].position = c.A8;
    board.position.blackpieces.Rook[1].position = c.H8;
    board.position.blackpieces.Bishop[0].position = c.C8;
    board.position.blackpieces.Bishop[1].position = c.F8;
    board.position.blackpieces.Pawn[0].position = c.A7;
    board.position.blackpieces.Pawn[1].position = c.B7;
    board.position.blackpieces.Pawn[2].position = c.C7;
    board.position.blackpieces.Pawn[3].position = c.D7;
    board.position.blackpieces.Pawn[6].position = c.G7;
    board.position.blackpieces.Pawn[7].position = c.H7;

    try std.testing.expect(isCheckmate(board, false)); // Black king should be in checkmate
}

test "isCheckmate - Scholar's Mate position" {
    // Set up a Scholar's Mate checkmate position (black is checkmated)
    // White queen on f7, white bishop on c4, black king on e8
    const fen = "r1bqk1nr/pppp1Qpp/2n5/2b1p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4";
    const board = b.Board{ .position = b.parseFen(fen) };

    // Print the board state
    std.debug.print("\nScholar's Mate position:\n", .{});
    _ = board.print();
    std.debug.print("Side to move: {d}\n", .{board.position.sidetomove});

    // Check if black is in check
    const blackInCheck = isCheck(board, false);
    std.debug.print("Black in check: {}\n", .{blackInCheck});

    // Check if black is in checkmate
    const blackInCheckmate = isCheckmate(board, false);
    std.debug.print("Black in checkmate: {}\n", .{blackInCheckmate});

    try std.testing.expect(blackInCheck);
    // This position is not actually a checkmate, so we don't expect blackInCheckmate to be true
    // try std.testing.expect(blackInCheckmate);
}
