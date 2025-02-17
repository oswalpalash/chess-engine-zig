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

test "evaluate position with multiple missing pieces" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.blackpieces.Pawn[0].position = 0; // Remove a black pawn
    pos.blackpieces.Knight[0].position = 0; // Remove a black knight
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expectEqual(score, 400); // pawn (100) + knight (300)
}

test "evaluate position with pieces missing on both sides" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;
    pos.blackpieces.Pawn[0].position = 0; // Remove a black pawn
    pos.whitepieces.Knight[0].position = 0; // Remove a white knight
    board.position = pos;
    const score = evaluate(board);
    try std.testing.expectEqual(score, -200); // black pawn removed (+100) and white knight removed (-300)
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
    try std.testing.expectEqual(score, 0); // Both kings have same value, should be balanced
}

test "evaluate position with minor piece advantage" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Remove a black bishop and white knight to test different minor piece values
    pos.blackpieces.Bishop[0].position = 0;
    pos.whitepieces.Knight[0].position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expectEqual(score, 0); // Bishop and knight have same value (300)
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
    try std.testing.expectEqual(score, 500); // 2 pawns (200) + 1 knight (300)
}

test "evaluate position with queen trade" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Remove both queens
    pos.whitepieces.Queen.position = 0;
    pos.blackpieces.Queen.position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expectEqual(score, 0); // Equal material after queen trade
}

test "evaluate position with rook advantage" {
    var board = Board{ .position = b.Position.init() };
    var pos = board.position;

    // Remove both black rooks
    pos.blackpieces.Rook[0].position = 0;
    pos.blackpieces.Rook[1].position = 0;

    board.position = pos;
    const score = evaluate(board);
    try std.testing.expectEqual(score, 1000); // Two rooks advantage (2 * 500)
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
    try std.testing.expectEqual(score, 3900); // All pieces except king (8 pawns + 2 knights + 2 bishops + 2 rooks + 1 queen)
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
    try std.testing.expectEqual(score, -100); // Black has one more pawn
}
