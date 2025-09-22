// board_helpers.zig
// Utility functions for board and piece manipulation

const b = @import("../board.zig");
const c = @import("../consts.zig");
const std = @import("std");

pub fn bitmapfromboard(board: b.Board) u64 {
    var bitmap: u64 = 0;
    inline for (std.meta.fields(@TypeOf(board.position.whitepieces))) |field| {
        const value = @field(board.position.whitepieces, field.name);
        const FieldType = @TypeOf(value);
        if (FieldType == b.Piece) {
            bitmap |= value.position;
        } else switch (@typeInfo(FieldType)) {
            .Array => |array_info| {
                if (array_info.child == b.Piece) {
                    for (value) |item| {
                        bitmap |= item.position;
                    }
                }
            },
            else => {},
        }
    }
    inline for (std.meta.fields(@TypeOf(board.position.blackpieces))) |field| {
        const value = @field(board.position.blackpieces, field.name);
        const FieldType = @TypeOf(value);
        if (FieldType == b.Piece) {
            bitmap |= value.position;
        } else switch (@typeInfo(FieldType)) {
            .Array => |array_info| {
                if (array_info.child == b.Piece) {
                    for (value) |item| {
                        bitmap |= item.position;
                    }
                }
            },
            else => {},
        }
    }
    return bitmap;
}

test "bitmap of initial board" {
    const board = b.Board{ .position = b.Position.init() };
    const bitmap = bitmapfromboard(board);
    try std.testing.expectEqual(bitmap, 0xFFFF00000000FFFF);
    try std.testing.expectEqual(bitmap, c.A1 | c.B1 | c.C1 | c.D1 | c.E1 | c.F1 | c.G1 | c.H1 | c.A2 | c.B2 | c.C2 | c.D2 | c.E2 | c.F2 | c.G2 | c.H2 | c.A7 | c.B7 | c.C7 | c.D7 | c.E7 | c.F7 | c.G7 | c.H7 | c.A8 | c.B8 | c.C8 | c.D8 | c.E8 | c.F8 | c.G8 | c.H8);
}

pub fn piecefromlocation(location: u64, board: b.Board) b.Piece {
    // iterate through all pieces of each colour to find which piece position matches the location
    inline for (std.meta.fields(@TypeOf(board.position.whitepieces))) |field| {
        const value = @field(board.position.whitepieces, field.name);
        const FieldType = @TypeOf(value);
        if (FieldType == b.Piece) {
            if (value.position == location) return value;
        } else switch (@typeInfo(FieldType)) {
            .Array => |array_info| {
                if (array_info.child == b.Piece) {
                    for (value) |item| {
                        if (item.position == location) return item;
                    }
                }
            },
            else => {},
        }
    }
    inline for (std.meta.fields(@TypeOf(board.position.blackpieces))) |field| {
        const value = @field(board.position.blackpieces, field.name);
        const FieldType = @TypeOf(value);
        if (FieldType == b.Piece) {
            if (value.position == location) return value;
        } else switch (@typeInfo(FieldType)) {
            .Array => |array_info| {
                if (array_info.child == b.Piece) {
                    for (value) |item| {
                        if (item.position == location) return item;
                    }
                }
            },
            else => {},
        }
    }
    return b.Piece{ .color = 0, .value = 0, .representation = '.', .stdval = 0, .position = 0 };
}

test "piece from location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H1,
        board,
    );
    try std.testing.expectEqual(piece.representation, 'R');
}

test "white pawn from location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H2,
        board,
    );
    try std.testing.expectEqual(piece.representation, 'P');
}

test "empty location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H3,
        board,
    );
    try std.testing.expectEqual(piece.representation, '.');
}

test "black pawn from location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H7,
        board,
    );
    try std.testing.expectEqual(piece.representation, 'p');
}

test "black piece from location" {
    const board = b.Board{ .position = b.Position.init() };
    const piece = piecefromlocation(
        c.H8,
        board,
    );
    try std.testing.expectEqual(piece.representation, 'r');
}

pub fn captureblackpiece(loc: u64, board: b.Board) b.Board {
    var piece: b.Piece = piecefromlocation(loc, board);
    var boardCopy: b.Board = board;
    // determine type of piece
    _ = switch (piece.representation) {
        'k' => {
            boardCopy.position.blackpieces.King.position = 0;
            piece.position = 0;
        },
        'q' => {
            if (boardCopy.position.blackpieces.Queen.position == loc) {
                boardCopy.position.blackpieces.Queen.position = 0;
                piece.position = 0;
            } else {
                for (&boardCopy.position.blackpieces.PromotedQueen) |*promoted| {
                    if (promoted.position == loc) {
                        promoted.position = 0;
                        piece.position = 0;
                        if (boardCopy.position.blackpieces.PromotedQueenCount > 0) {
                            boardCopy.position.blackpieces.PromotedQueenCount -= 1;
                        }
                        break;
                    }
                }
            }
        },
        'r' => {
            if (boardCopy.position.blackpieces.Rook[0].position == loc) {
                boardCopy.position.blackpieces.Rook[0].position = 0;
                piece.position = 0;
                if (loc == c.H8) {
                    boardCopy.position.canCastleBlackKingside = false;
                } else if (loc == c.A8) {
                    boardCopy.position.canCastleBlackQueenside = false;
                }
            } else if (boardCopy.position.blackpieces.Rook[1].position == loc) {
                boardCopy.position.blackpieces.Rook[1].position = 0;
                piece.position = 0;
                if (loc == c.H8) {
                    boardCopy.position.canCastleBlackKingside = false;
                } else if (loc == c.A8) {
                    boardCopy.position.canCastleBlackQueenside = false;
                }
            } else {
                for (&boardCopy.position.blackpieces.PromotedRook) |*promoted| {
                    if (promoted.position == loc) {
                        promoted.position = 0;
                        piece.position = 0;
                        if (boardCopy.position.blackpieces.PromotedRookCount > 0) {
                            boardCopy.position.blackpieces.PromotedRookCount -= 1;
                        }
                        break;
                    }
                }
            }
        },
        'b' => {
            if (boardCopy.position.blackpieces.Bishop[0].position == loc) {
                boardCopy.position.blackpieces.Bishop[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Bishop[1].position == loc) {
                boardCopy.position.blackpieces.Bishop[1].position = 0;
                piece.position = 0;
            } else {
                for (&boardCopy.position.blackpieces.PromotedBishop) |*promoted| {
                    if (promoted.position == loc) {
                        promoted.position = 0;
                        piece.position = 0;
                        if (boardCopy.position.blackpieces.PromotedBishopCount > 0) {
                            boardCopy.position.blackpieces.PromotedBishopCount -= 1;
                        }
                        break;
                    }
                }
            }
        },
        'n' => {
            if (boardCopy.position.blackpieces.Knight[0].position == loc) {
                boardCopy.position.blackpieces.Knight[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Knight[1].position == loc) {
                boardCopy.position.blackpieces.Knight[1].position = 0;
                piece.position = 0;
            } else {
                for (&boardCopy.position.blackpieces.PromotedKnight) |*promoted| {
                    if (promoted.position == loc) {
                        promoted.position = 0;
                        piece.position = 0;
                        if (boardCopy.position.blackpieces.PromotedKnightCount > 0) {
                            boardCopy.position.blackpieces.PromotedKnightCount -= 1;
                        }
                        break;
                    }
                }
            }
        },
        'p' => {
            if (boardCopy.position.blackpieces.Pawn[0].position == loc) {
                boardCopy.position.blackpieces.Pawn[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Pawn[1].position == loc) {
                boardCopy.position.blackpieces.Pawn[1].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Pawn[2].position == loc) {
                boardCopy.position.blackpieces.Pawn[2].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Pawn[3].position == loc) {
                boardCopy.position.blackpieces.Pawn[3].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Pawn[4].position == loc) {
                boardCopy.position.blackpieces.Pawn[4].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Pawn[5].position == loc) {
                boardCopy.position.blackpieces.Pawn[5].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Pawn[6].position == loc) {
                boardCopy.position.blackpieces.Pawn[6].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Pawn[7].position == loc) {
                boardCopy.position.blackpieces.Pawn[7].position = 0;
                piece.position = 0;
            }
        },
        else => {},
    };
    return boardCopy;
}

test "capture black pawn at e7 in initial board" {
    const newboard = captureblackpiece(c.E7, b.Board{ .position = b.Position.init() });
    try std.testing.expectEqual(newboard.position.blackpieces.Pawn[3].position, 0);
}

test "capture black rook at a8 in initial board" {
    const newboard = captureblackpiece(c.A8, b.Board{ .position = b.Position.init() });
    try std.testing.expectEqual(newboard.position.blackpieces.Rook[1].position, 0);
}

pub fn rowfrombitmap(bitmap: u64) u64 {
    const rows = [8]u6{ 0, 1, 2, 3, 4, 5, 6, 7 };
    for (rows) |i| {
        if (bitmap & (@as(u64, 0xFF) << (i * 8)) != 0) {
            return i + 1;
        }
    }
    return 0;
}

test "rowfrombitmap for black rook at a8" {
    const consts = @import("../consts.zig");
    try std.testing.expectEqual(rowfrombitmap(consts.A8), 8);
}

pub fn colfrombitmap(bitmap: u64) u64 {
    const cols = [8]u6{ 0, 1, 2, 3, 4, 5, 6, 7 };
    for (cols) |i| {
        if (bitmap & (@as(u64, 0x0101010101010101) << i) != 0) {
            return 8 - i;
        }
    }
    return 0;
}

test "colfrombitmap for black rook at a8" {
    const consts = @import("../consts.zig");
    try std.testing.expectEqual(colfrombitmap(consts.A8), 1);
}

pub fn capturewhitepiece(loc: u64, board: b.Board) b.Board {
    var piece: b.Piece = piecefromlocation(loc, board);
    var boardCopy: b.Board = board;
    // determine type of piece
    _ = switch (piece.representation) {
        'K' => {
            boardCopy.position.whitepieces.King.position = 0;
            piece.position = 0;
        },
        'Q' => {
            if (boardCopy.position.whitepieces.Queen.position == loc) {
                boardCopy.position.whitepieces.Queen.position = 0;
                piece.position = 0;
            } else {
                for (&boardCopy.position.whitepieces.PromotedQueen) |*promoted| {
                    if (promoted.position == loc) {
                        promoted.position = 0;
                        piece.position = 0;
                        if (boardCopy.position.whitepieces.PromotedQueenCount > 0) {
                            boardCopy.position.whitepieces.PromotedQueenCount -= 1;
                        }
                        break;
                    }
                }
            }
        },
        'R' => {
            if (boardCopy.position.whitepieces.Rook[0].position == loc) {
                boardCopy.position.whitepieces.Rook[0].position = 0;
                piece.position = 0;
                if (loc == c.A1) {
                    boardCopy.position.canCastleWhiteQueenside = false;
                } else if (loc == c.H1) {
                    boardCopy.position.canCastleWhiteKingside = false;
                }
            } else if (boardCopy.position.whitepieces.Rook[1].position == loc) {
                boardCopy.position.whitepieces.Rook[1].position = 0;
                piece.position = 0;
                if (loc == c.A1) {
                    boardCopy.position.canCastleWhiteQueenside = false;
                } else if (loc == c.H1) {
                    boardCopy.position.canCastleWhiteKingside = false;
                }
            } else {
                for (&boardCopy.position.whitepieces.PromotedRook) |*promoted| {
                    if (promoted.position == loc) {
                        promoted.position = 0;
                        piece.position = 0;
                        if (boardCopy.position.whitepieces.PromotedRookCount > 0) {
                            boardCopy.position.whitepieces.PromotedRookCount -= 1;
                        }
                        break;
                    }
                }
            }
        },
        'B' => {
            if (boardCopy.position.whitepieces.Bishop[0].position == loc) {
                boardCopy.position.whitepieces.Bishop[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Bishop[1].position == loc) {
                boardCopy.position.whitepieces.Bishop[1].position = 0;
                piece.position = 0;
            } else {
                for (&boardCopy.position.whitepieces.PromotedBishop) |*promoted| {
                    if (promoted.position == loc) {
                        promoted.position = 0;
                        piece.position = 0;
                        if (boardCopy.position.whitepieces.PromotedBishopCount > 0) {
                            boardCopy.position.whitepieces.PromotedBishopCount -= 1;
                        }
                        break;
                    }
                }
            }
        },
        'N' => {
            if (boardCopy.position.whitepieces.Knight[0].position == loc) {
                boardCopy.position.whitepieces.Knight[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Knight[1].position == loc) {
                boardCopy.position.whitepieces.Knight[1].position = 0;
                piece.position = 0;
            } else {
                for (&boardCopy.position.whitepieces.PromotedKnight) |*promoted| {
                    if (promoted.position == loc) {
                        promoted.position = 0;
                        piece.position = 0;
                        if (boardCopy.position.whitepieces.PromotedKnightCount > 0) {
                            boardCopy.position.whitepieces.PromotedKnightCount -= 1;
                        }
                        break;
                    }
                }
            }
        },
        'P' => {
            if (boardCopy.position.whitepieces.Pawn[0].position == loc) {
                boardCopy.position.whitepieces.Pawn[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[1].position == loc) {
                boardCopy.position.whitepieces.Pawn[1].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[2].position == loc) {
                boardCopy.position.whitepieces.Pawn[2].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[3].position == loc) {
                boardCopy.position.whitepieces.Pawn[3].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[4].position == loc) {
                boardCopy.position.whitepieces.Pawn[4].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[5].position == loc) {
                boardCopy.position.whitepieces.Pawn[5].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[6].position == loc) {
                boardCopy.position.whitepieces.Pawn[6].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Pawn[7].position == loc) {
                boardCopy.position.whitepieces.Pawn[7].position = 0;
                piece.position = 0;
            }
        },
        else => {},
    };
    return boardCopy;
}

test "capture white pawn at e2 in initial board" {
    const consts = @import("../consts.zig");
    const board_mod = @import("../board.zig");
    const newboard = capturewhitepiece(consts.E2, board_mod.Board{ .position = board_mod.Position.init() });
    try std.testing.expectEqual(newboard.position.whitepieces.Pawn[4].position, 0);
}

test "capture white rook disables kingside castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[1].position = c.H1;
    board.position.canCastleWhiteKingside = true;

    const post_capture = capturewhitepiece(c.H1, board);
    try std.testing.expectEqual(false, post_capture.position.canCastleWhiteKingside);
}

test "capture white rook disables queenside castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.A1;
    board.position.canCastleWhiteQueenside = true;

    const post_capture = capturewhitepiece(c.A1, board);
    try std.testing.expectEqual(false, post_capture.position.canCastleWhiteQueenside);
}

test "capture black rook disables kingside castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Rook[1].position = c.H8;
    board.position.canCastleBlackKingside = true;

    const post_capture = captureblackpiece(c.H8, board);
    try std.testing.expectEqual(false, post_capture.position.canCastleBlackKingside);
}

test "capture black rook disables queenside castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Rook[0].position = c.A8;
    board.position.canCastleBlackQueenside = true;

    const post_capture = captureblackpiece(c.A8, board);
    try std.testing.expectEqual(false, post_capture.position.canCastleBlackQueenside);
}

test "capture promoted white queen clears slot" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.promotePawn(0, 0, 'Q', c.E8) catch unreachable;
    try std.testing.expectEqual(@as(u4, 1), board.position.whitepieces.PromotedQueenCount);

    const post_capture = capturewhitepiece(c.E8, board);
    try std.testing.expectEqual(@as(u4, 0), post_capture.position.whitepieces.PromotedQueenCount);
    const piece = piecefromlocation(c.E8, post_capture);
    try std.testing.expectEqual(piece.position, 0);
}
