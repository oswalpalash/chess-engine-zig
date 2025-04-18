const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

pub fn getValidKingMoves(piece: b.Piece, board: b.Board) []b.Board {
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    if (piece.position == 0) return moves[0..possiblemoves]; // Should not happen for king, but safe

    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var king: b.Piece = piece;
    var dummypiece: b.Piece = undefined;

    // King move shifts and corresponding masks to prevent wrap-around
    const kingShifts = [_]struct { shift: i8, mask: u64 }{
        .{ .shift = 8, .mask = 0xFFFFFFFFFFFFFFFF }, // Up 1
        .{ .shift = -8, .mask = 0xFFFFFFFFFFFFFFFF }, // Down 1
        .{ .shift = 1, .mask = 0xFEFEFEFEFEFEFEFE }, // Right 1 (not from H file)
        .{ .shift = -1, .mask = 0x7F7F7F7F7F7F7F7F }, // Left 1 (not from A file)
        .{ .shift = 9, .mask = 0xFEFEFEFEFEFEFEFE }, // Up 1, Right 1 (not from H file)
        .{ .shift = 7, .mask = 0x7F7F7F7F7F7F7F7F }, // Up 1, Left 1 (not from A file)
        .{ .shift = -7, .mask = 0xFEFEFEFEFEFEFEFE }, // Down 1, Right 1 (not from H file)
        .{ .shift = -9, .mask = 0x7F7F7F7F7F7F7F7F }, // Down 1, Left 1 (not from A file)
    };

    for (kingShifts) |move| {
        // Apply mask to ensure king is not on the edge it would wrap from
        if ((piece.position & move.mask) == 0) continue;

        var newpos: u64 = undefined;
        if (move.shift > 0) {
            // Check for potential overflow before shifting (though unlikely for king moves)
            newpos = piece.position << @as(u6, @intCast(move.shift));
        } else {
            // Check for potential underflow before shifting
            newpos = piece.position >> @as(u6, @intCast(-move.shift));
        }

        // If newpos is 0 after shift (e.g., E1 >> 9), skip
        if (newpos == 0) continue;

        // Check if target square is empty or has an enemy piece
        if (bitmap & newpos == 0) { // Square is empty
            king.position = newpos;
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.King.position = king.position;
            } else {
                newBoard.position.blackpieces.King.position = king.position;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else { // Square is occupied
            dummypiece = board_helpers.piecefromlocation(newpos, board);
            if (dummypiece.representation != '.' and dummypiece.color != piece.color) { // Enemy piece
                king.position = newpos;
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
        king = piece; // Reset king struct for next iteration
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
