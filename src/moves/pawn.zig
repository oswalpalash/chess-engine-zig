const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");
const knight_moves = @import("knight.zig");

const promotion_pieces = [_]u8{ 'q', 'r', 'b', 'n' };

fn clearPawnSlot(position: *b.Position, color: u8, index: usize) void {
    if (color == 0) {
        position.whitepieces.Pawn[index] = b.WhitePawn;
        position.whitepieces.Pawn[index].position = 0;
        position.whitepieces.Pawn[index].index = @intCast(index);
    } else {
        position.blackpieces.Pawn[index] = b.BlackPawn;
        position.blackpieces.Pawn[index].position = 0;
        position.blackpieces.Pawn[index].index = @intCast(index);
    }
}

// Returns an array of boards representing all possible moves for the given pawn
pub fn getValidPawnMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u6 = 0;
    var index: u64 = 0;

    const next_side: u8 = if (board.position.sidetomove == 0) 1 else 0;

    // Find which pawn we're moving
    if (piece.color == 0) {
        for (board.position.whitepieces.Pawn, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    } else {
        for (board.position.blackpieces.Pawn, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    }

    const currentRow = board_helpers.rowfrombitmap(piece.position);
    const currentCol = board_helpers.colfrombitmap(piece.position);

    // Direction modifiers based on piece color
    const forwardShift: i8 = if (piece.color == 0) 8 else -8;

    // Starting row and promotion row based on color
    const startingRow: u64 = if (piece.color == 0) 2 else 7;

    // Single square forward move
    var oneSquareForward: u64 = 0;
    if (forwardShift > 0) {
        oneSquareForward = piece.position << @as(u6, @intCast(forwardShift));
    } else {
        oneSquareForward = piece.position >> @as(u6, @intCast(-forwardShift));
    }

    if (bitmap & oneSquareForward == 0) {
        if ((piece.color == 0 and currentRow < 7) or (piece.color == 1 and currentRow > 2)) {
            // Regular move
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = oneSquareForward;
            } else {
                newBoard.position.blackpieces.Pawn[index].position = oneSquareForward;
            }
            newBoard.position.enPassantSquare = 0;
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
            // Promotion
            for (promotion_pieces) |promo| {
                var newBoard = b.Board{ .position = board.position };
                clearPawnSlot(&newBoard.position, piece.color, @intCast(index));
                newBoard.position.enPassantSquare = 0;
                board_helpers.addPromotedPiece(&newBoard.position, piece.color, promo, oneSquareForward) catch unreachable;
                newBoard.position.sidetomove = next_side;
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        }

        // Two square forward move from starting position
        if (currentRow == startingRow) {
            var twoSquareForward: u64 = 0;
            if (forwardShift > 0) {
                twoSquareForward = piece.position << @as(u6, @intCast(forwardShift * 2));
            } else {
                twoSquareForward = piece.position >> @as(u6, @intCast(-forwardShift * 2));
            }

            if (bitmap & twoSquareForward == 0) {
                var newBoard = b.Board{ .position = board.position };
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Pawn[index].position = twoSquareForward;
                    // Set en passant square
                    newBoard.position.enPassantSquare = oneSquareForward;
                } else {
                    newBoard.position.blackpieces.Pawn[index].position = twoSquareForward;
                    newBoard.position.enPassantSquare = oneSquareForward;
                }
                newBoard.position.sidetomove = next_side;
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        }
    }

    // Diagonal captures
    var leftCapture: u64 = 0;
    var rightCapture: u64 = 0;

    // Calculate capture positions based on color and column constraints
    if (piece.color == 0) {
        leftCapture = if (currentCol > 1) piece.position << 7 else 0;
        rightCapture = if (currentCol < 8) piece.position << 9 else 0;
    } else {
        leftCapture = if (currentCol < 8) piece.position >> 7 else 0;
        rightCapture = if (currentCol > 1) piece.position >> 9 else 0;
    }

    // Check left capture
    if (leftCapture != 0) {
        if (bitmap & leftCapture != 0) {
            const targetPiece = board_helpers.piecefromlocation(leftCapture, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(leftCapture, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(leftCapture, b.Board{ .position = board.position });

                if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
                    for (promotion_pieces) |promo| {
                        var promoBoard = newBoard;
                        clearPawnSlot(&promoBoard.position, piece.color, @intCast(index));
                        promoBoard.position.enPassantSquare = 0;
                        board_helpers.addPromotedPiece(&promoBoard.position, piece.color, promo, leftCapture) catch unreachable;
                        promoBoard.position.sidetomove = next_side;
                        moves[possiblemoves] = promoBoard;
                        possiblemoves += 1;
                    }
                } else {
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = leftCapture;
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = leftCapture;
                    }
                    newBoard.position.enPassantSquare = 0;
                    newBoard.position.sidetomove = next_side;
                    moves[possiblemoves] = newBoard;
                    possiblemoves += 1;
                }
            }
        } else if (leftCapture == board.position.enPassantSquare) {
            // En passant capture to the left
            var newBoard = b.Board{ .position = board.position };
            var capturedPawnPos: u64 = 0;

            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = leftCapture;
                // Capture the black pawn that just moved (one square behind the en passant square)
                capturedPawnPos = leftCapture >> 8;
                newBoard = board_helpers.captureblackpiece(capturedPawnPos, newBoard);
            } else {
                newBoard.position.blackpieces.Pawn[index].position = leftCapture;
                // Capture the white pawn that just moved (one square ahead of the en passant square)
                capturedPawnPos = leftCapture << 8;
                newBoard = board_helpers.capturewhitepiece(capturedPawnPos, newBoard);
            }
            newBoard.position.enPassantSquare = 0; // Clear en passant square
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    // Check right capture
    if (rightCapture != 0) {
        if (bitmap & rightCapture != 0) {
            const targetPiece = board_helpers.piecefromlocation(rightCapture, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(rightCapture, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(rightCapture, b.Board{ .position = board.position });

                if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
                    for (promotion_pieces) |promo| {
                        var promoBoard = newBoard;
                        clearPawnSlot(&promoBoard.position, piece.color, @intCast(index));
                        promoBoard.position.enPassantSquare = 0;
                        board_helpers.addPromotedPiece(&promoBoard.position, piece.color, promo, rightCapture) catch unreachable;
                        promoBoard.position.sidetomove = next_side;
                        moves[possiblemoves] = promoBoard;
                        possiblemoves += 1;
                    }
                } else {
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = rightCapture;
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = rightCapture;
                    }
                    newBoard.position.enPassantSquare = 0;
                    newBoard.position.sidetomove = next_side;
                    moves[possiblemoves] = newBoard;
                    possiblemoves += 1;
                }
            }
        } else if (rightCapture == board.position.enPassantSquare) {
            // En passant capture to the right
            var newBoard = b.Board{ .position = board.position };
            var capturedPawnPos: u64 = 0;

            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = rightCapture;
                // Capture the black pawn that just moved
                capturedPawnPos = rightCapture >> 8;
                newBoard = board_helpers.captureblackpiece(capturedPawnPos, newBoard);
            } else {
                newBoard.position.blackpieces.Pawn[index].position = rightCapture;
                // Capture the white pawn that just moved
                capturedPawnPos = rightCapture << 8;
                newBoard = board_helpers.capturewhitepiece(capturedPawnPos, newBoard);
            }
            newBoard.position.enPassantSquare = 0; // Clear en passant square
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    return moves[0..possiblemoves];
}

test "getValidPawnMoves from e2 in start position" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2);
}

test "getValidPawnMoves from e7 in empty board" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[3].position = c.E7;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 4);
}

test "getValidPawnMoves for black pawn from e7 in start position" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidPawnMoves(board.position.blackpieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2); // e7 pawn can move to e6 and e5
}

test "getValidPawnMoves for black pawn from e2 in empty board" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[3].position = c.E2;
    const moves = getValidPawnMoves(board.position.blackpieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 4); // Promotions to Q, R, B, N
    var found = [_]bool{ false, false, false, false };
    for (moves) |move| {
        try std.testing.expectEqual(move.position.blackpieces.Pawn[3].position, 0);
        const promoted = board_helpers.piecefromlocation(c.E1, move);
        switch (promoted.representation) {
            'q' => found[0] = true,
            'r' => found[1] = true,
            'b' => found[2] = true,
            'n' => found[3] = true,
            else => {},
        }
    }
    for (found) |flag| try std.testing.expect(flag);
}

test "getValidPawnMoves for black pawn capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[3].position = c.E6;
    board.position.whitepieces.Pawn[2].position = c.D5;
    const moves = getValidPawnMoves(board.position.blackpieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 2); // Can move to e5 or capture on d5

    var foundCapture = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[3].position == c.D5) {
            foundCapture = true;
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
        }
    }
    try std.testing.expect(foundCapture);
}

test "getValidPawnMoves for black pawn en passant capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[3].position = c.E4;
    board.position.whitepieces.Pawn[2].position = c.D4;
    board.position.enPassantSquare = c.D3; // Simulate white pawn just moved D2->D4
    const moves = getValidPawnMoves(board.position.blackpieces.Pawn[3], board);

    var foundEnPassant = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[3].position == c.D3) {
            foundEnPassant = true;
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
            try std.testing.expectEqual(move.position.enPassantSquare, 0);
        }
    }
    try std.testing.expect(foundEnPassant);
}

test "getValidPawnMoves for black pawn promotion on capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[3].position = c.E2;
    board.position.whitepieces.Pawn[2].position = c.D1;
    const moves = getValidPawnMoves(board.position.blackpieces.Pawn[3], board);

    try std.testing.expectEqual(moves.len, 8);
    var foundCapture = [_]bool{ false, false, false, false };
    var foundAdvance = [_]bool{ false, false, false, false };
    for (moves) |move| {
        try std.testing.expectEqual(move.position.blackpieces.Pawn[3].position, 0);
        const dest: u64 = if (move.position.whitepieces.Pawn[2].position == 0) c.D1 else c.E1;
        const promoted = board_helpers.piecefromlocation(dest, move);
        switch (promoted.representation) {
            'q' => {
                if (dest == c.D1) {
                    foundCapture[0] = true;
                } else {
                    foundAdvance[0] = true;
                }
            },
            'r' => {
                if (dest == c.D1) {
                    foundCapture[1] = true;
                } else {
                    foundAdvance[1] = true;
                }
            },
            'b' => {
                if (dest == c.D1) {
                    foundCapture[2] = true;
                } else {
                    foundAdvance[2] = true;
                }
            },
            'n' => {
                if (dest == c.D1) {
                    foundCapture[3] = true;
                } else {
                    foundAdvance[3] = true;
                }
            },
            else => {},
        }
    }
    for (foundCapture) |flag| try std.testing.expect(flag);
    for (foundAdvance) |flag| try std.testing.expect(flag);
}

test "getValidPawnMoves promotion on reaching 8th rank" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 4);
    var found = [_]bool{ false, false, false, false };
    for (moves) |move| {
        try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);
        const promoted = board_helpers.piecefromlocation(c.E8, move);
        switch (promoted.representation) {
            'Q' => found[0] = true,
            'R' => found[1] = true,
            'B' => found[2] = true,
            'N' => found[3] = true,
            else => {},
        }
    }
    for (found) |flag| try std.testing.expect(flag);
}

test "getValidPawnMoves promotion on capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    board.position.blackpieces.Pawn[0].position = c.F8;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 8);
    var foundForward = [_]bool{ false, false, false, false };
    var foundCapture = [_]bool{ false, false, false, false };
    for (moves) |move| {
        try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);
        const dest: u64 = if (move.position.blackpieces.Pawn[0].position == 0) c.F8 else c.E8;
        const promoted = board_helpers.piecefromlocation(dest, move);
        switch (promoted.representation) {
            'Q' => {
                if (dest == c.F8) {
                    foundCapture[0] = true;
                } else {
                    foundForward[0] = true;
                }
            },
            'R' => {
                if (dest == c.F8) {
                    foundCapture[1] = true;
                } else {
                    foundForward[1] = true;
                }
            },
            'B' => {
                if (dest == c.F8) {
                    foundCapture[2] = true;
                } else {
                    foundForward[2] = true;
                }
            },
            'N' => {
                if (dest == c.F8) {
                    foundCapture[3] = true;
                } else {
                    foundForward[3] = true;
                }
            },
            else => {},
        }
    }
    for (foundForward) |flag| try std.testing.expect(flag);
    for (foundCapture) |flag| try std.testing.expect(flag);
}

test "promoted knight can move" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);

    var knight_board: ?b.Board = null;
    for (moves) |move| {
        if (board_helpers.piecefromlocation(c.E8, move).representation == 'N') {
            knight_board = move;
            break;
        }
    }
    try std.testing.expect(knight_board != null);

    var promoted_knight: ?b.Piece = null;
    for (knight_board.?.position.whitepieces.PromotedKnight) |knight| {
        if (knight.position != 0) {
            promoted_knight = knight;
            break;
        }
    }
    try std.testing.expect(promoted_knight != null);

    const knightMoves = knight_moves.getValidKnightMoves(promoted_knight.?, knight_board.?);
    try std.testing.expect(knightMoves.len > 0);
}

test "getValidPawnMoves en passant capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E5;
    board.position.blackpieces.Pawn[0].position = c.F5;
    board.position.enPassantSquare = c.F6; // Simulate black pawn just moved F7->F5
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 2); // Forward move and en passant capture
    var foundEnPassant = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[0].position == 0 and
            move.position.whitepieces.Pawn[0].position == c.F6)
        {
            foundEnPassant = true;
            try std.testing.expectEqual(move.position.enPassantSquare, 0);
        }
    }
    try std.testing.expect(foundEnPassant);
}

test "getValidPawnMoves blocked by own piece" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E2;
    board.position.whitepieces.Pawn[1].position = c.E3;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 0);
}

test "getValidPawnMoves two square move sets en passant square" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E2;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 2);
    var foundTwoSquare = false;
    for (moves) |move| {
        if (move.position.whitepieces.Pawn[0].position == c.E4) {
            foundTwoSquare = true;
            try std.testing.expectEqual(move.position.enPassantSquare, c.E3);
        }
    }
    try std.testing.expect(foundTwoSquare);
}
