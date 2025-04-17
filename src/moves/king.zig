const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

pub fn getValidKingMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    var king: b.Piece = piece;
    var dummypiece: b.Piece = undefined;
    const directional_kingshifts = [4]u6{ 1, 7, 8, 9 };
    // forward moves
    for (directional_kingshifts) |shift| {
        if (piece.position << shift == 0) {
            continue;
        }
        // if there is no piece, allow shifting
        // if there is a piece, check if it is of different colour, if so, capture it
        // if it is of same colour, don't allow shifting
        if (bitmap & (piece.position << shift) == 0) {
            dummypiece = board_helpers.piecefromlocation(piece.position << shift, board);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == piece.color) {
                    continue;
                }
            }
            king.position = piece.position << shift;
            // update board
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.King.position = king.position;
            } else {
                newBoard.position.blackpieces.King.position = king.position;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            if (bitmap & (piece.position << shift) != 0) {
                dummypiece = board_helpers.piecefromlocation(piece.position << shift, board);
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != piece.color) {
                        king.position = piece.position << shift;
                        // update board with appropriate capture
                        var newBoard = if (piece.color == 0)
                            board_helpers.captureblackpiece(king.position, b.Board{ .position = board.position })
                        else
                            board_helpers.capturewhitepiece(king.position, b.Board{ .position = board.position });

                        if (piece.color == 0) {
                            newBoard.position.whitepieces.King.position = king.position;
                        } else {
                            newBoard.position.blackpieces.King.position = king.position;
                        }
                        moves[possiblemoves] = newBoard;
                        possiblemoves += 1;
                    }
                }
            }
        }
    }
    king = piece;
    // reverse moves
    for (directional_kingshifts) |shift| {
        if (king.position >> shift == 0) {
            continue;
        }
        if (bitmap & (king.position >> shift) == 0) {
            dummypiece = board_helpers.piecefromlocation(piece.position >> shift, board);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == piece.color) {
                    continue;
                }
            }
            king.position = piece.position >> shift;
            // update board
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.King.position = king.position;
            } else {
                newBoard.position.blackpieces.King.position = king.position;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            if (bitmap & (piece.position >> shift) != 0) {
                dummypiece = board_helpers.piecefromlocation(piece.position >> shift, board);
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != piece.color) {
                        king.position = piece.position >> shift;
                        // update board with appropriate capture
                        var newBoard = if (piece.color == 0)
                            board_helpers.captureblackpiece(king.position, b.Board{ .position = board.position })
                        else
                            board_helpers.capturewhitepiece(king.position, b.Board{ .position = board.position });

                        if (piece.color == 0) {
                            newBoard.position.whitepieces.King.position = king.position;
                        } else {
                            newBoard.position.blackpieces.King.position = king.position;
                        }
                        moves[possiblemoves] = newBoard;
                        possiblemoves += 1;
                    }
                }
            }
        }
    }

    // Add castling moves for white king (kingside) if available
    if (piece.color == 0 and board.position.canCastleWhiteKingside and piece.position == c.E1) {
        // Check if squares F1 and G1 are empty
        if ((bitmap & c.F1) == 0 and (bitmap & c.G1) == 0) {
            var castledKing = piece;
            castledKing.position = c.G1; // king moves two squares towards rook
            var newBoard = board;
            newBoard.position.whitepieces.King = castledKing;
            // Update kingside rook: from H1 to F1
            newBoard.position.whitepieces.Rook[1].position = c.F1;
            // Remove castling right
            newBoard.position.canCastleWhiteKingside = false;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    // Add castling moves for black king (kingside) if available
    if (piece.color == 1 and board.position.canCastleBlackKingside and piece.position == c.E8) {
        // Check if squares F8 and G8 are empty
        if ((bitmap & c.F8) == 0 and (bitmap & c.G8) == 0) {
            var castledKing = piece;
            castledKing.position = c.G8; // king moves two squares towards rook
            var newBoard = board;
            newBoard.position.blackpieces.King = castledKing;
            // Update kingside rook: from H8 to F8
            newBoard.position.blackpieces.Rook[1].position = c.F8;
            // Remove castling right
            newBoard.position.canCastleBlackKingside = false;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    return moves[0..possiblemoves];
}

test "getValidKingMoves for empty board with king on e1" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E4;
    _ = board.print();
    const moves = getValidKingMoves(board.position.whitepieces.King, board);
    try std.testing.expectEqual(moves.len, 8);
}

test "getValidKingMoves for init board with king on e1" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidKingMoves(board.position.whitepieces.King, board);
    try std.testing.expectEqual(moves.len, 0);
}

test "getValidKingMoves for empty board with king on e1 and black piece on e2" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E1;
    board.position.blackpieces.Pawn[4].position = c.E2;
    const moves = getValidKingMoves(board.position.whitepieces.King, board);
    try std.testing.expectEqual(moves.len, 5);
}

test "getValidKingMoves for black king on empty board" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E4;
    const moves = getValidKingMoves(board.position.blackpieces.King, board);
    try std.testing.expectEqual(moves.len, 8); // Should have 8 moves in all directions

    // Verify the king's position is updated correctly in the resulting boards
    for (moves) |move| {
        try std.testing.expectEqual(move.position.blackpieces.King.position != c.E4, true);
        try std.testing.expectEqual(move.position.whitepieces.King.position, 0);
    }
}

test "getValidKingMoves for black king with captures" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E4;
    // Place white pieces to capture
    board.position.whitepieces.Pawn[0].position = c.E5;
    board.position.whitepieces.Pawn[1].position = c.F4;
    // Place black piece to block
    board.position.blackpieces.Pawn[0].position = c.D4;

    const moves = getValidKingMoves(board.position.blackpieces.King, board);
    try std.testing.expectEqual(moves.len, 7); // 8 directions - 1 blocked

    // Verify captures work correctly
    var captureFound = false;
    for (moves) |move| {
        if (move.position.blackpieces.King.position == c.E5 or
            move.position.blackpieces.King.position == c.F4)
        {
            captureFound = true;
            // Check that the captured piece is removed
            if (move.position.blackpieces.King.position == c.E5) {
                try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);
            } else {
                try std.testing.expectEqual(move.position.whitepieces.Pawn[1].position, 0);
            }
        }
    }
    try std.testing.expect(captureFound);
}

test "getValidKingMoves for black king with castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E8;
    board.position.blackpieces.Rook[1].position = c.H8;
    board.position.canCastleBlackKingside = true;

    const moves = getValidKingMoves(board.position.blackpieces.King, board);

    // Verify castling is included in the moves
    var castlingFound = false;
    for (moves) |move| {
        if (move.position.blackpieces.King.position == c.G8 and
            move.position.blackpieces.Rook[1].position == c.F8)
        {
            castlingFound = true;
            try std.testing.expectEqual(move.position.canCastleBlackKingside, false);
        }
    }
    try std.testing.expect(castlingFound);
}
