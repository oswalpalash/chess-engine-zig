const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

fn canShiftForward(shift: u6, row: u64, col: u64) bool {
    return switch (shift) {
        1 => col > 1,
        7 => col < 8 and row < 8,
        8 => row < 8,
        9 => col > 1 and row < 8,
        else => false,
    };
}

fn canShiftBackward(shift: u6, row: u64, col: u64) bool {
    return switch (shift) {
        1 => col < 8,
        7 => col > 1 and row > 1,
        8 => row > 1,
        9 => col < 8 and row > 1,
        else => false,
    };
}

pub fn getValidKingMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    var king: b.Piece = piece;
    var dummypiece: b.Piece = undefined;
    const next_side: u8 = if (board.position.sidetomove == 0) 1 else 0;
    const directional_kingshifts = [4]u6{ 1, 7, 8, 9 };
    const king_row = board_helpers.rowfrombitmap(piece.position);
    const king_col = board_helpers.colfrombitmap(piece.position);
    // forward moves
    for (directional_kingshifts) |shift| {
        if (!canShiftForward(shift, king_row, king_col)) {
            continue;
        }
        const target = piece.position << shift;
        if (target == 0) {
            continue;
        }
        // if there is no piece, allow shifting
        // if there is a piece, check if it is of different colour, if so, capture it
        // if it is of same colour, don't allow shifting
        if ((bitmap & target) == 0) {
            dummypiece = board_helpers.piecefromlocation(target, board);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == piece.color) {
                    continue;
                }
            }
            king.position = target;
            // update board
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.King.position = king.position;
                newBoard.position.canCastleWhiteKingside = false;
                newBoard.position.canCastleWhiteQueenside = false;
            } else {
                newBoard.position.blackpieces.King.position = king.position;
                newBoard.position.canCastleBlackKingside = false;
                newBoard.position.canCastleBlackQueenside = false;
            }
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            if ((bitmap & target) != 0) {
                dummypiece = board_helpers.piecefromlocation(target, board);
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != piece.color) {
                        king.position = target;
                        // update board with appropriate capture
                        var newBoard = if (piece.color == 0)
                            board_helpers.captureblackpiece(king.position, b.Board{ .position = board.position })
                        else
                            board_helpers.capturewhitepiece(king.position, b.Board{ .position = board.position });

                        if (piece.color == 0) {
                            newBoard.position.whitepieces.King.position = king.position;
                            newBoard.position.canCastleWhiteKingside = false;
                            newBoard.position.canCastleWhiteQueenside = false;
                        } else {
                            newBoard.position.blackpieces.King.position = king.position;
                            newBoard.position.canCastleBlackKingside = false;
                            newBoard.position.canCastleBlackQueenside = false;
                        }
                        newBoard.position.sidetomove = next_side;
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
        if (!canShiftBackward(shift, king_row, king_col)) {
            continue;
        }
        const target = piece.position >> shift;
        if (target == 0) {
            continue;
        }
        if ((bitmap & target) == 0) {
            dummypiece = board_helpers.piecefromlocation(target, board);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == piece.color) {
                    continue;
                }
            }
            king.position = target;
            // update board
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.King.position = king.position;
                newBoard.position.canCastleWhiteKingside = false;
                newBoard.position.canCastleWhiteQueenside = false;
            } else {
                newBoard.position.blackpieces.King.position = king.position;
                newBoard.position.canCastleBlackKingside = false;
                newBoard.position.canCastleBlackQueenside = false;
            }
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            if ((bitmap & target) != 0) {
                dummypiece = board_helpers.piecefromlocation(target, board);
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != piece.color) {
                        king.position = target;
                        // update board with appropriate capture
                        var newBoard = if (piece.color == 0)
                            board_helpers.captureblackpiece(king.position, b.Board{ .position = board.position })
                        else
                            board_helpers.capturewhitepiece(king.position, b.Board{ .position = board.position });

                        if (piece.color == 0) {
                            newBoard.position.whitepieces.King.position = king.position;
                            newBoard.position.canCastleWhiteKingside = false;
                            newBoard.position.canCastleWhiteQueenside = false;
                        } else {
                            newBoard.position.blackpieces.King.position = king.position;
                            newBoard.position.canCastleBlackKingside = false;
                            newBoard.position.canCastleBlackQueenside = false;
                        }
                        newBoard.position.sidetomove = next_side;
                        moves[possiblemoves] = newBoard;
                        possiblemoves += 1;
                    }
                }
            }
        }
    }

    // Add castling moves for white king (kingside) if available
    if (piece.color == 0 and board.position.canCastleWhiteKingside and piece.position == c.E1 and
        board.position.whitepieces.Rook[1].position == c.H1)
    {
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
            newBoard.position.canCastleWhiteQueenside = false;
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    // Add castling moves for black king (kingside) if available
    if (piece.color == 1 and board.position.canCastleBlackKingside and piece.position == c.E8 and
        board.position.blackpieces.Rook[1].position == c.H8)
    {
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
            newBoard.position.canCastleBlackQueenside = false;
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    return moves[0..possiblemoves];
}

fn expectKingMoves(moves: []b.Board, expected: []const u64, color: u1) !void {
    try std.testing.expectEqual(expected.len, moves.len);
    for (expected) |square| {
        var found = false;
        for (moves) |move| {
            const king_pos = if (color == 0)
                move.position.whitepieces.King.position
            else
                move.position.blackpieces.King.position;
            if (king_pos == square) {
                found = true;
                break;
            }
        }
        try std.testing.expect(found);
    }
    for (moves) |move| {
        const king_pos = if (color == 0)
            move.position.whitepieces.King.position
        else
            move.position.blackpieces.King.position;
        var found = false;
        for (expected) |square| {
            if (king_pos == square) {
                found = true;
                break;
            }
        }
        try std.testing.expect(found);
    }
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

test "castling requires rook on start square" {
    var board_with_rook = b.Board{ .position = b.Position.emptyboard() };
    board_with_rook.position.whitepieces.King.position = c.E1;
    board_with_rook.position.whitepieces.Rook[1].position = c.H1;
    board_with_rook.position.canCastleWhiteKingside = true;

    const moves_with_rook = getValidKingMoves(board_with_rook.position.whitepieces.King, board_with_rook);
    var castlingFound = false;
    for (moves_with_rook) |move| {
        if (move.position.whitepieces.King.position == c.G1 and
            move.position.whitepieces.Rook[1].position == c.F1)
        {
            castlingFound = true;
            break;
        }
    }
    try std.testing.expect(castlingFound);

    var board_without_rook = board_with_rook;
    board_without_rook.position.whitepieces.Rook[1].position = 0;

    const moves_without_rook = getValidKingMoves(board_without_rook.position.whitepieces.King, board_without_rook);
    var castlingMissing = true;
    for (moves_without_rook) |move| {
        if (move.position.whitepieces.King.position == c.G1 and
            move.position.whitepieces.Rook[1].position == c.F1)
        {
            castlingMissing = false;
            break;
        }
    }
    try std.testing.expect(castlingMissing);
}

test "castling unavailable after king moves" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E1;
    board.position.whitepieces.Rook[1].position = c.H1;
    board.position.canCastleWhiteKingside = true;
    board.position.canCastleWhiteQueenside = true;

    const moves = getValidKingMoves(board.position.whitepieces.King, board);
    var moved_board: ?b.Board = null;
    for (moves) |move| {
        if (move.position.whitepieces.King.position == c.E2) {
            moved_board = move;
            break;
        }
    }
    try std.testing.expect(moved_board != null);
    try std.testing.expectEqual(false, moved_board.?.position.canCastleWhiteKingside);
    try std.testing.expectEqual(false, moved_board.?.position.canCastleWhiteQueenside);

    var reset_board = moved_board.?;
    reset_board.position.whitepieces.King.position = c.E1;

    const follow_up_moves = getValidKingMoves(reset_board.position.whitepieces.King, reset_board);
    for (follow_up_moves) |move| {
        try std.testing.expect(move.position.whitepieces.King.position != c.G1 or
            move.position.whitepieces.Rook[1].position != c.F1);
    }
}

test "castling unavailable after rook moves" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E1;
    board.position.whitepieces.Rook[1].position = c.H2;
    board.position.canCastleWhiteKingside = true;

    const moves = getValidKingMoves(board.position.whitepieces.King, board);
    for (moves) |move| {
        try std.testing.expect(move.position.whitepieces.King.position != c.G1 or
            move.position.whitepieces.Rook[1].position != c.F1);
    }
}

test "castling unavailable after rook capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E1;
    board.position.whitepieces.Rook[1].position = c.H1;
    board.position.canCastleWhiteKingside = true;

    const post_capture = board_helpers.capturewhitepiece(c.H1, board);
    try std.testing.expectEqual(false, post_capture.position.canCastleWhiteKingside);

    const moves = getValidKingMoves(post_capture.position.whitepieces.King, post_capture);
    for (moves) |move| {
        try std.testing.expect(move.position.whitepieces.King.position != c.G1 or
            move.position.whitepieces.Rook[1].position != c.F1);
    }
}

test "white king moves on corner squares" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.A1;
    var moves = getValidKingMoves(board.position.whitepieces.King, board);
    const expected_a1 = [_]u64{ c.A2, c.B1, c.B2 };
    try expectKingMoves(moves, expected_a1[0..], 0);

    board.position.whitepieces.King.position = c.H1;
    moves = getValidKingMoves(board.position.whitepieces.King, board);
    const expected_h1 = [_]u64{ c.G1, c.G2, c.H2 };
    try expectKingMoves(moves, expected_h1[0..], 0);

    board.position.whitepieces.King.position = c.A8;
    moves = getValidKingMoves(board.position.whitepieces.King, board);
    const expected_a8 = [_]u64{ c.A7, c.B7, c.B8 };
    try expectKingMoves(moves, expected_a8[0..], 0);

    board.position.whitepieces.King.position = c.H8;
    moves = getValidKingMoves(board.position.whitepieces.King, board);
    const expected_h8 = [_]u64{ c.G7, c.G8, c.H7 };
    try expectKingMoves(moves, expected_h8[0..], 0);
}

test "king moves on edge files and ranks" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.A4;
    var moves = getValidKingMoves(board.position.whitepieces.King, board);
    const expected_a4 = [_]u64{ c.A3, c.A5, c.B3, c.B4, c.B5 };
    try expectKingMoves(moves, expected_a4[0..], 0);

    board.position.whitepieces.King.position = c.H5;
    moves = getValidKingMoves(board.position.whitepieces.King, board);
    const expected_h5 = [_]u64{ c.G4, c.G5, c.G6, c.H4, c.H6 };
    try expectKingMoves(moves, expected_h5[0..], 0);

    board.position.whitepieces.King.position = c.E1;
    moves = getValidKingMoves(board.position.whitepieces.King, board);
    const expected_e1 = [_]u64{ c.D1, c.D2, c.E2, c.F1, c.F2 };
    try expectKingMoves(moves, expected_e1[0..], 0);

    board.position.blackpieces.King.position = c.E8;
    board.position.whitepieces.King.position = 0;
    const black_moves = getValidKingMoves(board.position.blackpieces.King, board);
    const expected_e8 = [_]u64{ c.D7, c.D8, c.E7, c.F7, c.F8 };
    try expectKingMoves(black_moves, expected_e8[0..], 1);
}
