const std = @import("std");
const b = @import("../board.zig");
const board_helpers = @import("../utils/board_helpers.zig");

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

    inline for (std.meta.fields(@TypeOf(old_board.position.whitepieces))) |field| {
        const old_piece = @field(old_board.position.whitepieces, field.name);
        const new_piece = @field(new_board.position.whitepieces, field.name);
        const FieldType = @TypeOf(old_piece);
        if (FieldType == b.Piece) {
            if (old_piece.position != new_piece.position) {
                if (old_piece.position != 0) from_pos = old_piece.position;
                if (new_piece.position != 0) to_pos = new_piece.position;
            }
        } else switch (@typeInfo(FieldType)) {
            .array => |array_info| {
                if (array_info.child == b.Piece) {
                    for (old_piece, 0..) |piece, i| {
                        if (piece.position != new_piece[i].position) {
                            if (piece.position != 0) from_pos = piece.position;
                            if (new_piece[i].position != 0) to_pos = new_piece[i].position;
                        }
                    }
                }
            },
            else => {},
        }
    }

    if (from_pos == 0) {
        inline for (std.meta.fields(@TypeOf(old_board.position.blackpieces))) |field| {
            const old_piece = @field(old_board.position.blackpieces, field.name);
            const new_piece = @field(new_board.position.blackpieces, field.name);
            const FieldType = @TypeOf(old_piece);
            if (FieldType == b.Piece) {
                if (old_piece.position != new_piece.position) {
                    if (old_piece.position != 0) from_pos = old_piece.position;
                    if (new_piece.position != 0) to_pos = new_piece.position;
                }
            } else switch (@typeInfo(FieldType)) {
                .array => |array_info| {
                    if (array_info.child == b.Piece) {
                        for (old_piece, 0..) |piece, i| {
                            if (piece.position != new_piece[i].position) {
                                if (piece.position != 0) from_pos = piece.position;
                                if (new_piece[i].position != 0) to_pos = new_piece[i].position;
                            }
                        }
                    }
                },
                else => {},
            }
        }
    }

    const from_square = bitboardToSquare(from_pos);
    const to_square = bitboardToSquare(to_pos);
    result[0] = from_square[0];
    result[1] = from_square[1];
    result[2] = to_square[0];
    result[3] = to_square[1];

    var promotion_char: u8 = 0;
    if (from_pos != 0 and to_pos != 0) {
        const from_piece = board_helpers.piecefromlocation(from_pos, old_board);
        const to_piece = board_helpers.piecefromlocation(to_pos, new_board);
        if (from_piece.representation == 'P' or from_piece.representation == 'p') {
            const lower = std.ascii.toLower(to_piece.representation);
            switch (lower) {
                'q', 'r', 'b', 'n' => promotion_char = lower,
                else => {},
            }
        }
    }

    result[4] = promotion_char;
    return result;
}
