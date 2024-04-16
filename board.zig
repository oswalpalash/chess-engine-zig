const std = @import("std");
// Board Representation

// Board is a 64, bit integer. Each bit represents a square on the board.
// The least significant bit represents a1, the most significant bit represents h8.

const Piece = struct {
    color: u8,
    value: u8,
    representation: u8,
    current: u64 = 0,
};

const WhiteKing: Piece = Piece{
    .color = 0,
    .value = 255,
    .representation = 'K',
};
const WhiteQueen: Piece = Piece{ .color = 0, .value = 9, .representation = 'Q' };
const WhiteRook: Piece = Piece{ .color = 0, .value = 5, .representation = 'R' };
const WhiteBishop: Piece = Piece{ .color = 0, .value = 3, .representation = 'B' };
const WhiteKnight: Piece = Piece{ .color = 0, .value = 3, .representation = 'N' };
const WhitePawn: Piece = Piece{ .color = 0, .value = 1, .representation = 'P' };
const BlackKing: Piece = Piece{ .color = 1, .value = 255, .representation = 'k' };
const BlackQueen: Piece = Piece{ .color = 1, .value = 9, .representation = 'q' };
const BlackRook: Piece = Piece{ .color = 1, .value = 5, .representation = 'r' };
const BlackBishop: Piece = Piece{ .color = 1, .value = 3, .representation = 'b' };
const BlackKnight: Piece = Piece{ .color = 1, .value = 3, .representation = 'n' };
const BlackPawn: Piece = Piece{ .color = 1, .value = 1, .representation = 'p' };
const Empty: Piece = Piece{ .color = 2, .value = 0, .representation = '.' };

const Position = struct {
    WhiteKing: u64,
    WhiteQueen: u64,
    WhiteRook: u64,
    WhiteBishop: u64,
    WhiteKnight: u64,
    WhitePawn: u64,
    BlackKing: u64,
    BlackQueen: u64,
    BlackRook: u64,
    BlackBishop: u64,
    BlackKnight: u64,
    BlackPawn: u64,

    pub fn init() Position {
        return Position{
            // use actual bitboards with all pieces in starting position
            .WhiteKing = 0x8,
            .WhiteQueen = 0x10,
            .WhiteRook = 0x81,
            .WhiteBishop = 0x24,
            .WhiteKnight = 0x42,
            .WhitePawn = 0xFF00,
            .BlackKing = 0x0800000000000000,
            .BlackQueen = 0x1000000000000000,
            .BlackRook = 0x8100000000000000,
            .BlackBishop = 0x2400000000000000,
            .BlackKnight = 0x4200000000000000,
            .BlackPawn = 0xFF000000000000,
        };
    }

    pub fn print(position: Position) [64]u8 {
        var printBuffer: [64]u8 = undefined;
        var i: u7 = 0;
        while (i < 64) : (i += 1) {
            if ((position.WhiteKing >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = WhiteKing.representation;
            } else if ((position.WhiteQueen >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = WhiteQueen.representation;
            } else if ((position.WhiteRook >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = WhiteRook.representation;
            } else if ((position.WhiteBishop >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = WhiteBishop.representation;
            } else if ((position.WhiteKnight >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = WhiteKnight.representation;
            } else if ((position.WhitePawn >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = WhitePawn.representation;
            } else if ((position.BlackKing >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = BlackKing.representation;
            } else if ((position.BlackQueen >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = BlackQueen.representation;
            } else if ((position.BlackRook >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = BlackRook.representation;
            } else if ((position.BlackBishop >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = BlackBishop.representation;
            } else if ((position.BlackKnight >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = BlackKnight.representation;
            } else if ((position.BlackPawn >> @as(u6, @truncate(i))) & 1 == 1) {
                printBuffer[i] = BlackPawn.representation;
            } else {
                printBuffer[i] = Empty.representation;
            }
        }
        // print the buffer in reverse order
        for (0..printBuffer.len) |index| {
            if (index % 8 == 0 and index != 0) {
                std.debug.print("\n", .{});
            }
            std.debug.print("{c}", .{printBuffer[printBuffer.len - 1 - index]});
        }
        return printBuffer;
    }
};

// board is a structure of Position
const Board = struct {
    position: Position,

    pub fn print(self: Board) [64]u8 {
        return self.position.print();
    }
};

test "print board" {
    var board: Board = Board{ .position = Position.init() };
    try std.testing.expectEqualStrings(&board.print(), "RNBKQBNRPPPPPPPP................................pppppppprnbkqbnr"[0..64]);
}
