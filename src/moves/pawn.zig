const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

// Returns an array of boards representing all possible moves for the given pawn
pub fn getValidPawnMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u6 = 0;
    var index: u64 = 0;

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
            newBoard.position.enPassantSquare = 0;
            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = oneSquareForward;
            } else {
                newBoard.position.blackpieces.Pawn[index].position = oneSquareForward;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
            // Promotion
            var newBoard = b.Board{ .position = board.position };
            newBoard.position.enPassantSquare = 0;
            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = oneSquareForward;
                newBoard.position.whitepieces.Pawn[index].representation = 'Q';
            } else {
                newBoard.position.blackpieces.Pawn[index].position = oneSquareForward;
                newBoard.position.blackpieces.Pawn[index].representation = 'q';
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
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
                newBoard.position.enPassantSquare = 0;
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Pawn[index].position = twoSquareForward;
                    // Set en passant square
                    newBoard.position.enPassantSquare = oneSquareForward;
                } else {
                    newBoard.position.blackpieces.Pawn[index].position = twoSquareForward;
                    newBoard.position.enPassantSquare = oneSquareForward;
                }
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
                newBoard.position.enPassantSquare = 0;

                if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
                    // Promotion on capture
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = leftCapture;
                        newBoard.position.whitepieces.Pawn[index].representation = 'Q';
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = leftCapture;
                        newBoard.position.blackpieces.Pawn[index].representation = 'q';
                    }
                } else {
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = leftCapture;
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = leftCapture;
                    }
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        } else if (leftCapture == board.position.enPassantSquare) {
            // En passant capture to the left
            var newBoard = b.Board{ .position = board.position };
            newBoard.position.enPassantSquare = 0;
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
                newBoard.position.enPassantSquare = 0;

                if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
                    // Promotion on capture
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = rightCapture;
                        newBoard.position.whitepieces.Pawn[index].representation = 'Q';
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = rightCapture;
                        newBoard.position.blackpieces.Pawn[index].representation = 'q';
                    }
                } else {
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = rightCapture;
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = rightCapture;
                    }
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        } else if (rightCapture == board.position.enPassantSquare) {
            // En passant capture to the right
            var newBoard = b.Board{ .position = board.position };
            newBoard.position.enPassantSquare = 0;
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
    try std.testing.expectEqual(moves.len, 1);
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
    try std.testing.expectEqual(moves.len, 1); // One move to e1 with promotion
    try std.testing.expectEqual(moves[0].position.blackpieces.Pawn[3].representation, 'q');
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

    var foundPromotionCapture = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[3].position == c.D1) {
            foundPromotionCapture = true;
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
            try std.testing.expectEqual(move.position.blackpieces.Pawn[3].representation, 'q');
        }
    }
    try std.testing.expect(foundPromotionCapture);
}

test "getValidPawnMoves promotion on reaching 8th rank" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 1);
    try std.testing.expectEqual(moves[0].position.whitepieces.Pawn[0].representation, 'Q');
}

test "getValidPawnMoves promotion on capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    board.position.blackpieces.Pawn[0].position = c.F8;
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 2); // One forward promotion, one capture promotion
    var foundCapture = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[0].position == 0) {
            foundCapture = true;
            try std.testing.expectEqual(move.position.whitepieces.Pawn[0].representation, 'Q');
        }
    }
    try std.testing.expect(foundCapture);
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
