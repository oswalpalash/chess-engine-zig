const std = @import("std");
const b = @import("board.zig");
const c = @import("consts.zig");
const pawn = @import("moves/pawn.zig");
const board_helpers = @import("utils/board_helpers.zig");
const rook = @import("moves/rook.zig");
const knight = @import("moves/knight.zig");
const bishop = @import("moves/bishop.zig");
const queen = @import("moves/queen.zig");
const king = @import("moves/king.zig");

// Import the reverse function from board.zig
const reverse = b.reverse;

/// Represents a chess move from one square to another
pub const Move = struct {
    from: u64, // Bitboard position of source square
    to: u64, // Bitboard position of target square
    promotion_piece: ?u8 = null, // Optional promotion piece (e.g., 'q' for queen)

    /// Convert a move to UCI string format (e.g., "e2e4" or "e7e8q")
    pub fn toUciString(self: Move) ![5]u8 {
        var result: [5]u8 = undefined;

        // Convert source square
        const from_square = b.bitboardToSquare(self.from);
        result[0] = from_square[0];
        result[1] = from_square[1];

        // Convert target square
        const to_square = b.bitboardToSquare(self.to);
        result[2] = to_square[0];
        result[3] = to_square[1];

        // Add promotion piece if present
        if (self.promotion_piece) |piece| {
            result[4] = piece;
        } else {
            result[4] = 0;
        }

        return result;
    }
};

/// Parse a UCI move string (e.g., "e2e4" or "e7e8q") into a Move structure
pub fn parseUciMove(token: []const u8) !Move {
    if (token.len < 4 or token.len > 5) {
        return error.InvalidMoveFormat;
    }

    // Parse source square
    const from_file = token[0];
    const from_rank = token[1];
    if (from_file < 'a' or from_file > 'h' or from_rank < '1' or from_rank > '8') {
        return error.InvalidSquare;
    }

    // Parse target square
    const to_file = token[2];
    const to_rank = token[3];
    if (to_file < 'a' or to_file > 'h' or to_rank < '1' or to_rank > '8') {
        return error.InvalidSquare;
    }

    // Convert algebraic notation to bitboard positions
    const from_file_idx = from_file - 'a';
    const from_rank_idx = from_rank - '1';
    const to_file_idx = to_file - 'a';
    const to_rank_idx = to_rank - '1';

    // Calculate bitboard positions
    const from_pos = @as(u64, 1) << @intCast(from_rank_idx * 8 + (7 - from_file_idx));
    const to_pos = @as(u64, 1) << @intCast(to_rank_idx * 8 + (7 - to_file_idx));

    // Check for promotion
    var promotion_piece: ?u8 = null;
    if (token.len == 5) {
        const piece = token[4];
        switch (piece) {
            'q', 'r', 'b', 'n' => promotion_piece = piece,
            else => return error.InvalidPromotionPiece,
        }
    }

    return Move{
        .from = from_pos,
        .to = to_pos,
        .promotion_piece = promotion_piece,
    };
}

test "import works" {
    const board = b.Board{ .position = b.Position.init() };
    try std.testing.expectEqual(board.move_count, 0);
    try std.testing.expectEqual(board.position.whitepieces.King.position, c.E1);
}

// takes in a board and iterates through all pieces and returns a 64 bit representation of the board
pub fn bitmapfromboard(board: b.Board) u64 {
    return board_helpers.bitmapfromboard(board);
}

test "bitmap of initial board" {
    const board = b.Board{ .position = b.Position.init() };
    const bitmap = bitmapfromboard(board);
    try std.testing.expectEqual(bitmap, 0xFFFF00000000FFFF);
    try std.testing.expectEqual(bitmap, c.A1 | c.B1 | c.C1 | c.D1 | c.E1 | c.F1 | c.G1 | c.H1 | c.A2 | c.B2 | c.C2 | c.D2 | c.E2 | c.F2 | c.G2 | c.H2 | c.A7 | c.B7 | c.C7 | c.D7 | c.E7 | c.F7 | c.G7 | c.H7 | c.A8 | c.B8 | c.C8 | c.D8 | c.E8 | c.F8 | c.G8 | c.H8);
}

pub fn piecefromlocation(location: u64, board: b.Board) b.Piece {
    return board_helpers.piecefromlocation(location, board);
}

test "piece from location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H1,
        board,
    );
    try std.testing.expectEqual(piece.representation, 'R');
}

test "white pawn from location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H2,
        board,
    );
    try std.testing.expectEqual(piece.representation, 'P');
}

test "empty location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H3,
        board,
    );
    try std.testing.expectEqual(piece.representation, '.');
}

test "black pawn from location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H7,
        board,
    );
    try std.testing.expectEqual(piece.representation, 'p');
}

test "black piece from location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H8,
        board,
    );
    try std.testing.expectEqual(piece.representation, 'r');
}

pub fn captureblackpiece(loc: u64, board: b.Board) b.Board {
    return board_helpers.captureblackpiece(loc, board);
}

test "capture black pawn at e7 in initial board" {
    const newboard = captureblackpiece(c.E7, b.Board{ .position = b.Position.init() });
    try std.testing.expectEqual(newboard.position.blackpieces.Pawn[3].position, 0);
}

test "capture black rook at a8 in initial board" {
    const newboard = captureblackpiece(c.A8, b.Board{ .position = b.Position.init() });
    try std.testing.expectEqual(newboard.position.blackpieces.Rook[1].position, 0);
}

test "ensure self captures are not allowed. add a3 pawn in init board and check pawn moves for a2 pawn" {
    var board = b.Board{ .position = b.Position.init() };
    board.position.whitepieces.Pawn[7].position = c.A3;
    _ = board.print();
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 0);
}

test "pawn capture e3 f4 or go to e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[3].position = c.E3;
    board.position.blackpieces.Pawn[2].position = c.F4;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 2);
    try std.testing.expectEqual(moves[1].position.blackpieces.Pawn[2].position, 0);
    try std.testing.expectEqual(moves[0].position.blackpieces.Pawn[2].position, c.F4);
    try std.testing.expectEqual(moves[0].position.whitepieces.Pawn[3].position, c.E4);
}

pub fn rowfrombitmap(bitmap: u64) u64 {
    return board_helpers.rowfrombitmap(bitmap);
}

pub fn colfrombitmap(bitmap: u64) u64 {
    return board_helpers.colfrombitmap(bitmap);
}

test "rowfrombitmap and colfrombitmap for black rook at a8" {
    const board = b.Board{ .position = b.Position.init() };
    const blackRook = board.position.blackpieces.Rook[1]; // A8 rook
    const row = rowfrombitmap(blackRook.position);
    const col = colfrombitmap(blackRook.position);
    try std.testing.expectEqual(row, 8);
    try std.testing.expectEqual(col, 1);
}

test "ValidBishopMoves for empty board with bishop on e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Bishop[0].position = c.E4;
    _ = board.print();

    const moves = getValidBishopMoves(board.position.whitepieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 13); // Bishop on e4 can move to 13 squares

    // Verify specific positions
    var foundPositions = [_]bool{false} ** 13;
    const expectedPositions = [_]u64{
        c.D5, c.C6, c.B7, c.A8, // Up-Left diagonal
        c.F5, c.G6, c.H7, // Up-Right diagonal
        c.D3, c.C2, c.B1, // Down-Left diagonal
        c.F3, c.G2, c.H1, // Down-Right diagonal
    };

    for (moves) |move| {
        const pos = move.position.whitepieces.Bishop[0].position;
        for (expectedPositions, 0..) |expected, i| {
            if (pos == expected) {
                foundPositions[i] = true;
            }
        }
    }

    // Verify all expected positions were found
    for (foundPositions) |found| {
        try std.testing.expect(found);
    }
}

test "ValidBishopMoves for bishop on c1 in initial position" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidBishopMoves(board.position.whitepieces.Bishop[1], board);
    try std.testing.expectEqual(moves.len, 0); // Bishop should be blocked by pawns
}

test "ValidBishopMoves with captures" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Bishop[0].position = c.E4;

    // Place black pieces to capture
    board.position.blackpieces.Pawn[0].position = c.C6; // Up-Left
    board.position.blackpieces.Pawn[1].position = c.G6; // Up-Right
    board.position.blackpieces.Pawn[2].position = c.C2; // Down-Left
    board.position.blackpieces.Pawn[3].position = c.G2; // Down-Right

    // Place white piece to block
    board.position.whitepieces.Pawn[0].position = c.F5; // Blocks further Up-Right movement

    const moves = getValidBishopMoves(board.position.whitepieces.Bishop[0], board);

    // Expected moves:
    // Up-Left: d5, c6(capture)
    // Up-Right: f5(blocked)
    // Down-Left: d3, c2(capture)
    // Down-Right: f3, g2(capture)
    try std.testing.expectEqual(moves.len, 6);

    // Verify captures result in removed pieces
    var captureFound = false;
    for (moves) |move| {
        if (move.position.whitepieces.Bishop[0].position == c.C6) {
            try std.testing.expectEqual(move.position.blackpieces.Pawn[0].position, 0);
            captureFound = true;
        }
    }
    try std.testing.expect(captureFound);
}

test "ValidBishopMoves edge cases" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Test from corner
    board.position.whitepieces.Bishop[0].position = c.A1;
    var moves = getValidBishopMoves(board.position.whitepieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 7); // Can only move diagonally up-right

    // Test from edge
    board.position.whitepieces.Bishop[0].position = c.A4;
    moves = getValidBishopMoves(board.position.whitepieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 7); // Can move diagonally up-right and down-right
}

pub fn ValidQueenMoves(piece: b.Piece, board: b.Board) []b.Board {
    return queen.getValidQueenMoves(piece, board);
}

// Test cases for ValidQueenMoves
test "ValidQueenMoves for initial board (no moves expected)" {
    const board = b.Board{ .position = b.Position.init() };
    const queen_piece = board.position.whitepieces.Queen;
    const moves = ValidQueenMoves(queen_piece, board);
    try std.testing.expectEqual(moves.len, 0); // Queen is blocked by own pieces
}

test "ValidQueenMoves for empty board with queen on d4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.D4;
    _ = board.print();

    const moves = ValidQueenMoves(board.position.whitepieces.Queen, board);

    // Expected moves: 27 moves (all directions until the edge of the board)
    try std.testing.expect(moves.len == 27);
}

test "ValidQueenMoves for empty board with queen on a1" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.A1;
    _ = board.print();

    const moves = ValidQueenMoves(board.position.whitepieces.Queen, board);

    // From a1, queen can move to:
    // a2-a8, b1-h1, b2-h8 => total 7 + 7 + 7 = 21 moves
    try std.testing.expect(moves.len == 21);
}

test "ValidQueenMoves with obstacles" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.D4;
    // Place friendly pieces at d5 and e4
    board.position.whitepieces.Pawn[0].position = c.D5;
    board.position.whitepieces.Pawn[1].position = c.E4;
    // Place enemy piece at c5 and e5
    board.position.blackpieces.Pawn[0].position = c.C5;
    board.position.blackpieces.Pawn[1].position = c.E5;
    _ = board.print();

    const moves = ValidQueenMoves(board.position.whitepieces.Queen, board);

    // Expected moves:
    // d5 blocked by own piece (no move up)
    // d3, d2, d1
    // e4 captures own piece (invalid), so no moves east
    // c4, b4, a4
    // e5 captures enemy piece
    // c5 captures enemy piece
    // e3, f2, g1
    // c3, b2, a1

    try std.testing.expect(moves.len == 14);
}

// Color-specific move functions
pub const getValidPawnMoves = pawn.getValidPawnMoves;

test "getValidPawnMoves works for white pawns" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2); // e2 pawn can move to e3 and e4
}

test "getValidPawnMoves works for black pawns" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidPawnMoves(board.position.blackpieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2); // e7 pawn can move to e6 and e5
}

pub const getValidRookMoves = rook.getValidRookMoves;

test "getValidRookMoves works for white rooks" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.E4;
    const moves = getValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // Rook on e4 can move to 14 squares
}

test "getValidRookMoves works for black rooks" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Rook[0].position = c.E4;
    const moves = getValidRookMoves(board.position.blackpieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // Rook on e4 can move to 14 squares (7 horizontal + 7 vertical)
}

pub const getValidKnightMoves = knight.getValidKnightMoves;

pub const getValidBishopMoves = bishop.getValidBishopMoves;

test "getValidBishopMoves works for white bishops" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Bishop[0].position = c.E4;
    const moves = getValidBishopMoves(board.position.whitepieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 13); // Bishop on e4 can move to 13 squares
}

test "getValidBishopMoves works for black bishops" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Bishop[0].position = c.E4;
    const moves = getValidBishopMoves(board.position.blackpieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 13); // Bishop on e4 can move to 13 squares
}

pub const getValidQueenMoves = queen.getValidQueenMoves;

test "getValidQueenMoves works for white queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.E4;
    const moves = getValidQueenMoves(board.position.whitepieces.Queen, board);
    try std.testing.expectEqual(moves.len, 27); // Queen on e4 can move to 27 squares
}

test "getValidQueenMoves works for black queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Queen.position = c.E4;
    const moves = getValidQueenMoves(board.position.blackpieces.Queen, board);
    try std.testing.expectEqual(moves.len, 27); // Queen on e4 can move to 27 squares
}

pub const getValidKingMoves = king.getValidKingMoves;

test "getValidKingMoves works for white king" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E4;
    const moves = getValidKingMoves(board.position.whitepieces.King, board);
    try std.testing.expectEqual(moves.len, 8); // King on e4 can move to 8 squares
}

test "getValidKingMoves works for black king" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E4;
    const moves = getValidKingMoves(board.position.blackpieces.King, board);
    try std.testing.expectEqual(moves.len, 8); // King on e4 can move to 8 squares
}

pub fn capturewhitepiece(loc: u64, board: b.Board) b.Board {
    var piece: b.Piece = piecefromlocation(loc, board);
    var boardCopy: b.Board = board;
    // determine type of piece
    _ = switch (piece.representation) {
        'K' => {
            boardCopy.position.whitepieces.King.position = 0;
            piece.position = 0;
        },
        'Q' => {
            boardCopy.position.whitepieces.Queen.position = 0;
            piece.position = 0;
        },
        'R' => {
            if (boardCopy.position.whitepieces.Rook[0].position == loc) {
                boardCopy.position.whitepieces.Rook[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Rook[1].position == loc) {
                boardCopy.position.whitepieces.Rook[1].position = 0;
                piece.position = 0;
            }
        },
        'B' => {
            if (boardCopy.position.whitepieces.Bishop[0].position == loc) {
                boardCopy.position.whitepieces.Bishop[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Bishop[1].position == loc) {
                boardCopy.position.whitepieces.Bishop[1].position = 0;
                piece.position = 0;
            }
        },
        'N' => {
            if (boardCopy.position.whitepieces.Knight[0].position == loc) {
                boardCopy.position.whitepieces.Knight[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Knight[1].position == loc) {
                boardCopy.position.whitepieces.Knight[1].position = 0;
                piece.position = 0;
            }
        },
        'P' => {
            if (boardCopy.position.whitepieces.Pawn[0].position == loc) {
                boardCopy.position.whitepieces.Pawn[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[1].position == loc) {
                boardCopy.position.whitepieces.Pawn[1].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[2].position == loc) {
                boardCopy.position.whitepieces.Pawn[2].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[3].position == loc) {
                boardCopy.position.whitepieces.Pawn[3].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[4].position == loc) {
                boardCopy.position.whitepieces.Pawn[4].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[5].position == loc) {
                boardCopy.position.whitepieces.Pawn[5].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[6].position == loc) {
                boardCopy.position.whitepieces.Pawn[6].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[7].position == loc) {
                boardCopy.position.whitepieces.Pawn[7].position = 0;
                piece.position = 0;
            }
        },
        else => {},
    };
    return boardCopy;
}

pub fn allvalidmoves(board: b.Board) []b.Board {
    // Check for checkmate first
    const s = @import("state.zig");
    if (s.isCheckmate(board, board.position.sidetomove == 0)) {
        return &[_]b.Board{};
    }

    var moves: [1024]b.Board = undefined;
    var movecount: usize = 0;

    // Copy board and set side to move for each generated move
    var boardCopy = board;
    const next_side: u8 = if (board.position.sidetomove == 0) 1 else 0;

    if (board.position.sidetomove == 0) { // White pieces
        // King moves
        const kingMoves = getValidKingMoves(board.position.whitepieces.King, board);
        for (kingMoves) |move| {
            // Only allow moves that don't leave us in check
            if (!s.isCheck(move, true)) {
                boardCopy = move;
                boardCopy.position.sidetomove = next_side;
                moves[movecount] = boardCopy;
                movecount += 1;
            }
        }

        // Queen moves
        const queenMoves = getValidQueenMoves(board.position.whitepieces.Queen, board);
        for (queenMoves) |move| {
            if (!s.isCheck(move, true)) {
                boardCopy = move;
                boardCopy.position.sidetomove = next_side;
                moves[movecount] = boardCopy;
                movecount += 1;
            }
        }

        // Rook moves
        var rookMoveCount: usize = 0;
        for (board.position.whitepieces.Rook) |r| {
            if (r.position == 0) continue;
            const rookMoves = getValidRookMoves(r, board);
            rookMoveCount += rookMoves.len;
            for (rookMoves) |move| {
                if (!s.isCheck(move, true)) {
                    boardCopy = move;
                    boardCopy.position.sidetomove = next_side;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Bishop moves
        var bishopMoveCount: usize = 0;
        for (board.position.whitepieces.Bishop) |piece| {
            if (piece.position == 0) continue;
            const bishopMoves = getValidBishopMoves(piece, board);
            bishopMoveCount += bishopMoves.len;
            for (bishopMoves) |move| {
                if (!s.isCheck(move, true)) {
                    boardCopy = move;
                    boardCopy.position.sidetomove = next_side;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Knight moves
        var knightMoveCount: usize = 0;
        for (board.position.whitepieces.Knight) |k| {
            if (k.position == 0) continue;
            const knightMoves = getValidKnightMoves(k, board);
            knightMoveCount += knightMoves.len;
            for (knightMoves) |move| {
                if (!s.isCheck(move, true)) {
                    boardCopy = move;
                    boardCopy.position.sidetomove = next_side;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Pawn moves
        var pawnMoveCount: usize = 0;
        for (board.position.whitepieces.Pawn) |p| {
            if (p.position == 0) continue;
            const pawnMoves = getValidPawnMoves(p, board);
            pawnMoveCount += pawnMoves.len;
            for (pawnMoves) |move| {
                if (!s.isCheck(move, true)) {
                    boardCopy = move;
                    boardCopy.position.sidetomove = next_side;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }
    } else { // Black pieces
        // King moves
        const kingMoves = getValidKingMoves(board.position.blackpieces.King, board);
        for (kingMoves) |move| {
            // Only allow moves that don't leave us in check
            if (!s.isCheck(move, false)) {
                boardCopy = move;
                boardCopy.position.sidetomove = next_side;
                moves[movecount] = boardCopy;
                movecount += 1;
            }
        }

        // Queen moves
        const queenMoves = getValidQueenMoves(board.position.blackpieces.Queen, board);
        for (queenMoves) |move| {
            if (!s.isCheck(move, false)) {
                boardCopy = move;
                boardCopy.position.sidetomove = next_side;
                moves[movecount] = boardCopy;
                movecount += 1;
            }
        }

        // Rook moves
        var rookMoveCount: usize = 0;
        for (board.position.blackpieces.Rook) |r| {
            if (r.position == 0) continue;
            const rookMoves = getValidRookMoves(r, board);
            rookMoveCount += rookMoves.len;
            for (rookMoves) |move| {
                if (!s.isCheck(move, false)) {
                    boardCopy = move;
                    boardCopy.position.sidetomove = next_side;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Bishop moves
        var bishopMoveCount: usize = 0;
        for (board.position.blackpieces.Bishop) |piece| {
            if (piece.position == 0) continue;
            const bishopMoves = getValidBishopMoves(piece, board);
            bishopMoveCount += bishopMoves.len;
            for (bishopMoves) |move| {
                if (!s.isCheck(move, false)) {
                    boardCopy = move;
                    boardCopy.position.sidetomove = next_side;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Knight moves
        var knightMoveCount: usize = 0;
        for (board.position.blackpieces.Knight) |k| {
            if (k.position == 0) continue;
            const knightMoves = getValidKnightMoves(k, board);
            knightMoveCount += knightMoves.len;
            for (knightMoves) |move| {
                if (!s.isCheck(move, false)) {
                    boardCopy = move;
                    boardCopy.position.sidetomove = next_side;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Pawn moves
        var pawnMoveCount: usize = 0;
        for (board.position.blackpieces.Pawn) |p| {
            if (p.position == 0) continue;
            const pawnMoves = getValidPawnMoves(p, board);
            pawnMoveCount += pawnMoves.len;
            for (pawnMoves) |move| {
                if (!s.isCheck(move, false)) {
                    boardCopy = move;
                    boardCopy.position.sidetomove = next_side;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }
    }

    return moves[0..movecount];
}

test "parseUciMove basic move" {
    const move = try parseUciMove("e2e4");
    try std.testing.expectEqual(move.from, c.E2);
    try std.testing.expectEqual(move.to, c.E4);
    try std.testing.expectEqual(move.promotion_piece, null);
}

test "parseUciMove promotion move" {
    const move = try parseUciMove("e7e8q");
    try std.testing.expectEqual(move.from, c.E7);
    try std.testing.expectEqual(move.to, c.E8);
    try std.testing.expectEqual(move.promotion_piece.?, 'q');
}

test "parseUciMove invalid format" {
    try std.testing.expectError(error.InvalidMoveFormat, parseUciMove("e2"));
    try std.testing.expectError(error.InvalidMoveFormat, parseUciMove("e2e4e5"));
}

test "parseUciMove invalid squares" {
    try std.testing.expectError(error.InvalidSquare, parseUciMove("i2e4"));
    try std.testing.expectError(error.InvalidSquare, parseUciMove("e9e4"));
    try std.testing.expectError(error.InvalidSquare, parseUciMove("e2i4"));
    try std.testing.expectError(error.InvalidSquare, parseUciMove("e2e9"));
}

test "parseUciMove invalid promotion" {
    try std.testing.expectError(error.InvalidPromotionPiece, parseUciMove("e7e8k"));
}

test "Move toUciString basic move" {
    const move = Move{ .from = c.E2, .to = c.E4, .promotion_piece = null };
    const uci = try move.toUciString();
    try std.testing.expectEqualStrings(uci[0..4], "e2e4");
    try std.testing.expectEqual(uci[4], 0);
}

test "Move toUciString promotion move" {
    const move = Move{ .from = c.E7, .to = c.E8, .promotion_piece = 'q' };
    const uci = try move.toUciString();
    try std.testing.expectEqualStrings(uci[0..5], "e7e8q");
}

/// Apply a move to a board position and return the new board state
pub fn applyMove(board: b.Board, move: Move) !b.Board {
    // First find which piece is at the 'from' position
    const piece = piecefromlocation(move.from, board);
    if (piece.position == 0) return error.InvalidMove;

    // Get valid moves for just this piece
    const valid_moves = switch (piece.representation) {
        'P', 'p' => getValidPawnMoves(piece, board),
        'R', 'r' => getValidRookMoves(piece, board),
        'N', 'n' => getValidKnightMoves(piece, board),
        'B', 'b' => getValidBishopMoves(piece, board),
        'Q', 'q' => getValidQueenMoves(piece, board),
        'K', 'k' => getValidKingMoves(piece, board),
        else => return error.InvalidMove,
    };

    // Find the matching move in valid moves
    for (valid_moves) |valid_move| {
        // Find the piece that moved by comparing board states
        var found_piece_pos: u64 = 0;

        // Check white pieces
        inline for (std.meta.fields(@TypeOf(valid_move.position.whitepieces))) |field| {
            const old_piece = @field(board.position.whitepieces, field.name);
            const new_piece = @field(valid_move.position.whitepieces, field.name);

            if (@TypeOf(old_piece) == b.Piece) {
                if (old_piece.position == move.from) {
                    found_piece_pos = new_piece.position;
                }
            } else if (@TypeOf(old_piece) == [2]b.Piece or @TypeOf(old_piece) == [8]b.Piece) {
                for (old_piece, 0..) |p, i| {
                    if (p.position == move.from) {
                        found_piece_pos = new_piece[i].position;
                    }
                }
            }
        }

        // Check black pieces if we haven't found the move
        if (found_piece_pos == 0) {
            inline for (std.meta.fields(@TypeOf(valid_move.position.blackpieces))) |field| {
                const old_piece = @field(board.position.blackpieces, field.name);
                const new_piece = @field(valid_move.position.blackpieces, field.name);

                if (@TypeOf(old_piece) == b.Piece) {
                    if (old_piece.position == move.from) {
                        found_piece_pos = new_piece.position;
                    }
                } else if (@TypeOf(old_piece) == [2]b.Piece or @TypeOf(old_piece) == [8]b.Piece) {
                    for (old_piece, 0..) |p, i| {
                        if (p.position == move.from) {
                            found_piece_pos = new_piece[i].position;
                        }
                    }
                }
            }
        }

        // If this valid move matches our input move, return it
        var result = valid_move;
        if (found_piece_pos == move.to) {
            // Handle promotion if specified
            if (move.promotion_piece) |promotion| {
                // Find the pawn that was promoted and update its representation
                if (board.position.sidetomove == 0) {
                    // White pawn promotion
                    for (&result.position.whitepieces.Pawn) |*p| {
                        if (p.position == move.to) {
                            p.representation = std.ascii.toUpper(promotion);
                            break;
                        }
                    }
                } else {
                    // Black pawn promotion
                    for (&result.position.blackpieces.Pawn) |*p| {
                        if (p.position == move.to) {
                            p.representation = promotion;
                            break;
                        }
                    }
                }
                //  update side to move
                result.position.sidetomove = 1 - board.position.sidetomove;
                return result;
            }
            result.position.sidetomove = 1 - board.position.sidetomove;
            return result;
        }
    }

    return error.InvalidMove;
}

test "applyMove basic pawn move" {
    const board = b.Board{ .position = b.Position.init() };
    const move = Move{
        .from = c.E2,
        .to = c.E4,
        .promotion_piece = null,
    };

    const new_board = try applyMove(board, move);
    try std.testing.expectEqual(new_board.position.whitepieces.Pawn[4].position, c.E4);
}

test "applyMove pawn capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Set up a capture position
    board.position.whitepieces.Pawn[0].position = c.E4;
    board.position.blackpieces.Pawn[0].position = c.F5;

    const move = Move{
        .from = c.E4,
        .to = c.F5,
        .promotion_piece = null,
    };

    const new_board = try applyMove(board, move);
    try std.testing.expectEqual(new_board.position.whitepieces.Pawn[0].position, c.F5);
    try std.testing.expectEqual(new_board.position.blackpieces.Pawn[0].position, 0);
}

test "applyMove pawn promotion" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Set up a promotion position
    board.position.whitepieces.Pawn[0].position = c.E7;

    const move = Move{
        .from = c.E7,
        .to = c.E8,
        .promotion_piece = 'q',
    };

    const new_board = try applyMove(board, move);
    try std.testing.expectEqual(new_board.position.whitepieces.Pawn[0].position, c.E8);
    try std.testing.expectEqual(new_board.position.whitepieces.Pawn[0].representation, 'Q');
}

test "applyMove invalid move" {
    const board = b.Board{ .position = b.Position.init() };
    const move = Move{
        .from = c.E2,
        .to = c.E5, // Invalid - pawn can't move 3 squares
        .promotion_piece = null,
    };

    try std.testing.expectError(error.InvalidMove, applyMove(board, move));
}

test "applyMove castling" {
    var board = b.Board{ .position = b.Position.init() };
    // Clear pieces between king and rook
    board.position.whitepieces.Knight[1].position = 0;
    board.position.whitepieces.Bishop[1].position = 0;

    const move = Move{
        .from = c.E1,
        .to = c.G1,
        .promotion_piece = null,
    };

    const new_board = try applyMove(board, move);
    try std.testing.expectEqual(new_board.position.whitepieces.King.position, c.G1);
    try std.testing.expectEqual(new_board.position.whitepieces.Rook[1].position, c.F1);
}

test "debug knight move sequence" {
    var board = b.Board{ .position = b.Position.init() };

    // Move sequence with verification
    const moves = [_]Move{
        Move{ .from = c.B1, .to = c.C3, .promotion_piece = null }, // white knight
        Move{ .from = c.C7, .to = c.C6, .promotion_piece = null }, // black pawn
        Move{ .from = c.C3, .to = c.D5, .promotion_piece = null }, // white knight
        Move{ .from = c.C6, .to = c.D5, .promotion_piece = null }, // black pawn captures
        Move{ .from = c.G1, .to = c.H3, .promotion_piece = null }, // white knight
        Move{ .from = c.F7, .to = c.F6, .promotion_piece = null }, // black pawn
        Move{ .from = c.H3, .to = c.G5, .promotion_piece = null }, // white knight
        Move{ .from = c.F6, .to = c.G5, .promotion_piece = null }, // black pawn captures
        Move{ .from = c.A2, .to = c.A3, .promotion_piece = null }, // white pawn
        Move{ .from = c.G8, .to = c.F6, .promotion_piece = null }, // black knight
    };

    std.debug.print("\nInitial position:\n", .{});
    _ = board.print();

    for (moves, 0..) |move, i| {
        board = try applyMove(board, move);
        std.debug.print("\nAfter move {d}:\n", .{i + 1});
        _ = board.print();
        std.debug.print("Side to move: {d}\n", .{board.position.sidetomove});
    }
}

test "allvalidmoves when in check only returns moves that get out of check" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Set up a check position: white king on e1, black queen on e8 (checking the king)
    board.position.whitepieces.King.position = c.E1;
    board.position.blackpieces.Queen.position = c.E8;

    // Add a white piece that can block the check
    board.position.whitepieces.Rook[0].position = c.D1;

    // Set white to move
    board.position.sidetomove = 0;

    // Get all valid moves
    const moves = allvalidmoves(board);

    // Verify that we have at least one valid move
    try std.testing.expect(moves.len > 0);

    // Verify that all returned moves get out of check
    const s = @import("state.zig");
    for (moves) |move| {
        try std.testing.expect(!s.isCheck(move, true));
    }

    // Verify that at least one move is the king moving or the rook blocking
    var foundValidMove = false;

    for (moves) |move| {
        if (move.position.whitepieces.King.position != c.E1 or
            move.position.whitepieces.Rook[0].position == c.E1)
        {
            foundValidMove = true;
            break;
        }
    }

    try std.testing.expect(foundValidMove);
}

test "allvalidmoves allows capturing the checking piece" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Set up a check position: white king on e4, black knight on f6 (checking the king)
    board.position.whitepieces.King.position = c.E4;
    board.position.blackpieces.Knight[0].position = c.F6;

    // Add a white piece that can capture the knight
    board.position.whitepieces.Bishop[0].position = c.G5;

    // Set white to move
    board.position.sidetomove = 0;

    // Get all valid moves
    const moves = allvalidmoves(board);

    // Verify that all returned moves get out of check
    const s = @import("state.zig");
    for (moves) |move| {
        try std.testing.expect(!s.isCheck(move, true));
    }

    // Verify that one of the moves is the bishop capturing the knight
    var foundCapture = false;
    for (moves) |move| {
        if (move.position.whitepieces.Bishop[0].position == c.F6 and
            move.position.blackpieces.Knight[0].position == 0)
        {
            foundCapture = true;
            break;
        }
    }

    try std.testing.expect(foundCapture);
}

test "allvalidmoves alternates side to move between plies" {
    var board = b.Board{ .position = b.Position.init() };

    // Ensure we start with white to move
    board.position.sidetomove = 0;

    const first_moves = allvalidmoves(board);
    try std.testing.expect(first_moves.len > 0);
    const board_after_white = first_moves[0];
    try std.testing.expectEqual(@as(u8, 1), board_after_white.position.sidetomove);

    const second_moves = allvalidmoves(board_after_white);
    try std.testing.expect(second_moves.len > 0);
    const board_after_black = second_moves[0];
    try std.testing.expectEqual(@as(u8, 0), board_after_black.position.sidetomove);
}
