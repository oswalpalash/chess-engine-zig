const b = @import("board.zig");
const std = @import("std");

test "import works" {
    var board = b.Board{ .position = b.Position.init() };
    try std.testing.expectEqual(board.move_count, 0);
    try std.testing.expectEqual(board.position.WhiteKing, 0b1000);
}

pub fn AllPawnMoves(pos: u64) []u64 {
    // generate all possible pawn moves while ensuring popcount remains the same
    // forward one square, forward two squares, capture left, capture right
    var shifts = [4]u6{ 8, 16, 7, 9 };
    var moves: [256]u64 = undefined;
    @memset(&moves, 0);
    var index: usize = 0;
    for (shifts) |shift| {
        _ = switch (shift) {
            8 => {
                // forward one square, only disallowed on the last rank
                if ((pos & 0xFF << 56) == 0) {
                    moves[index] = pos << 8;
                    if (pos << 8 != 0) {
                        index += 1;
                    }
                }
            },
            16 => {
                // forward two squares, only allowed on second rank
                if ((pos & 0xFF00) != 0) {
                    moves[index] = pos << 16;
                    if (pos << 16 != 0) {
                        index += 1;
                    }
                }
            },
            7 => {
                // capture left, disallowed on the a file
                if ((pos & 0x8080808080808080) == 0) {
                    moves[index] = pos << 7;
                    if (pos << 7 != 0) {
                        index += 1;
                    }
                }
            },
            9 => {
                // capture right, disallowed on the h file
                if ((pos & 0x0101010101010101) == 0) {
                    moves[index] = pos << 9;
                    if (pos << 9 != 0) {
                        index += 1;
                    }
                }
            },
            else => {},
        };
    }
    return moves[0..index];
}

test "all pawn moves" {
    var initPos: b.Position = b.Position.emptyboard();
    initPos.WhitePawn = 0x8 << 8;
    var moves: []u64 = AllPawnMoves(initPos.WhitePawn);
    // expect e3, e4, d3 and f3
    try std.testing.expectEqual(moves.len, 4);
}

test "pawn moves out of board" {
    var initPos: b.Position = b.Position.emptyboard();
    initPos.WhitePawn = 0x0800000000000000;
    var moves: []u64 = AllPawnMoves(initPos.WhitePawn);
    _ = moves;
    try std.testing.expectEqual(AllPawnMoves(initPos.WhitePawn).len, 0);
}

test "some pawn moves go out of board" {
    var initPos: b.Position = b.Position.emptyboard();
    // white pawn at a2
    initPos.WhitePawn = 0x8000;
    try std.testing.expectEqual(AllPawnMoves(initPos.WhitePawn).len, 3);
}
