const std = @import("std");
// Board Representation

// Board is a 64, bit integer. Each bit represents a square on the board.
// The least significant bit represents a1, the most significant bit represents h8.

const BoardSize: u8 = 64;

const Piece = struct {
    color: u8,
    value: u8,
    representation: u8,
    current: u64 = 0,
    stdval: u8 = 0,
};

const WhiteKing: Piece = Piece{ .color = 0, .value = 255, .representation = 'K', .stdval = 255 };
const WhiteQueen: Piece = Piece{ .color = 0, .value = 9, .representation = 'Q', .stdval = 9 };
const WhiteRook: Piece = Piece{ .color = 0, .value = 5, .representation = 'R', .stdval = 5 };
const WhiteBishop: Piece = Piece{ .color = 0, .value = 3, .representation = 'B', .stdval = 3 };
const WhiteKnight: Piece = Piece{ .color = 0, .value = 3, .representation = 'N', .stdval = 3 };
const WhitePawn: Piece = Piece{ .color = 0, .value = 1, .representation = 'P', .stdval = 1 };
const BlackKing: Piece = Piece{ .color = 1, .value = 255, .representation = 'k', .stdval = 255 };
const BlackQueen: Piece = Piece{ .color = 1, .value = 9, .representation = 'q', .stdval = 9 };
const BlackRook: Piece = Piece{ .color = 1, .value = 5, .representation = 'r', .stdval = 5 };
const BlackBishop: Piece = Piece{ .color = 1, .value = 3, .representation = 'b', .stdval = 3 };
const BlackKnight: Piece = Piece{ .color = 1, .value = 3, .representation = 'n', .stdval = 3 };
const BlackPawn: Piece = Piece{ .color = 1, .value = 1, .representation = 'p', .stdval = 1 };
const Empty: Piece = Piece{ .color = 2, .value = 0, .representation = '.', .stdval = 0 };

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

    pub fn emptyboard() Position {
        return Position{
            .WhiteKing = 0,
            .WhiteQueen = 0,
            .WhiteRook = 0,
            .WhiteBishop = 0,
            .WhiteKnight = 0,
            .WhitePawn = 0,
            .BlackKing = 0,
            .BlackQueen = 0,
            .BlackRook = 0,
            .BlackBishop = 0,
            .BlackKnight = 0,
            .BlackPawn = 0,
        };
    }

    pub fn flip(self: Position) Position {
        return Position{
            .WhiteKing = self.BlackKing,
            .WhiteQueen = self.BlackQueen,
            .WhiteRook = self.BlackRook,
            .WhiteBishop = self.BlackBishop,
            .WhiteKnight = self.BlackKnight,
            .WhitePawn = self.BlackPawn,
            .BlackKing = self.WhiteKing,
            .BlackQueen = self.WhiteQueen,
            .BlackRook = self.WhiteRook,
            .BlackBishop = self.WhiteBishop,
            .BlackKnight = self.WhiteKnight,
            .BlackPawn = self.WhitePawn,
        };
    }

    // inverts board from middle
    pub fn invert(self: Position) Position {
        return Position{
            .WhiteKing = reverse(self.WhiteKing),
            .WhiteQueen = reverse(self.WhiteQueen),
            .WhiteRook = reverse(self.WhiteRook),
            .WhiteBishop = reverse(self.WhiteBishop),
            .WhiteKnight = reverse(self.WhiteKnight),
            .WhitePawn = reverse(self.WhitePawn),
            .BlackKing = reverse(self.BlackKing),
            .BlackQueen = reverse(self.BlackQueen),
            .BlackRook = reverse(self.BlackRook),
            .BlackBishop = reverse(self.BlackBishop),
            .BlackKnight = reverse(self.BlackKnight),
            .BlackPawn = reverse(self.BlackPawn),
        };
    }

    pub fn print(position: Position) [64]u8 {
        var printBuffer: [64]u8 = undefined;
        var i: u6 = 0;
        while (i < printBuffer.len) : (i += 1) {
            if (position.WhiteKing >> i & 1 == 1) {
                printBuffer[i] = WhiteKing.representation;
            } else if (position.WhiteQueen >> i & 1 == 1) {
                printBuffer[i] = WhiteQueen.representation;
            } else if (position.WhiteRook >> i & 1 == 1) {
                printBuffer[i] = WhiteRook.representation;
            } else if (position.WhiteBishop >> i & 1 == 1) {
                printBuffer[i] = WhiteBishop.representation;
            } else if (position.WhiteKnight >> i & 1 == 1) {
                printBuffer[i] = WhiteKnight.representation;
            } else if (position.WhitePawn >> i & 1 == 1) {
                printBuffer[i] = WhitePawn.representation;
            } else if (position.BlackKing >> i & 1 == 1) {
                printBuffer[i] = BlackKing.representation;
            } else if (position.BlackQueen >> i & 1 == 1) {
                printBuffer[i] = BlackQueen.representation;
            } else if (position.BlackRook >> i & 1 == 1) {
                printBuffer[i] = BlackRook.representation;
            } else if (position.BlackBishop >> i & 1 == 1) {
                printBuffer[i] = BlackBishop.representation;
            } else if (position.BlackKnight >> i & 1 == 1) {
                printBuffer[i] = BlackKnight.representation;
            } else if (position.BlackPawn >> i & 1 == 1) {
                printBuffer[i] = BlackPawn.representation;
            } else {
                printBuffer[i] = Empty.representation;
            }
            if (i == BoardSize - 1) {
                break;
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
    move_count: u32 = 0,
    whitepieces: WhitePieces = WhitePieces{ .King = WhiteKing, .Queen = WhiteQueen, .Rook = WhiteRook, .Bishop = WhiteBishop, .Knight = WhiteKnight, .Pawn = WhitePawn },
    blackpieces: BlackPieces = BlackPieces{ .King = BlackKing, .Queen = BlackQueen, .Rook = BlackRook, .Bishop = BlackBishop, .Knight = BlackKnight, .Pawn = BlackPawn },

    pub fn print(self: Board) [BoardSize]u8 {
        return self.position.print();
    }
};

const WhitePieces = struct {
    King: Piece = WhiteKing,
    Queen: Piece = WhiteQueen,
    Rook: Piece = WhiteRook,
    Bishop: Piece = WhiteBishop,
    Knight: Piece = WhiteKnight,
    Pawn: Piece = WhitePawn,

    pub fn boardvalue(self: WhitePieces) u32 {
        var value: u32 = 0;
        value += self.King.stdval;
        value += self.Queen.stdval;
        value += self.Rook.stdval;
        value += self.Bishop.stdval;
        value += self.Knight.stdval;
        value += self.Pawn.stdval;
        return value;
    }

    pub fn currentValues(self: WhitePieces, position: Position) u32 {
        var value: u32 = 0;
        value = @popCount(position.WhiteKing) * self.King.value;
        value += @popCount(position.WhiteQueen) * self.Queen.value;
        value += @popCount(position.WhiteRook) * self.Rook.value;
        value += @popCount(position.WhiteBishop) * self.Bishop.value;
        value += @popCount(position.WhiteKnight) * self.Knight.value;
        value += @popCount(position.WhitePawn) * self.Pawn.value;
        return value;
    }
};

const BlackPieces = struct {
    King: Piece = BlackKing,
    Queen: Piece = BlackQueen,
    Rook: Piece = BlackRook,
    Bishop: Piece = BlackBishop,
    Knight: Piece = BlackKnight,
    Pawn: Piece = BlackPawn,

    pub fn boardvalue(self: BlackPieces) u32 {
        var value: u32 = 0;
        value += self.King.stdval;
        value += self.Queen.stdval;
        value += self.Rook.stdval;
        value += self.Bishop.stdval;
        value += self.Knight.stdval;
        value += self.Pawn.stdval;
        return value;
    }

    pub fn currentValues(self: BlackPieces, position: Position) u32 {
        var value: u32 = 0;
        // determine number of pieces on the board
        value = @popCount(position.BlackKing) * self.King.value;
        value += @popCount(position.BlackQueen) * self.Queen.value;
        value += @popCount(position.BlackRook) * self.Rook.value;
        value += @popCount(position.BlackBishop) * self.Bishop.value;
        value += @popCount(position.BlackKnight) * self.Knight.value;
        value += @popCount(position.BlackPawn) * self.Pawn.value;
        return value;
    }
};

pub fn basicEval(board: Board) i64 {
    var whiteValue: u32 = board.whitepieces.boardvalue();
    var blackValue: u32 = board.blackpieces.boardvalue();
    var value: i64 = 0;
    value += @as(i64, whiteValue);
    value -= @as(i64, blackValue);
    return value;
}

pub fn CurrentEval(board: Board) i64 {
    var whiteValue: u32 = board.whitepieces.currentValues(board.position);
    var blackValue: u32 = board.blackpieces.currentValues(board.position);
    std.debug.print("White: {d}\n", .{whiteValue});
    std.debug.print("Black: {d}\n", .{blackValue});
    var value: i64 = 0;
    value += @as(i64, whiteValue);
    value -= @as(i64, blackValue);
    std.debug.print("Value: {d}\n", .{value});
    return value;
}

pub fn reverse(self: u64) u64 { // inverts from the center
    var result: u64 = 0;
    var i: u6 = 0;
    while (i < BoardSize) : (i += 1) {
        result |= ((self >> i) & 1) << (0x3f - i);
        if (i == BoardSize - 1) {
            break;
        }
    }
    return result;
}

// function to parse fen string
// example FEN : rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR
pub fn parseFen(fen: []const u8) Position {
    std.debug.assert(fen.len < BoardSize);
    var board: Board = Board{ .position = Position.emptyboard() }; // Assume emptyBoard initializes all bitboards to 0
    var index: u6 = 0; // Index on the bitboard, valid values are 0 to 63

    var i: usize = 0; // Index to iterate through FEN string characters
    while (i < fen.len) {
        switch (fen[i]) {
            // Major and minor pieces
            'K', 'Q', 'R', 'B', 'N', 'P', 'k', 'q', 'r', 'b', 'n', 'p' => {
                var bit: u64 = @as(u64, 1) << index;
                switch (fen[i]) {
                    'K' => board.position.WhiteKing |= bit,
                    'Q' => board.position.WhiteQueen |= bit,
                    'R' => board.position.WhiteRook |= bit,
                    'B' => board.position.WhiteBishop |= bit,
                    'N' => board.position.WhiteKnight |= bit,
                    'P' => board.position.WhitePawn |= bit,
                    'k' => board.position.BlackKing |= bit,
                    'q' => board.position.BlackQueen |= bit,
                    'r' => board.position.BlackRook |= bit,
                    'b' => board.position.BlackBishop |= bit,
                    'n' => board.position.BlackKnight |= bit,
                    'p' => board.position.BlackPawn |= bit,
                    else => {}, // Should never happen, all cases are covered
                }
                if (index == BoardSize - 1) {
                    break;
                }
                index += 1;
            },
            '1' => index += 1,
            '2' => index += 2,
            '3' => index += 3,
            '4' => index += 4,
            '5' => index += 5,
            '6' => index += 6,
            '7' => index += 7,
            '8' => index += 8,
            else => {},
        }
        i += 1;
    }
    return board.position.invert();
}

test "print board" {
    var board: Board = Board{ .position = Position.init() };
    try std.testing.expectEqualStrings(&board.print(), "RNBKQBNRPPPPPPPP................................pppppppprnbkqbnr"[0..BoardSize]);
}

test "fen" {
    var board: Board = Board{ .position = parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR") };
    try std.testing.expectEqualStrings(&board.print(), "RNBKQBNRPPPPPPPP................................pppppppprnbkqbnr"[0..BoardSize]);
}

test "eval of starting position" {
    var board: Board = Board{ .position = Position.init() };
    try std.testing.expectEqual(basicEval(board), 0);
}

test "current eval of starting position" {
    var board: Board = Board{ .position = Position.init() };
    try std.testing.expectEqual(CurrentEval(board), 0);
}

test "current eval of only white pieces" {
    var board: Board = Board{ .position = Position.init() };
    board.position.BlackKing = 0;
    board.position.BlackQueen = 0;
    board.position.BlackRook = 0;
    board.position.BlackBishop = 0;
    board.position.BlackKnight = 0;
    board.position.BlackPawn = 0;
    try std.testing.expectEqual(CurrentEval(board), 294);
}
