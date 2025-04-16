const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");
const std = @import("std");

pub fn getValidKnightMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;

    // Find the correct index for the knight
    var index: u8 = 0;
    if (piece.color == 0) {
        // White knight
        if (board.position.whitepieces.Knight[0].position == piece.position) {
            index = 0;
        } else if (board.position.whitepieces.Knight[1].position == piece.position) {
            index = 1;
        } else {
            // Knight not found, return empty array
            return moves[0..0];
        }
    } else {
        // Black knight
        if (board.position.blackpieces.Knight[0].position == piece.position) {
            index = 0;
        } else if (board.position.blackpieces.Knight[1].position == piece.position) {
            index = 1;
        } else {
            // Knight not found, return empty array
            return moves[0..0];
        }
    }

    // Define all possible knight move shifts
    // These represent the 8 possible L-shaped moves a knight can make
    const knightShifts = [_]struct { shift: i8, mask: u64 }{
        .{ .shift = 6, .mask = 0xFCFCFCFCFCFCFCFC }, // Up 1, Left 2 (not from a,b files)
        .{ .shift = 10, .mask = 0x3F3F3F3F3F3F3F3F }, // Up 1, Right 2 (not from g,h files)
        .{ .shift = 15, .mask = 0xFEFEFEFEFEFEFEFE }, // Up 2, Left 1 (not from a file)
        .{ .shift = 17, .mask = 0x7F7F7F7F7F7F7F7F }, // Up 2, Right 1 (not from h file)
        .{ .shift = -6, .mask = 0x3F3F3F3F3F3F3F3F }, // Down 1, Right 2 (not from g,h files)
        .{ .shift = -10, .mask = 0xFCFCFCFCFCFCFCFC }, // Down 1, Left 2 (not from a,b files)
        .{ .shift = -15, .mask = 0x7F7F7F7F7F7F7F7F }, // Down 2, Right 1 (not from h file)
        .{ .shift = -17, .mask = 0xFEFEFEFEFEFEFEFE }, // Down 2, Left 1 (not from a file)
    };

    // Check each possible knight move
    for (knightShifts) |move| {
        // Apply the mask to ensure we don't wrap around the board
        if ((piece.position & move.mask) == 0) continue;

        var newpos: u64 = undefined;
        if (move.shift > 0) {
            newpos = piece.position << @as(u6, @intCast(move.shift));
        } else {
            newpos = piece.position >> @as(u6, @intCast(-move.shift));
        }

        // Skip if the position is invalid (should not happen with proper masks)
        if (newpos == 0) continue;

        // Check if target square is empty
        if (bitmap & newpos == 0) {
            // Empty square - add move
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Knight[index].position = newpos;
            } else {
                newBoard.position.blackpieces.Knight[index].position = newpos;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            // Square is occupied - check if it's an enemy piece
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                // Capture enemy piece
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });

                if (piece.color == 0) {
                    newBoard.position.whitepieces.Knight[index].position = newpos;
                } else {
                    newBoard.position.blackpieces.Knight[index].position = newpos;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        }
    }

    return moves[0..possiblemoves];
}

test "getValidKnightMoves works for white knights" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // b1 knight can move to a3 and c3
}

test "getValidKnightMoves works for black knights" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidKnightMoves(board.position.blackpieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // b8 knight can move to a6 and c6
}

test "ValidKnightMoves for empty board with knight on e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.E4;
    _ = board.print();
    const moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 8); // Knight should have all 8 possible moves
}

test "ValidKnightMoves for init board with knight on b1" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to a3 and c3
}

test "ValidKnightMoves for empty board with knight on b1 and black piece on c3" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.B1;
    board.position.blackpieces.Pawn[2].position = c.C3;
    const moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 3); // Can move to a3, c3 (capture), and d2
}

test "ValidKnightMoves for corner positions" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Test from a1 corner
    board.position.whitepieces.Knight[0].position = c.A1;
    var moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to b3 and c2

    // Test from h8 corner
    board.position.whitepieces.Knight[0].position = c.H8;
    moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to f7 and g6
}

test "ValidKnightMoves with both knights" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.B1;
    board.position.whitepieces.Knight[1].position = c.G1;

    const moves1 = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves1.len, 3); // Can move to a3, c3, and d2

    const moves2 = getValidKnightMoves(board.position.whitepieces.Knight[1], board);
    try std.testing.expectEqual(moves2.len, 3); // Can move to e2, f3, and h3
}

test "ValidKnightMoves captures" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.E4;

    // Place some black pieces in knight's path
    board.position.blackpieces.Pawn[0].position = c.F6; // Can be captured
    board.position.blackpieces.Pawn[1].position = c.D6; // Can be captured
    board.position.whitepieces.Pawn[0].position = c.G5; // Blocked by own piece

    const moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 7); // 8 possible moves - 1 blocked by own piece

    // Verify captures are possible
    var foundCaptures = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[0].position == 0 or
            move.position.blackpieces.Pawn[1].position == 0)
        {
            foundCaptures = true;
            break;
        }
    }
    try std.testing.expect(foundCaptures);
}

test "ValidKnightMoves unordered test for knight on b1" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.B1;
    const moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    var foundC3 = false;
    var foundA3 = false;
    for (moves) |move| {
        const newPos = move.position.whitepieces.Knight[0].position;
        if (newPos == c.C3) foundC3 = true;
        if (newPos == c.A3) foundA3 = true;
    }
    try std.testing.expect(foundC3);
    try std.testing.expect(foundA3);
}
