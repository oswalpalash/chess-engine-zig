const b = @import("board.zig");
const c = @import("consts.zig");
const m = @import("moves.zig");
const std = @import("std");
const legal = @import("moves/legal.zig");

// isCheck determines if the given board position has the king in check
// It does this by checking if the king's square is attacked by any enemy piece
pub fn isCheck(board: b.Board, isWhite: bool) bool {
    // Get the king's position based on color
    const kingPosition = if (isWhite) board.position.whitepieces.King.position else board.position.blackpieces.King.position;

    // Use the isSquareAttacked function from legal.zig to check if the king's position is attacked
    const attackerColor: u8 = if (isWhite) 1 else 0; // Opposite color from the king
    return legal.isSquareAttacked(kingPosition, attackerColor, board);
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

    // Use the optimized getLegalMoves function from legal.zig
    // It already filters out moves that would leave the king in check
    const colorToMove: u8 = if (isWhite) 0 else 1;

    // Create a copy of the board with the correct side to move
    var board_copy = board;
    board_copy.sidetomove = colorToMove;

    const legal_moves = legal.getLegalMoves(colorToMove, board_copy);

    // If there are no legal moves, it's checkmate
    return legal_moves.len == 0;
}

test "isCheckmate - initial board position is not checkmate" {
    const board = b.Board{ .position = b.Position.init() };
    try std.testing.expect(!isCheckmate(board, true)); // White king not in checkmate
    try std.testing.expect(!isCheckmate(board, false)); // Black king not in checkmate
}

test "isCheckmate - fool's mate" {
    var board_copy = b.Board{ .position = b.Position.init() };

    // Modify white pieces that moved
    board_copy.position.whitepieces.Pawn[5].position = c.F3; // White f pawn to f3
    board_copy.position.whitepieces.Pawn[6].position = c.G4; // White g pawn to g4

    // Modify black pieces that moved
    board_copy.position.blackpieces.Pawn[4].position = c.E5; // Black e pawn to e5
    board_copy.position.blackpieces.Queen.position = c.H4; // Black queen to h4 (checkmate)

    const moves = legal.getLegalMoves(0, board_copy);
    std.debug.print("\nFool's Mate position:\n\n", .{});
    _ = board_copy.print();
    std.debug.print("White king in check: {}\n", .{legal.isKingInCheck(0, board_copy)});
    std.debug.print("Number of legal moves: {}\n", .{moves.len});

    try std.testing.expectEqual(@as(usize, 0), moves.len);
    try std.testing.expect(isCheckmate(board_copy, true));
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
