const std = @import("std");
const b = @import("board.zig");
const Board = b.Board;
const Piece = b.Piece;

pub fn evaluate(board: Board) i32 {
    var score: i32 = 0;

    // White pieces
    inline for (board.position.whitepieces.Pawn) |pawn| {
        if (pawn.position != 0) score += @as(i32, pawn.stdval) * 100;
    }
    inline for (board.position.whitepieces.Knight) |knight| {
        if (knight.position != 0) score += @as(i32, knight.stdval) * 100;
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
        if (pawn.position != 0) score -= @as(i32, pawn.stdval) * 100;
    }
    inline for (board.position.blackpieces.Knight) |knight| {
        if (knight.position != 0) score -= @as(i32, knight.stdval) * 100;
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

    return score;
}

test "evaluate initial position is balanced" {
    const board = Board{ .position = b.Position.init() };
    const score = evaluate(board);
    try std.testing.expectEqual(score, 0);
}

test "evaluate position with extra white pawn" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.blackpieces.Pawn[0].position = 0; // Remove a black pawn
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expectEqual(score, 100); // stdval of pawn is 1 * 100
}

test "evaluate position with extra white queen" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.blackpieces.Queen.position = 0; // Remove black queen
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expectEqual(score, 900); // stdval of queen is 9 * 100
}

test "evaluate position with missing white king" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.whitepieces.King.position = 0; // Remove white king
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expectEqual(score, -25500); // stdval of king is 255 * 100
}

test "evaluate empty board" {
    const board = Board{ .position = b.Position.emptyboard() };
    const score = evaluate(board);
    try std.testing.expectEqual(score, 0);
}
