const std = @import("std");
const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("board_helpers.zig");

fn bitboardFromRowCol(row: u6, col: u6) u64 {
    const col_shift: u6 = @intCast(8 - col);
    const row_shift: u6 = @intCast((row - 1) * 8);
    return (@as(u64, 1) << col_shift) << row_shift;
}

fn pieceAt(board: *const b.Board, location: u64) b.Piece {
    const empty_piece = b.Piece{
        .color = 2,
        .value = 0,
        .representation = '.',
        .current = 0,
        .stdval = 0,
        .position = 0,
        .index = 0,
    };

    const white = &board.*.position.whitepieces;
    inline for (std.meta.fields(@TypeOf(white.*))) |field| {
        const field_ptr = &@field(white.*, field.name);
        const FieldType = @TypeOf(field_ptr.*);
        if (FieldType == b.Piece) {
            if (field_ptr.*.position == location) {
                return field_ptr.*;
            }
        } else switch (@typeInfo(FieldType)) {
            .array => |array_info| {
                if (array_info.child == b.Piece) {
                    inline for (0..array_info.len) |i| {
                        if (field_ptr.*[i].position == location) {
                            return field_ptr.*[i];
                        }
                    }
                }
            },
            else => {},
        }
    }

    const black = &board.*.position.blackpieces;
    inline for (std.meta.fields(@TypeOf(black.*))) |field| {
        const field_ptr = &@field(black.*, field.name);
        const FieldType = @TypeOf(field_ptr.*);
        if (FieldType == b.Piece) {
            if (field_ptr.*.position == location) {
                return field_ptr.*;
            }
        } else switch (@typeInfo(FieldType)) {
            .array => |array_info| {
                if (array_info.child == b.Piece) {
                    inline for (0..array_info.len) |i| {
                        if (field_ptr.*[i].position == location) {
                            return field_ptr.*[i];
                        }
                    }
                }
            },
            else => {},
        }
    }

    return empty_piece;
}

inline fn inBounds(row: i8, col: i8) bool {
    return row >= 1 and row <= 8 and col >= 1 and col <= 8;
}

pub fn isSquareAttacked(board: *const b.Board, square: u64, byWhite: bool) bool {
    if (square == 0) {
        return false;
    }

    const row_val = board_helpers.rowfrombitmap(square);
    const col_val = board_helpers.colfrombitmap(square);
    if (row_val == 0 or col_val == 0) {
        return false;
    }

    const row = @as(i8, @intCast(row_val));
    const col = @as(i8, @intCast(col_val));
    const attacker_color: u8 = if (byWhite) 0 else 1;

    // Pawn attacks
    if (byWhite) {
        if (row > 1) {
            const pawn_row = row - 1;
            if (col > 1) {
                const target = bitboardFromRowCol(@intCast(pawn_row), @intCast(col - 1));
                const piece = pieceAt(board, target);
                if (piece.representation == 'P') {
                    return true;
                }
            }
            if (col < 8) {
                const target = bitboardFromRowCol(@intCast(pawn_row), @intCast(col + 1));
                const piece = pieceAt(board, target);
                if (piece.representation == 'P') {
                    return true;
                }
            }
        }
    } else {
        if (row < 8) {
            const pawn_row = row + 1;
            if (col > 1) {
                const target = bitboardFromRowCol(@intCast(pawn_row), @intCast(col - 1));
                const piece = pieceAt(board, target);
                if (piece.representation == 'p') {
                    return true;
                }
            }
            if (col < 8) {
                const target = bitboardFromRowCol(@intCast(pawn_row), @intCast(col + 1));
                const piece = pieceAt(board, target);
                if (piece.representation == 'p') {
                    return true;
                }
            }
        }
    }

    // Knight attacks
    const knight_offsets = [_]struct { dr: i8, dc: i8 }{
        .{ .dr = 2, .dc = 1 },
        .{ .dr = 1, .dc = 2 },
        .{ .dr = -1, .dc = 2 },
        .{ .dr = -2, .dc = 1 },
        .{ .dr = -2, .dc = -1 },
        .{ .dr = -1, .dc = -2 },
        .{ .dr = 1, .dc = -2 },
        .{ .dr = 2, .dc = -1 },
    };

    for (knight_offsets) |offset| {
        const target_row = row + offset.dr;
        const target_col = col + offset.dc;
        if (!inBounds(target_row, target_col)) continue;
        const target = bitboardFromRowCol(@intCast(target_row), @intCast(target_col));
        const piece = pieceAt(board, target);
        if (piece.color == attacker_color and std.ascii.toLower(piece.representation) == 'n') {
            return true;
        }
    }

    // Rook and queen attacks (orthogonal)
    const rook_dirs = [_]struct { dr: i8, dc: i8 }{
        .{ .dr = 0, .dc = 1 },
        .{ .dr = 0, .dc = -1 },
        .{ .dr = 1, .dc = 0 },
        .{ .dr = -1, .dc = 0 },
    };

    for (rook_dirs) |dir| {
        var r = row + dir.dr;
        var file = col + dir.dc;
        while (inBounds(r, file)) {
            const target = bitboardFromRowCol(@intCast(r), @intCast(file));
            const piece = pieceAt(board, target);
            if (piece.representation == '.') {
                r += dir.dr;
                file += dir.dc;
                continue;
            }
            if (piece.color == attacker_color) {
                const lower = std.ascii.toLower(piece.representation);
                if (lower == 'r' or lower == 'q') {
                    return true;
                }
            }
            break;
        }
    }

    // Bishop and queen attacks (diagonal)
    const bishop_dirs = [_]struct { dr: i8, dc: i8 }{
        .{ .dr = 1, .dc = 1 },
        .{ .dr = 1, .dc = -1 },
        .{ .dr = -1, .dc = 1 },
        .{ .dr = -1, .dc = -1 },
    };

    for (bishop_dirs) |dir| {
        var r = row + dir.dr;
        var file = col + dir.dc;
        while (inBounds(r, file)) {
            const target = bitboardFromRowCol(@intCast(r), @intCast(file));
            const piece = pieceAt(board, target);
            if (piece.representation == '.') {
                r += dir.dr;
                file += dir.dc;
                continue;
            }
            if (piece.color == attacker_color) {
                const lower = std.ascii.toLower(piece.representation);
                if (lower == 'b' or lower == 'q') {
                    return true;
                }
            }
            break;
        }
    }

    // King attacks
    const king_offsets = [_]struct { dr: i8, dc: i8 }{
        .{ .dr = 1, .dc = 0 },
        .{ .dr = 1, .dc = 1 },
        .{ .dr = 0, .dc = 1 },
        .{ .dr = -1, .dc = 1 },
        .{ .dr = -1, .dc = 0 },
        .{ .dr = -1, .dc = -1 },
        .{ .dr = 0, .dc = -1 },
        .{ .dr = 1, .dc = -1 },
    };

    for (king_offsets) |offset| {
        const target_row = row + offset.dr;
        const target_col = col + offset.dc;
        if (!inBounds(target_row, target_col)) continue;
        const target = bitboardFromRowCol(@intCast(target_row), @intCast(target_col));
        const piece = pieceAt(board, target);
        if (piece.color == attacker_color and std.ascii.toLower(piece.representation) == 'k') {
            return true;
        }
    }

    return false;
}

test "fool's mate queen attacks e1" {
    var board = b.Board{ .position = b.Position.init() };
    board.position.whitepieces.Pawn[5].position = c.F3;
    board.position.whitepieces.Pawn[6].position = c.G4;
    board.position.blackpieces.Pawn[4].position = c.E5;
    board.position.blackpieces.Queen.position = c.H4;

    try std.testing.expect(isSquareAttacked(&board, c.E1, false));
}
