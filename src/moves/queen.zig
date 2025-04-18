const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

pub fn getValidQueenMoves(piece: b.Piece, board: b.Board) []b.Board {
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    if (piece.position == 0) return moves[0..possiblemoves];

    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    const queen_piece: b.Piece = piece;

    const shifts = [7]u6{ 1, 2, 3, 4, 5, 6, 7 };
    const row: u64 = board_helpers.rowfrombitmap(queen_piece.position);
    const col: u64 = board_helpers.colfrombitmap(queen_piece.position);
    var newqueen: b.Piece = queen_piece;
    var testpiece: b.Piece = undefined;

    // Rook-like moves
    // Forward moves
    for (shifts) |shift| {
        if (row + shift > 8) break;
        const newpos = queen_piece.position << (shift * 8);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Backward moves
    for (shifts) |shift| {
        if (row <= shift) break;
        const newpos = queen_piece.position >> (shift * 8);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Left moves
    for (shifts) |shift| {
        if (col <= shift) break;
        const newpos = queen_piece.position << shift;
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Right moves
    for (shifts) |shift| {
        if (col + shift > 8) break;
        const newpos = queen_piece.position >> shift;
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Bishop-like moves
    // Up-Left diagonal
    for (shifts) |shift| {
        if (row + shift > 8 or col <= shift) break;
        const newpos = queen_piece.position << (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Up-Right diagonal
    for (shifts) |shift| {
        if (row + shift > 8 or col + shift > 8) break;
        const newpos = queen_piece.position << (shift * 7);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Down-Left diagonal
    for (shifts) |shift| {
        if (row <= shift or col <= shift) break;
        const newpos = queen_piece.position >> (shift * 7);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Down-Right diagonal
    for (shifts) |shift| {
        if (row <= shift or col + shift > 8) break;
        const newpos = queen_piece.position >> (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    return moves[0..possiblemoves];
}

test "getValidQueenMoves captures for black queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Queen.position = c.E4;

    // Place white pieces to capture
    board.position.whitepieces.Pawn[0].position = c.E6; // Vertical capture
    board.position.whitepieces.Pawn[1].position = c.G4; // Horizontal capture
    board.position.whitepieces.Pawn[2].position = c.G6; // Diagonal capture

    const moves = getValidQueenMoves(board.position.blackpieces.Queen, board);

    // Verify captures are possible
    var verticalCapture = false;
    var horizontalCapture = false;
    var diagonalCapture = false;

    for (moves) |move| {
        if (move.position.blackpieces.Queen.position == c.E6) {
            try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);
            verticalCapture = true;
        }
        if (move.position.blackpieces.Queen.position == c.G4) {
            try std.testing.expectEqual(move.position.whitepieces.Pawn[1].position, 0);
            horizontalCapture = true;
        }
        if (move.position.blackpieces.Queen.position == c.G6) {
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
            diagonalCapture = true;
        }
    }

    try std.testing.expect(verticalCapture);
    try std.testing.expect(horizontalCapture);
    try std.testing.expect(diagonalCapture);
}

test "getValidQueenMoves blocked by own pieces for black queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Queen.position = c.E4;

    // Place friendly pieces to block
    board.position.blackpieces.Pawn[0].position = c.E5; // Block vertical
    board.position.blackpieces.Pawn[1].position = c.F4; // Block horizontal
    board.position.blackpieces.Pawn[2].position = c.F5; // Block diagonal

    const moves = getValidQueenMoves(board.position.blackpieces.Queen, board);

    // Verify blocked squares are not in valid moves
    for (moves) |move| {
        try std.testing.expect(move.position.blackpieces.Queen.position != c.E5);
        try std.testing.expect(move.position.blackpieces.Queen.position != c.F4);
        try std.testing.expect(move.position.blackpieces.Queen.position != c.F5);
    }
}

test "getValidQueenMoves captures in all directions" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Queen.position = c.E4;

    // Place white pieces in all 8 directions
    board.position.whitepieces.Pawn[0].position = c.E5; // North
    board.position.whitepieces.Pawn[1].position = c.F5; // Northeast
    board.position.whitepieces.Pawn[2].position = c.F4; // East
    board.position.whitepieces.Pawn[3].position = c.F3; // Southeast
    board.position.whitepieces.Pawn[4].position = c.E3; // South
    board.position.whitepieces.Pawn[5].position = c.D3; // Southwest
    board.position.whitepieces.Pawn[6].position = c.D4; // West
    board.position.whitepieces.Pawn[7].position = c.D5; // Northwest

    const moves = getValidQueenMoves(board.position.blackpieces.Queen, board);

    // Should have exactly 8 capture moves
    var captureCount: usize = 0;
    for (moves) |move| {
        for (board.position.whitepieces.Pawn) |p| {
            if (move.position.blackpieces.Queen.position == p.position) {
                captureCount += 1;
            }
        }
    }

    try std.testing.expectEqual(captureCount, 8);
}
