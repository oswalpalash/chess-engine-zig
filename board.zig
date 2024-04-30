const std = @import("std");
const c = @import("consts.zig");
// Board Representation

// Board is a 64, bit integer. Each bit represents a square on the board.
// The least significant bit represents a1, the most significant bit represents h8.

pub const BoardSize: u8 = 64;

pub const Piece = struct {
    color: u8,
    value: u8,
    representation: u8,
    current: u64 = 0,
    stdval: u8 = 0,
    position: u64 = 0,
};

pub const WhiteKing: Piece = Piece{ .color = 0, .value = 255, .representation = 'K', .stdval = 255, .position = 0x0 };
pub const WhiteQueen: Piece = Piece{ .color = 0, .value = 9, .representation = 'Q', .stdval = 9, .position = 0x0 };
pub const WhiteRook: Piece = Piece{ .color = 0, .value = 5, .representation = 'R', .stdval = 5, .position = 0x0 };
pub const WhiteBishop: Piece = Piece{ .color = 0, .value = 3, .representation = 'B', .stdval = 3, .position = 0x0 };
pub const WhiteKnight: Piece = Piece{ .color = 0, .value = 3, .representation = 'N', .stdval = 3, .position = 0x0 };
pub const WhitePawn: Piece = Piece{ .color = 0, .value = 1, .representation = 'P', .stdval = 1, .position = 0x0 };
pub const BlackKing: Piece = Piece{ .color = 1, .value = 255, .representation = 'k', .stdval = 255, .position = 0x0 };
pub const BlackQueen: Piece = Piece{ .color = 1, .value = 9, .representation = 'q', .stdval = 9, .position = 0x0 };
pub const BlackRook: Piece = Piece{ .color = 1, .value = 5, .representation = 'r', .stdval = 5, .position = 0x0 };
pub const BlackBishop: Piece = Piece{ .color = 1, .value = 3, .representation = 'b', .stdval = 3, .position = 0x0 };
pub const BlackKnight: Piece = Piece{ .color = 1, .value = 3, .representation = 'n', .stdval = 3, .position = 0x0 };
pub const BlackPawn: Piece = Piece{ .color = 1, .value = 1, .representation = 'p', .stdval = 1, .position = 0x0 };
const Empty: Piece = Piece{ .color = 2, .value = 0, .representation = '.', .stdval = 0, .position = 0x0 };

const WhitePieces = struct {
    King: Piece = WhiteKing,
    Queen: Piece = WhiteQueen,
    Rook: [2]Piece = [2]Piece{ WhiteRook, WhiteRook },
    Bishop: [2]Piece = [2]Piece{ WhiteBishop, WhiteBishop },
    Knight: [2]Piece = [2]Piece{ WhiteKnight, WhiteKnight },
    Pawn: [8]Piece = [8]Piece{ WhitePawn, WhitePawn, WhitePawn, WhitePawn, WhitePawn, WhitePawn, WhitePawn, WhitePawn },
};

const BlackPieces = struct {
    King: Piece = BlackKing,
    Queen: Piece = BlackQueen,
    Rook: [2]Piece = [2]Piece{ BlackRook, BlackRook },
    Bishop: [2]Piece = [2]Piece{ BlackBishop, BlackBishop },
    Knight: [2]Piece = [2]Piece{ BlackKnight, BlackKnight },
    Pawn: [8]Piece = [8]Piece{ BlackPawn, BlackPawn, BlackPawn, BlackPawn, BlackPawn, BlackPawn, BlackPawn, BlackPawn },
};

pub const Position = struct {
    whitepieces: WhitePieces = WhitePieces{},
    blackpieces: BlackPieces = BlackPieces{},

    pub fn init() Position {
        var whitepieces: WhitePieces = WhitePieces{};
        var blackpieces: BlackPieces = BlackPieces{};
        whitepieces.King.position = c.E1;
        whitepieces.Queen.position = c.D1;
        whitepieces.Rook[0].position = c.A1;
        whitepieces.Rook[1].position = c.H1;
        whitepieces.Bishop[0].position = c.C1;
        whitepieces.Bishop[1].position = c.F1;
        whitepieces.Knight[0].position = c.B1;
        whitepieces.Knight[1].position = c.G1;
        whitepieces.Pawn[0].position = c.A2;
        whitepieces.Pawn[1].position = c.B2;
        whitepieces.Pawn[2].position = c.C2;
        whitepieces.Pawn[3].position = c.D2;
        whitepieces.Pawn[4].position = c.E2;
        whitepieces.Pawn[5].position = c.F2;
        whitepieces.Pawn[6].position = c.G2;
        whitepieces.Pawn[7].position = c.H2;
        blackpieces.King.position = c.E8;
        blackpieces.Queen.position = c.D8;
        blackpieces.Rook[0].position = reverse(whitepieces.Rook[0].position);
        blackpieces.Rook[1].position = reverse(whitepieces.Rook[1].position);
        blackpieces.Bishop[0].position = reverse(whitepieces.Bishop[0].position);
        blackpieces.Bishop[1].position = reverse(whitepieces.Bishop[1].position);
        blackpieces.Knight[0].position = reverse(whitepieces.Knight[0].position);
        blackpieces.Knight[1].position = reverse(whitepieces.Knight[1].position);
        blackpieces.Pawn[0].position = reverse(whitepieces.Pawn[0].position);
        blackpieces.Pawn[1].position = reverse(whitepieces.Pawn[1].position);
        blackpieces.Pawn[2].position = reverse(whitepieces.Pawn[2].position);
        blackpieces.Pawn[3].position = reverse(whitepieces.Pawn[3].position);
        blackpieces.Pawn[4].position = reverse(whitepieces.Pawn[4].position);
        blackpieces.Pawn[5].position = reverse(whitepieces.Pawn[5].position);
        blackpieces.Pawn[6].position = reverse(whitepieces.Pawn[6].position);
        blackpieces.Pawn[7].position = reverse(whitepieces.Pawn[7].position);
        return Position{
            .whitepieces = whitepieces,
            .blackpieces = blackpieces,
        };
    }

    pub fn emptyboard() Position {
        return Position{
            .whitepieces = WhitePieces{},
            .blackpieces = BlackPieces{},
        };
    }

    pub fn flip(self: Position) Position {
        var whitepieces: WhitePieces = self.whitepieces;
        var blackpieces: BlackPieces = self.blackpieces;
        whitepieces.King.position = reverse(whitepieces.King.position);
        whitepieces.Queen.position = reverse(whitepieces.Queen.position);
        whitepieces.Rook[0].position = reverse(whitepieces.Rook[0].position);
        whitepieces.Rook[1].position = reverse(whitepieces.Rook[1].position);
        whitepieces.Bishop[0].position = reverse(whitepieces.Bishop[0].position);
        whitepieces.Bishop[1].position = reverse(whitepieces.Bishop[1].position);
        whitepieces.Knight[0].position = reverse(whitepieces.Knight[0].position);
        whitepieces.Knight[1].position = reverse(whitepieces.Knight[1].position);
        whitepieces.Pawn[0].position = reverse(whitepieces.Pawn[0].position);
        whitepieces.Pawn[1].position = reverse(whitepieces.Pawn[1].position);
        whitepieces.Pawn[2].position = reverse(whitepieces.Pawn[2].position);
        whitepieces.Pawn[3].position = reverse(whitepieces.Pawn[3].position);
        whitepieces.Pawn[4].position = reverse(whitepieces.Pawn[4].position);
        whitepieces.Pawn[5].position = reverse(whitepieces.Pawn[5].position);
        whitepieces.Pawn[6].position = reverse(whitepieces.Pawn[6].position);
        whitepieces.Pawn[7].position = reverse(whitepieces.Pawn[7].position);
        blackpieces.King.position = reverse(blackpieces.King.position);
        blackpieces.Queen.position = reverse(blackpieces.Queen.position);
        blackpieces.Rook[0].position = reverse(blackpieces.Rook[0].position);
        blackpieces.Rook[1].position = reverse(blackpieces.Rook[1].position);
        blackpieces.Bishop[0].position = reverse(blackpieces.Bishop[0].position);
        blackpieces.Bishop[1].position = reverse(blackpieces.Bishop[1].position);
        blackpieces.Knight[0].position = reverse(blackpieces.Knight[0].position);
        blackpieces.Knight[1].position = reverse(blackpieces.Knight[1].position);
        blackpieces.Pawn[0].position = reverse(blackpieces.Pawn[0].position);
        blackpieces.Pawn[1].position = reverse(blackpieces.Pawn[1].position);
        blackpieces.Pawn[2].position = reverse(blackpieces.Pawn[2].position);
        blackpieces.Pawn[3].position = reverse(blackpieces.Pawn[3].position);
        blackpieces.Pawn[4].position = reverse(blackpieces.Pawn[4].position);
        blackpieces.Pawn[5].position = reverse(blackpieces.Pawn[5].position);
        blackpieces.Pawn[6].position = reverse(blackpieces.Pawn[6].position);
        blackpieces.Pawn[7].position = reverse(blackpieces.Pawn[7].position);

        return Position{
            .whitepieces = whitepieces,
            .blackpieces = blackpieces,
        };
    }

    pub fn print(position: Position) [64]u8 {
        var printBuffer: [64]u8 = undefined;
        std.debug.print("\n", .{});
        var i: u6 = 0;
        while (i < printBuffer.len) : (i += 1) {
            if (position.whitepieces.King.position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.King.representation;
            } else if (position.whitepieces.Queen.position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Queen.representation;
            } else if (position.whitepieces.Rook[0].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Rook[0].representation;
            } else if (position.whitepieces.Rook[1].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Rook[1].representation;
            } else if (position.whitepieces.Bishop[0].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Bishop[0].representation;
            } else if (position.whitepieces.Bishop[1].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Bishop[1].representation;
            } else if (position.whitepieces.Knight[0].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Knight[0].representation;
            } else if (position.whitepieces.Knight[1].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Knight[1].representation;
            } else if (position.whitepieces.Pawn[0].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Pawn[0].representation;
            } else if (position.whitepieces.Pawn[1].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Pawn[1].representation;
            } else if (position.whitepieces.Pawn[2].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Pawn[2].representation;
            } else if (position.whitepieces.Pawn[3].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Pawn[3].representation;
            } else if (position.whitepieces.Pawn[4].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Pawn[4].representation;
            } else if (position.whitepieces.Pawn[5].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Pawn[5].representation;
            } else if (position.whitepieces.Pawn[6].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Pawn[6].representation;
            } else if (position.whitepieces.Pawn[7].position >> i & 1 == 1) {
                printBuffer[i] = position.whitepieces.Pawn[7].representation;
            } else if (position.blackpieces.King.position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.King.representation;
            } else if (position.blackpieces.Queen.position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Queen.representation;
            } else if (position.blackpieces.Rook[0].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Rook[0].representation;
            } else if (position.blackpieces.Rook[1].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Rook[1].representation;
            } else if (position.blackpieces.Bishop[0].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Bishop[0].representation;
            } else if (position.blackpieces.Bishop[1].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Bishop[1].representation;
            } else if (position.blackpieces.Knight[0].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Knight[0].representation;
            } else if (position.blackpieces.Knight[1].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Knight[1].representation;
            } else if (position.blackpieces.Pawn[0].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Pawn[0].representation;
            } else if (position.blackpieces.Pawn[1].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Pawn[1].representation;
            } else if (position.blackpieces.Pawn[2].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Pawn[2].representation;
            } else if (position.blackpieces.Pawn[3].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Pawn[3].representation;
            } else if (position.blackpieces.Pawn[4].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Pawn[4].representation;
            } else if (position.blackpieces.Pawn[5].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Pawn[5].representation;
            } else if (position.blackpieces.Pawn[6].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Pawn[6].representation;
            } else if (position.blackpieces.Pawn[7].position >> i & 1 == 1) {
                printBuffer[i] = position.blackpieces.Pawn[7].representation;
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
        std.debug.print("\n", .{});
        return printBuffer;
    }
};

// board is a structure of Position
pub const Board = struct {
    position: Position,
    move_count: u32 = 0,

    pub fn print(self: Board) [BoardSize]u8 {
        return self.position.print();
    }
};

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
    var blackrooks: u6 = 0;
    var blackknights: u6 = 0;
    var blackbishops: u6 = 0;
    var blackpawns: u6 = 0;
    var whiterooks: u6 = 0;
    var whiteknights: u6 = 0;
    var whitebishops: u6 = 0;
    var whitepawns: u6 = 0;

    var i: usize = 0; // Index to iterate through FEN string characters
    while (i < fen.len) {
        switch (fen[i]) {
            // Major and minor pieces
            'K', 'Q', 'R', 'B', 'N', 'P', 'k', 'q', 'r', 'b', 'n', 'p' => {
                const bit: u64 = @as(u64, 1) << index;
                switch (fen[i]) {
                    'K' => board.position.whitepieces.King.position |= bit,
                    'Q' => board.position.whitepieces.Queen.position |= bit,
                    'R' => {
                        board.position.whitepieces.Rook[blackrooks].position |= bit;
                        blackrooks += 1;
                    },
                    'B' => {
                        board.position.whitepieces.Bishop[blackbishops].position |= bit;
                        blackbishops += 1;
                    },
                    'N' => {
                        board.position.whitepieces.Knight[blackknights].position |= bit;
                        blackknights += 1;
                    },
                    'P' => {
                        board.position.whitepieces.Pawn[blackpawns].position |= bit;
                        blackpawns += 1;
                    },
                    'k' => board.position.blackpieces.King.position |= bit,
                    'q' => board.position.blackpieces.Queen.position |= bit,
                    'r' => {
                        board.position.blackpieces.Rook[whiterooks].position |= bit;
                        whiterooks += 1;
                    },
                    'b' => {
                        board.position.blackpieces.Bishop[whitebishops].position |= bit;
                        whitebishops += 1;
                    },
                    'n' => {
                        board.position.blackpieces.Knight[whiteknights].position |= bit;
                        whiteknights += 1;
                    },
                    'p' => {
                        board.position.blackpieces.Pawn[whitepawns].position |= bit;
                        whitepawns += 1;
                    },

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
    return board.position.flip();
}

test "print board" {
    var board: Board = Board{ .position = Position.init() };
    try std.testing.expectEqualStrings(&board.print(), "RNBKQBNRPPPPPPPP................................pppppppprnbkqbnr"[0..BoardSize]);
}

test "fen" {
    var board: Board = Board{ .position = parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR") };
    try std.testing.expectEqualStrings(&board.print(), "RNBKQBNRPPPPPPPP................................pppppppprnbkqbnr"[0..BoardSize]);
}

test "fen to board" {
    const board: Board = Board{ .position = parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR") };
    const board2: Board = Board{ .position = Position.init() };
    _ = board2.print();
    _ = board.print();
    // iterate through pieces in both board.Position and ensure they are the same
    // (@as(piece.type, @field(board.position.whitepieces, piece.name))).position
    inline for (std.meta.fields(@TypeOf(board.position.whitepieces))) |piece| {
        if (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == (Piece)) {
            std.debug.print("Comparing {s} {}\n", .{ piece.name, @as(u64, @field(board.position.whitepieces, piece.name).position) });
            try std.testing.expectEqual(@as(u64, @field(board.position.whitepieces, piece.name).position), @as(u64, @field(board2.position.whitepieces, piece.name).position));
        } else if ((@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == ([2]Piece)) or (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == ([8]Piece))) {
            inline for (0..@as(piece.type, @field(board.position.whitepieces, piece.name)).len) |i| {
                std.debug.print("Comparing {s} {} {}\n", .{ piece.name, i, @as(u64, @field(board.position.whitepieces, piece.name)[i].position) });
                try std.testing.expectEqual(@as(u64, @field(board.position.whitepieces, piece.name)[i].position), @as(u64, @field(board2.position.whitepieces, piece.name)[i].position));
            }
        }
    }
}
