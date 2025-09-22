const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

// Returns an array of boards representing all possible moves for the given pawn
pub fn getValidPawnMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u6 = 0;
    var index: usize = 0;

    const next_side: u8 = if (board.position.sidetomove == 0) 1 else 0;
    const promotions = [_]u8{ 'q', 'r', 'b', 'n' };

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
        if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
            for (promotions) |promo| {
                var newBoard = b.Board{ .position = board.position };
                if (piece.color == 0) {
                    newBoard.position.clearPawnSlot(0, index);
                    newBoard.position.addPromotedPiece(0, promo, oneSquareForward);
                } else {
                    newBoard.position.clearPawnSlot(1, index);
                    newBoard.position.addPromotedPiece(1, promo, oneSquareForward);
                }
                newBoard.position.enPassantSquare = 0;
                newBoard.position.sidetomove = next_side;
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        } else {
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

            // Two square forward move from starting position
            if (currentRow == startingRow) {
                var twoSquareForward: u64 = 0;
                if (forwardShift > 0) {
                    twoSquareForward = piece.position << @as(u6, @intCast(forwardShift * 2));
                } else {
                    twoSquareForward = piece.position >> @as(u6, @intCast(-forwardShift * 2));
                }

                if (bitmap & twoSquareForward == 0) {
                    var doubleBoard = b.Board{ .position = board.position };
                    if (piece.color == 0) {
                        doubleBoard.position.whitepieces.Pawn[index].position = twoSquareForward;
                        doubleBoard.position.enPassantSquare = oneSquareForward;
                    } else {
                        doubleBoard.position.blackpieces.Pawn[index].position = twoSquareForward;
                        doubleBoard.position.enPassantSquare = oneSquareForward;
                    }
                    doubleBoard.position.sidetomove = next_side;
                    moves[possiblemoves] = doubleBoard;
                    possiblemoves += 1;
                }
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
                    for (promotions) |promo| {
                        var promotedBoard = newBoard;
                        if (piece.color == 0) {
                            promotedBoard.position.clearPawnSlot(0, index);
                            promotedBoard.position.addPromotedPiece(0, promo, leftCapture);
                        } else {
                            promotedBoard.position.clearPawnSlot(1, index);
                            promotedBoard.position.addPromotedPiece(1, promo, leftCapture);
                        }
                        promotedBoard.position.enPassantSquare = 0;
                        promotedBoard.position.sidetomove = next_side;
                        moves[possiblemoves] = promotedBoard;
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
                    for (promotions) |promo| {
                        var promotedBoard = newBoard;
                        if (piece.color == 0) {
                            promotedBoard.position.clearPawnSlot(0, index);
                            promotedBoard.position.addPromotedPiece(0, promo, rightCapture);
                        } else {
                            promotedBoard.position.clearPawnSlot(1, index);
                            promotedBoard.position.addPromotedPiece(1, promo, rightCapture);
                        }
                        promotedBoard.position.enPassantSquare = 0;
                        promotedBoard.position.sidetomove = next_side;
                        moves[possiblemoves] = promotedBoard;
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
    try std.testing.expectEqual(moves.len, 4);

    var seen = [_]bool{ false, false, false, false };
    for (moves, 0..) |move, idx| {
        _ = idx;
        try std.testing.expectEqual(move.position.blackpieces.Pawn[3].position, 0);
        const promoted = board_helpers.piecefromlocation(c.E1, move);
        try std.testing.expect(promoted.is_promoted);
        try std.testing.expectEqual(promoted.color, 1);
        switch (promoted.representation) {
            'q' => seen[0] = true,
            'r' => seen[1] = true,
            'b' => seen[2] = true,
            'n' => seen[3] = true,
            else => try std.testing.expect(false),
        }
    }
    for (seen) |flag| try std.testing.expect(flag);
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

    var forward_seen = [_]bool{ false, false, false, false };
    var capture_seen = [_]bool{ false, false, false, false };
    for (moves) |move| {
        const forward = board_helpers.piecefromlocation(c.E1, move);
        if (forward.color == 1 and forward.is_promoted) {
            try std.testing.expectEqual(move.position.blackpieces.Pawn[3].position, 0);
            switch (forward.representation) {
                'q' => forward_seen[0] = true,
                'r' => forward_seen[1] = true,
                'b' => forward_seen[2] = true,
                'n' => forward_seen[3] = true,
                else => try std.testing.expect(false),
            }
            continue;
        }

        const promoted = board_helpers.piecefromlocation(c.D1, move);
        if (promoted.color == 1 and promoted.is_promoted) {
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
            switch (promoted.representation) {
                'q' => capture_seen[0] = true,
                'r' => capture_seen[1] = true,
                'b' => capture_seen[2] = true,
                'n' => capture_seen[3] = true,
                else => try std.testing.expect(false),
            }
            continue;
        }

        try std.testing.expect(false);
    }
    for (forward_seen) |flag| try std.testing.expect(flag);
    for (capture_seen) |flag| try std.testing.expect(flag);
}

test "getValidPawnMoves promotion on reaching 8th rank" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 4);

    var seen = [_]bool{ false, false, false, false };
    for (moves) |move| {
        const promoted = board_helpers.piecefromlocation(c.E8, move);
        try std.testing.expect(promoted.is_promoted);
        try std.testing.expectEqual(promoted.color, 0);
        try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);
        switch (promoted.representation) {
            'Q' => seen[0] = true,
            'R' => seen[1] = true,
            'B' => seen[2] = true,
            'N' => seen[3] = true,
            else => try std.testing.expect(false),
        }
    }
    for (seen) |flag| try std.testing.expect(flag);
}

test "getValidPawnMoves promotion on capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    board.position.blackpieces.Pawn[0].position = c.F8;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 8); // Four forward promotions and four capture promotions

    var forward_seen = [_]bool{ false, false, false, false };
    var capture_seen = [_]bool{ false, false, false, false };
    for (moves) |move| {
        const forward = board_helpers.piecefromlocation(c.E8, move);
        if (forward.color == 0 and forward.is_promoted) {
            try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);
            switch (forward.representation) {
                'Q' => forward_seen[0] = true,
                'R' => forward_seen[1] = true,
                'B' => forward_seen[2] = true,
                'N' => forward_seen[3] = true,
                else => try std.testing.expect(false),
            }
            continue;
        }

        const capture = board_helpers.piecefromlocation(c.F8, move);
        if (capture.color == 0 and capture.is_promoted) {
            try std.testing.expectEqual(move.position.blackpieces.Pawn[0].position, 0);
            switch (capture.representation) {
                'Q' => capture_seen[0] = true,
                'R' => capture_seen[1] = true,
                'B' => capture_seen[2] = true,
                'N' => capture_seen[3] = true,
                else => try std.testing.expect(false),
            }
            continue;
        }

        try std.testing.expect(false); // Unexpected board state
    }
    for (forward_seen) |flag| try std.testing.expect(flag);
    for (capture_seen) |flag| try std.testing.expect(flag);
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
