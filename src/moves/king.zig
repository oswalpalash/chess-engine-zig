const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

pub fn getValidKingMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    const row_i8 = @as(i8, @intCast(board_helpers.rowfrombitmap(piece.position)));
    const col_i8 = @as(i8, @intCast(board_helpers.colfrombitmap(piece.position)));

    const directions = [_]struct { dr: i8, dc: i8, shift: i8 }{
        .{ .dr = 1, .dc = 0, .shift = 8 }, // up
        .{ .dr = -1, .dc = 0, .shift = -8 }, // down
        .{ .dr = 0, .dc = -1, .shift = -1 }, // left
        .{ .dr = 0, .dc = 1, .shift = 1 }, // right
        .{ .dr = 1, .dc = 1, .shift = 7 }, // up-right
        .{ .dr = 1, .dc = -1, .shift = 9 }, // up-left
        .{ .dr = -1, .dc = 1, .shift = -9 }, // down-right
        .{ .dr = -1, .dc = -1, .shift = -7 }, // down-left
    };

    for (directions) |dir| {
        const target_row = row_i8 + dir.dr;
        const target_col = col_i8 + dir.dc;

        if (target_row < 1 or target_row > 8 or target_col < 1 or target_col > 8) {
            continue;
        }

        const shift_amount: u6 = @as(u6, @intCast(if (dir.shift > 0) dir.shift else -dir.shift));
        const newpos = if (dir.shift > 0)
            piece.position << shift_amount
        else
            piece.position >> shift_amount;

        if (newpos == 0) {
            continue;
        }

        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.King.position = newpos;
            } else {
                newBoard.position.blackpieces.King.position = newpos;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.representation != '.' and targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });

                if (piece.color == 0) {
                    newBoard.position.whitepieces.King.position = newpos;
                } else {
                    newBoard.position.blackpieces.King.position = newpos;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
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

test "getValidKingMoves for king corners on empty board" {
    const cases = [_]struct {
        start: u64,
        expected: []const u64,
    }{
        .{ .start = c.A1, .expected = &[_]u64{ c.A2, c.B1, c.B2 } },
        .{ .start = c.H1, .expected = &[_]u64{ c.H2, c.G1, c.G2 } },
        .{ .start = c.A8, .expected = &[_]u64{ c.A7, c.B8, c.B7 } },
        .{ .start = c.H8, .expected = &[_]u64{ c.H7, c.G8, c.G7 } },
    };

    for (cases) |case| {
        var board = b.Board{ .position = b.Position.emptyboard() };
        board.position.whitepieces.King.position = case.start;
        const moves = getValidKingMoves(board.position.whitepieces.King, board);
        try std.testing.expectEqual(case.expected.len, moves.len);

        var found = [_]bool{false} ** 5;
        for (moves) |move| {
            const newPos = move.position.whitepieces.King.position;
            var matched = false;
            for (case.expected, 0..) |expected_pos, idx| {
                if (newPos == expected_pos) {
                    found[idx] = true;
                    matched = true;
                    break;
                }
            }
            try std.testing.expect(matched);
        }

        for (found[0..case.expected.len]) |was_found| {
            try std.testing.expect(was_found);
        }
    }
}

test "getValidKingMoves for king edges on empty board" {
    const cases = [_]struct {
        start: u64,
        expected: []const u64,
    }{
        .{ .start = c.A4, .expected = &[_]u64{ c.A5, c.B5, c.B4, c.A3, c.B3 } },
        .{ .start = c.D1, .expected = &[_]u64{ c.C1, c.C2, c.D2, c.E1, c.E2 } },
        .{ .start = c.H5, .expected = &[_]u64{ c.H6, c.G6, c.G5, c.H4, c.G4 } },
        .{ .start = c.D8, .expected = &[_]u64{ c.C8, c.C7, c.D7, c.E8, c.E7 } },
    };

    for (cases) |case| {
        var board = b.Board{ .position = b.Position.emptyboard() };
        board.position.whitepieces.King.position = case.start;
        const moves = getValidKingMoves(board.position.whitepieces.King, board);
        try std.testing.expectEqual(case.expected.len, moves.len);

        var found = [_]bool{false} ** 5;
        for (moves) |move| {
            const newPos = move.position.whitepieces.King.position;
            var matched = false;
            for (case.expected, 0..) |expected_pos, idx| {
                if (newPos == expected_pos) {
                    found[idx] = true;
                    matched = true;
                    break;
                }
            }
            try std.testing.expect(matched);
        }

        for (found[0..case.expected.len]) |was_found| {
            try std.testing.expect(was_found);
        }
    }
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
