const b = @import("board.zig");
const std = @import("std");

test "import works" {
    const board = b.Board{ .position = b.Position.init() };
    try std.testing.expectEqual(board.move_count, 0);
    try std.testing.expectEqual(board.position.whitepieces.King.position, 0b1000);
}

const pawnShifts = [4]u6{ 8, 16, 7, 9 };

// takes in a board and iterates through all pieces and returns a 64 bit representation of the board
pub fn piecebitmap(board: b.Board) u64 {
    var bitmap: u64 = 0;
    const cpiece = b.Piece{ .color = 0, .value = 1, .representation = 'P', .stdval = 1, .position = 0 };
    _ = cpiece;
    inline for (std.meta.fields(@TypeOf(board.position.whitepieces))) |piece| {
        if (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == (b.Piece)) {
            bitmap |= (@as(piece.type, @field(board.position.whitepieces, piece.name))).position;
        } else if (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == ([2]b.Piece)) {
            for (@as(piece.type, @field(board.position.whitepieces, piece.name))) |item| {
                bitmap |= item.position;
            }
        } else if (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == ([8]b.Piece)) {
            for (@as(piece.type, @field(board.position.whitepieces, piece.name))) |item| {
                bitmap |= item.position;
            }
        }
    }
    inline for (std.meta.fields(@TypeOf(board.position.blackpieces))) |piece| {
        if (@TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == (b.Piece)) {
            bitmap |= (@as(piece.type, @field(board.position.blackpieces, piece.name))).position;
        } else if (@TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == ([2]b.Piece)) {
            for (@as(piece.type, @field(board.position.blackpieces, piece.name))) |item| {
                bitmap |= item.position;
            }
        } else if (@TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == ([8]b.Piece)) {
            for (@as(piece.type, @field(board.position.blackpieces, piece.name))) |item| {
                bitmap |= item.position;
            }
        }
    }

    return bitmap;
}

test "bitmap of initial board" {
    const board = b.Board{ .position = b.Position.init() };
    const bitmap = piecebitmap(board);
    try std.testing.expectEqual(bitmap, 0xFFFF00000000FFFF);
}

// valid pawn moves. only moves for white
// return board array with all possible moves
pub fn ValidPawnMoves(piece: b.Piece, board: b.Board) []b.Board {
    var bitmap: u64 = piecebitmap(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    var pawn: b.Piece = undefined;
    var index: u64 = 0;
    //@memset(&moves, 0);
    // determine which piece is being moved
    for (board.position.whitepieces.Pawn, 0..) |item, loopidx| {
        if (item.position == piece.position) {
            pawn = item;
            index = loopidx;
        }
    }
    // iterate through all possible moves
    // single move forward only if no piece is in front
    for (pawnShifts) |shift| switch (shift) {
        8 => {
            if (bitmap & (piece.position << 8) == 0) {
                pawn.position = piece.position << 8;
                // update board
                moves[possiblemoves] = b.Board{ .position = board.position };
                moves[possiblemoves].position.whitepieces.Pawn[index].position = pawn.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
            }
        },
        16 => {
            // only allowed on second row
            // not allowed if there is a piece in front
            if (bitmap & (piece.position << 16) == 0 and (piece.position & 0xFF00) != 0 and (bitmap & piece.position << 8) == 0) {
                pawn.position = piece.position << 16;
                // update board
                moves[possiblemoves] = b.Board{ .position = board.position };
                moves[possiblemoves].position.whitepieces.Pawn[index].position = pawn.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
            }
        },
        7 => {
            // remove captured piece from board
            if (bitmap & (piece.position << 7) != 0) {
                pawn.position = piece.position << 7;
                // update board
                moves[possiblemoves] = b.Board{ .position = board.position };
                moves[possiblemoves].position.whitepieces.Pawn[index].position = pawn.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
            }
        },
        9 => {
            if (bitmap & (piece.position << 9) != 0) {
                pawn.position = piece.position << 9;
                // update board
                moves[possiblemoves] = b.Board{ .position = board.position };
                moves[possiblemoves].position.whitepieces.Pawn[index].position = pawn.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
            }
        },
        else => {},
    };
    return moves[0..possiblemoves];
}

test "ValidPawnMoves from e2 in start position" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2);
}

test "ValidPawnMoves from e7 in empty board" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[3].position = 0x8000000000000;
    std.debug.print("before\n", .{});
    _ = board.print();
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 1);
}

test "pawn capture e3 f4 or go to e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[3].position = 0x80000;
    board.position.blackpieces.Pawn[2].position = 0x4000000;
    std.debug.print("before\n", .{});
    _ = board.print();
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 2);
}
