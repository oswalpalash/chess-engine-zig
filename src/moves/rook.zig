const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

pub fn getValidRookMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    var index: usize = 0; // Initialize with a default value

    const next_side: u8 = if (board.position.sidetomove == 0) 1 else 0;
    const from_square = piece.position;

    // Find which rook we're moving
    if (piece.color == 0) {
        for (board.position.whitepieces.Rook, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    } else {
        for (board.position.blackpieces.Rook, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    }

    const row: u64 = board_helpers.rowfrombitmap(piece.position);
    const col: u64 = board_helpers.colfrombitmap(piece.position);

    // Define the four directions a rook can move: up, down, left, right
    const directions = [_]struct { shift: i8, max_steps: u6 }{
        .{ .shift = 8, .max_steps = @intCast(8 - row) }, // up
        .{ .shift = -8, .max_steps = @intCast(row - 1) }, // down
        .{ .shift = -1, .max_steps = @intCast(col - 1) }, // left
        .{ .shift = 1, .max_steps = @intCast(8 - col) }, // right
    };

    // Check moves in each direction
    for (directions) |dir| {
        if (dir.max_steps == 0) continue;

        var steps: u6 = 1;
        while (steps <= dir.max_steps) : (steps += 1) {
            const shift: i8 = dir.shift * @as(i8, @intCast(steps));
            var newpos: u64 = undefined;

            if (shift > 0) {
                newpos = piece.position << @as(u6, @intCast(shift));
            } else {
                newpos = piece.position >> @as(u6, @intCast(-shift));
            }

            if (newpos == 0) break;

            // Check if square is empty
            if (bitmap & newpos == 0) {
                var newBoard = b.Board{ .position = board.position };
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Rook[index].position = newpos;
                    if (from_square == c.A1) {
                        newBoard.position.canCastleWhiteQueenside = false;
                    } else if (from_square == c.H1) {
                        newBoard.position.canCastleWhiteKingside = false;
                    }
                } else {
                    newBoard.position.blackpieces.Rook[index].position = newpos;
                    if (from_square == c.A8) {
                        newBoard.position.canCastleBlackQueenside = false;
                    } else if (from_square == c.H8) {
                        newBoard.position.canCastleBlackKingside = false;
                    }
                }
                newBoard.position.sidetomove = next_side;
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            } else {
                // Square is occupied - check if it's an enemy piece
                const targetPiece = board_helpers.piecefromlocation(newpos, board);
                if (targetPiece.color != piece.color) {
                    var newBoard = if (piece.color == 0)
                        board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                    else
                        board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });

                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Rook[index].position = newpos;
                        if (from_square == c.A1) {
                            newBoard.position.canCastleWhiteQueenside = false;
                        } else if (from_square == c.H1) {
                            newBoard.position.canCastleWhiteKingside = false;
                        }
                    } else {
                        newBoard.position.blackpieces.Rook[index].position = newpos;
                        if (from_square == c.A8) {
                            newBoard.position.canCastleBlackQueenside = false;
                        } else if (from_square == c.H8) {
                            newBoard.position.canCastleBlackKingside = false;
                        }
                    }
                    newBoard.position.sidetomove = next_side;
                    moves[possiblemoves] = newBoard;
                    possiblemoves += 1;
                }
                break; // Stop checking this direction after hitting any piece
            }
        }
    }

    return moves[0..possiblemoves];
}

test "getValidRookMoves for empty board with rook on e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.E4;
    const moves = getValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // 7 horizontal + 7 vertical moves
}

test "getValidRookMoves for black rook captures" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Rook[0].position = c.E4;
    board.position.whitepieces.Pawn[0].position = c.E6; // Can be captured
    board.position.whitepieces.Pawn[1].position = c.C4; // Can be captured
    board.position.blackpieces.Pawn[0].position = c.E3; // Blocks movement

    const moves = getValidRookMoves(board.position.blackpieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 8); // 2 captures + 6 empty squares

    // Verify captures are possible
    var foundCaptures = false;
    for (moves) |move| {
        if (move.position.whitepieces.Pawn[0].position == 0 or
            move.position.whitepieces.Pawn[1].position == 0)
        {
            foundCaptures = true;
            break;
        }
    }
    try std.testing.expect(foundCaptures);
}

test "getValidRookMoves blocked by own pieces" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.E4;
    // Place friendly pieces to block in all directions
    board.position.whitepieces.Pawn[0].position = c.E5;
    board.position.whitepieces.Pawn[1].position = c.E3;
    board.position.whitepieces.Pawn[2].position = c.D4;
    board.position.whitepieces.Pawn[3].position = c.F4;

    const moves = getValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 0); // No moves possible
}

test "getValidRookMoves edge cases" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Test from corner
    board.position.whitepieces.Rook[0].position = c.A1;
    var moves = getValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // 7 up + 7 right

    // Test from edge
    board.position.whitepieces.Rook[0].position = c.A4;
    moves = getValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // 7 horizontal + 7 vertical
}

// New test to verify that the black rook at A8 in the initial board has 0 moves
test "ValidRookMoves for black rook at a8 in initial board" {
    const board = b.Board{ .position = b.Position.init() };
    // Based on our board setup, the black rook at A8 is stored in blackpieces.Rook[1]
    const moves = getValidRookMoves(board.position.blackpieces.Rook[1], board);
    try std.testing.expectEqual(moves.len, 0);
}

test "rook move clears white kingside castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E1;
    board.position.whitepieces.Rook[1].position = c.H1;
    board.position.canCastleWhiteKingside = true;

    const moves = getValidRookMoves(board.position.whitepieces.Rook[1], board);
    var found = false;
    for (moves) |move| {
        if (move.position.whitepieces.Rook[1].position == c.H2) {
            found = true;
            try std.testing.expectEqual(false, move.position.canCastleWhiteKingside);
        }
    }
    try std.testing.expect(found);
}

test "rook move clears white queenside castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E1;
    board.position.whitepieces.Rook[0].position = c.A1;
    board.position.canCastleWhiteQueenside = true;

    const moves = getValidRookMoves(board.position.whitepieces.Rook[0], board);
    var found = false;
    for (moves) |move| {
        if (move.position.whitepieces.Rook[0].position == c.A2) {
            found = true;
            try std.testing.expectEqual(false, move.position.canCastleWhiteQueenside);
        }
    }
    try std.testing.expect(found);
}

test "rook move clears black kingside castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E8;
    board.position.blackpieces.Rook[1].position = c.H8;
    board.position.canCastleBlackKingside = true;

    const moves = getValidRookMoves(board.position.blackpieces.Rook[1], board);
    var found = false;
    for (moves) |move| {
        if (move.position.blackpieces.Rook[1].position == c.H7) {
            found = true;
            try std.testing.expectEqual(false, move.position.canCastleBlackKingside);
        }
    }
    try std.testing.expect(found);
}

test "rook move clears black queenside castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E8;
    board.position.blackpieces.Rook[0].position = c.A8;
    board.position.canCastleBlackQueenside = true;

    const moves = getValidRookMoves(board.position.blackpieces.Rook[0], board);
    var found = false;
    for (moves) |move| {
        if (move.position.blackpieces.Rook[0].position == c.A7) {
            found = true;
            try std.testing.expectEqual(false, move.position.canCastleBlackQueenside);
        }
    }
    try std.testing.expect(found);
}
