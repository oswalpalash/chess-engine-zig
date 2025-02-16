// advanced_tests.zig

const b = @import("board.zig");
const c = @import("consts.zig");
const m = @import("moves.zig");
const std = @import("std");

// Test for castling moves
// Updated: In the current configuration, when F1 and G1 are clear, the king generates two moves: a normal move from E1 to F1 and the castling move (king from E1 to G1, rook from H1 to F1).
test "castling moves for white king available" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Simulate castling rights by initializing the standard position
    board.position = b.Position.init();
    // Clear squares between king and rook (F1 and G1) so moves are allowed
    board.position.whitepieces.Bishop[1].position = 0; // originally at F1
    board.position.whitepieces.Knight[1].position = 0;   // originally at G1
    
    const moves = m.getValidKingMoves(board.position.whitepieces.King, board);
    // Expect two moves: one normal king move (E1->F1) and one castling move (E1->G1 with rook from H1->F1)
    try std.testing.expectEqual(moves.len, 2);
}

// Test for pawn promotion moves
// Note: Pawn promotion is not implemented yet. This test sets up a pawn on the 7th rank and
// checks that at least a forward move is generated. Once promotion is implemented, this test should
// verify that promotion moves are included.
test "pawn promotion moves are not generated yet" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Place a white pawn on the 7th rank (for example, A7)
    board.position.whitepieces.Pawn[0].position = c.A7;
    const moves = m.getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    // Currently, the engine probably only generates the basic forward move.
    try std.testing.expect(moves.len >= 1);
}

// Test for en passant moves
// Note: En passant is not implemented. This test creates a scenario where en passant might be available,
// and checks that no en passant move is generated until the feature is implemented.
test "en passant test placeholder" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Place a white pawn on e5
    board.position.whitepieces.Pawn[0].position = c.E5;
    // Place a black pawn on d5 in a position that would normally allow en passant capture
    board.position.blackpieces.Pawn[3].position = c.D5;
    
    const moves = m.getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    // For a pawn on e5 in an otherwise empty board, normally only a forward move (to e6) would be generated.
    // Without en passant implemented, the moves.len should reflect only that basic move.
    try std.testing.expectEqual(moves.len, 1);
} 