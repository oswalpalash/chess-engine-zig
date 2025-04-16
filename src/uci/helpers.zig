const std = @import("std");
const b = @import("../board.zig");
const c = @import("../consts.zig");

/// Convert a bitboard position to algebraic notation square (e.g., "e4")
pub fn bitboardToSquare(position: u64) [2]u8 {
    var result: [2]u8 = undefined;
    var temp = position;
    var square: u6 = 0;
    while (temp > 1) : (temp >>= 1) {
        square += 1;
    }
    const file = @as(u8, 'a') + (7 - @as(u8, @intCast(square % 8)));
    const rank = @as(u8, '1') + @as(u8, @intCast(square / 8));
    result[0] = file;
    result[1] = rank;
    return result;
}

/// Convert a board move to UCI format (e.g., "e2e4" or "e7e8q" for promotion)
pub fn moveToUci(old_board: b.Board, new_board: b.Board) [5]u8 {
    var result: [5]u8 = undefined;
    var from_pos: u64 = 0;
    var to_pos: u64 = 0;
    var is_promotion = false;
    inline for (std.meta.fields(@TypeOf(old_board.position.whitepieces))) |field| {
        const old_piece = @field(old_board.position.whitepieces, field.name);
        const new_piece = @field(new_board.position.whitepieces, field.name);
        if (@TypeOf(old_piece) == b.Piece) {
            if (old_piece.position != new_piece.position) {
                if (old_piece.position != 0) from_pos = old_piece.position;
                if (new_piece.position != 0) {
                    to_pos = new_piece.position;
                    if (field.name[0] == 'P' and new_piece.representation == 'Q') {
                        is_promotion = true;
                    }
                }
            }
        } else if (@TypeOf(old_piece) == [2]b.Piece or @TypeOf(old_piece) == [8]b.Piece) {
            for (old_piece, 0..) |piece, i| {
                if (piece.position != new_piece[i].position) {
                    if (piece.position != 0) from_pos = piece.position;
                    if (new_piece[i].position != 0) {
                        to_pos = new_piece[i].position;
                        if (field.name[0] == 'P' and new_piece[i].representation == 'Q') {
                            is_promotion = true;
                        }
                    }
                }
            }
        }
    }
    if (from_pos == 0) {
        inline for (std.meta.fields(@TypeOf(old_board.position.blackpieces))) |field| {
            const old_piece = @field(old_board.position.blackpieces, field.name);
            const new_piece = @field(new_board.position.blackpieces, field.name);
            if (@TypeOf(old_piece) == b.Piece) {
                if (old_piece.position != new_piece.position) {
                    if (old_piece.position != 0) from_pos = old_piece.position;
                    if (new_piece.position != 0) {
                        to_pos = new_piece.position;
                        if (field.name[0] == 'P' and new_piece.representation == 'q') {
                            is_promotion = true;
                        }
                    }
                }
            } else if (@TypeOf(old_piece) == [2]b.Piece or @TypeOf(old_piece) == [8]b.Piece) {
                for (old_piece, 0..) |piece, i| {
                    if (piece.position != new_piece[i].position) {
                        if (piece.position != 0) from_pos = piece.position;
                        if (new_piece[i].position != 0) {
                            to_pos = new_piece[i].position;
                            if (field.name[0] == 'P' and new_piece[i].representation == 'q') {
                                is_promotion = true;
                            }
                        }
                    }
                }
            }
        }
    }
    const from_square = bitboardToSquare(from_pos);
    const to_square = bitboardToSquare(to_pos);
    result[0] = from_square[0];
    result[1] = from_square[1];
    result[2] = to_square[0];
    result[3] = to_square[1];
    if (is_promotion) {
        result[4] = 'q';
    } else {
        result[4] = 0;
    }
    return result;
}
