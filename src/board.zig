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
    index: u8 = 0, // Track which instance of this piece type this is (0-based)
};

pub const WhiteKing: Piece = Piece{ .color = 0, .value = 255, .representation = 'K', .stdval = 255, .position = 0x0, .index = 0 };
pub const WhiteQueen: Piece = Piece{ .color = 0, .value = 9, .representation = 'Q', .stdval = 9, .position = 0x0, .index = 0 };
pub const WhiteRook: Piece = Piece{ .color = 0, .value = 5, .representation = 'R', .stdval = 5, .position = 0x0, .index = 0 };
pub const WhiteBishop: Piece = Piece{ .color = 0, .value = 3, .representation = 'B', .stdval = 3, .position = 0x0, .index = 0 };
pub const WhiteKnight: Piece = Piece{ .color = 0, .value = 3, .representation = 'N', .stdval = 3, .position = 0x0, .index = 0 };
pub const WhitePawn: Piece = Piece{ .color = 0, .value = 1, .representation = 'P', .stdval = 1, .position = 0x0, .index = 0 };
pub const BlackKing: Piece = Piece{ .color = 1, .value = 255, .representation = 'k', .stdval = 255, .position = 0x0, .index = 0 };
pub const BlackQueen: Piece = Piece{ .color = 1, .value = 9, .representation = 'q', .stdval = 9, .position = 0x0, .index = 0 };
pub const BlackRook: Piece = Piece{ .color = 1, .value = 5, .representation = 'r', .stdval = 5, .position = 0x0, .index = 0 };
pub const BlackBishop: Piece = Piece{ .color = 1, .value = 3, .representation = 'b', .stdval = 3, .position = 0x0, .index = 0 };
pub const BlackKnight: Piece = Piece{ .color = 1, .value = 3, .representation = 'n', .stdval = 3, .position = 0x0, .index = 0 };
pub const BlackPawn: Piece = Piece{ .color = 1, .value = 1, .representation = 'p', .stdval = 1, .position = 0x0, .index = 0 };
const Empty: Piece = Piece{ .color = 2, .value = 0, .representation = '.', .stdval = 0, .position = 0x0, .index = 0 };

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
    canCastleWhiteKingside: bool = false,
    canCastleWhiteQueenside: bool = false,
    canCastleBlackKingside: bool = false,
    canCastleBlackQueenside: bool = false,
    enPassantSquare: u64 = 0,
    sidetomove: u8 = 0, // 0 for white, 1 for black

    pub fn init() Position {
        var whitepieces: WhitePieces = WhitePieces{};
        var blackpieces: BlackPieces = BlackPieces{};
        whitepieces.King.position = c.E1;
        whitepieces.King.index = 0;
        whitepieces.Queen.position = c.D1;
        whitepieces.Queen.index = 0;
        whitepieces.Rook[0].position = c.A1;
        whitepieces.Rook[0].index = 0;
        whitepieces.Rook[1].position = c.H1;
        whitepieces.Rook[1].index = 1;
        whitepieces.Bishop[0].position = c.C1;
        whitepieces.Bishop[0].index = 0;
        whitepieces.Bishop[1].position = c.F1;
        whitepieces.Bishop[1].index = 1;
        whitepieces.Knight[0].position = c.B1;
        whitepieces.Knight[0].index = 0;
        whitepieces.Knight[1].position = c.G1;
        whitepieces.Knight[1].index = 1;

        // Initialize white pawns using constants
        const pawnPositions = [_]u64{
            c.A2, c.B2, c.C2, c.D2,
            c.E2, c.F2, c.G2, c.H2,
        };
        for (0..8) |i| {
            whitepieces.Pawn[i].position = pawnPositions[i];
            whitepieces.Pawn[i].index = @intCast(i);
        }

        blackpieces.King.position = c.E8;
        blackpieces.King.index = 0;
        blackpieces.Queen.position = c.D8;
        blackpieces.Queen.index = 0;
        blackpieces.Rook[0].position = reverse(whitepieces.Rook[0].position);
        blackpieces.Rook[0].index = 0;
        blackpieces.Rook[1].position = reverse(whitepieces.Rook[1].position);
        blackpieces.Rook[1].index = 1;
        blackpieces.Bishop[0].position = reverse(whitepieces.Bishop[0].position);
        blackpieces.Bishop[0].index = 0;
        blackpieces.Bishop[1].position = reverse(whitepieces.Bishop[1].position);
        blackpieces.Bishop[1].index = 1;
        blackpieces.Knight[0].position = reverse(whitepieces.Knight[0].position);
        blackpieces.Knight[0].index = 0;
        blackpieces.Knight[1].position = reverse(whitepieces.Knight[1].position);
        blackpieces.Knight[1].index = 1;
        for (0..8) |i| {
            blackpieces.Pawn[i].position = reverse(whitepieces.Pawn[i].position);
            blackpieces.Pawn[i].index = @intCast(i);
        }
        return Position{
            .whitepieces = whitepieces,
            .blackpieces = blackpieces,

            // By default, from standard chess opening, these are true:
            .canCastleWhiteKingside = true,
            .canCastleWhiteQueenside = true,
            .canCastleBlackKingside = true,
            .canCastleBlackQueenside = true,
            .enPassantSquare = 0,
            .sidetomove = 0, // White to move in initial position
        };
    }

    pub fn emptyboard() Position {
        return Position{
            .whitepieces = WhitePieces{},
            .blackpieces = BlackPieces{},

            // Typically, if you had an empty board, there's no castling:
            .canCastleWhiteKingside = false,
            .canCastleWhiteQueenside = false,
            .canCastleBlackKingside = false,
            .canCastleBlackQueenside = false,
            .enPassantSquare = 0,
            .sidetomove = 0, // White to move by default
        };
    }

    pub fn flip(self: Position) Position {
        var whitepieces: WhitePieces = self.whitepieces;
        var blackpieces: BlackPieces = self.blackpieces;
        whitepieces.King.position = reverse(whitepieces.King.position);
        whitepieces.King.index = self.whitepieces.King.index;
        whitepieces.Queen.position = reverse(whitepieces.Queen.position);
        whitepieces.Queen.index = self.whitepieces.Queen.index;
        whitepieces.Rook[0].position = reverse(whitepieces.Rook[0].position);
        whitepieces.Rook[0].index = self.whitepieces.Rook[0].index;
        whitepieces.Rook[1].position = reverse(whitepieces.Rook[1].position);
        whitepieces.Rook[1].index = self.whitepieces.Rook[1].index;
        whitepieces.Bishop[0].position = reverse(whitepieces.Bishop[0].position);
        whitepieces.Bishop[0].index = self.whitepieces.Bishop[0].index;
        whitepieces.Bishop[1].position = reverse(whitepieces.Bishop[1].position);
        whitepieces.Bishop[1].index = self.whitepieces.Bishop[1].index;
        whitepieces.Knight[0].position = reverse(whitepieces.Knight[0].position);
        whitepieces.Knight[0].index = self.whitepieces.Knight[0].index;
        whitepieces.Knight[1].position = reverse(whitepieces.Knight[1].position);
        whitepieces.Knight[1].index = self.whitepieces.Knight[1].index;
        whitepieces.Pawn[0].position = reverse(whitepieces.Pawn[0].position);
        whitepieces.Pawn[0].index = self.whitepieces.Pawn[0].index;
        whitepieces.Pawn[1].position = reverse(whitepieces.Pawn[1].position);
        whitepieces.Pawn[1].index = self.whitepieces.Pawn[1].index;
        whitepieces.Pawn[2].position = reverse(whitepieces.Pawn[2].position);
        whitepieces.Pawn[2].index = self.whitepieces.Pawn[2].index;
        whitepieces.Pawn[3].position = reverse(whitepieces.Pawn[3].position);
        whitepieces.Pawn[3].index = self.whitepieces.Pawn[3].index;
        whitepieces.Pawn[4].position = reverse(whitepieces.Pawn[4].position);
        whitepieces.Pawn[4].index = self.whitepieces.Pawn[4].index;
        whitepieces.Pawn[5].position = reverse(whitepieces.Pawn[5].position);
        whitepieces.Pawn[5].index = self.whitepieces.Pawn[5].index;
        whitepieces.Pawn[6].position = reverse(whitepieces.Pawn[6].position);
        whitepieces.Pawn[6].index = self.whitepieces.Pawn[6].index;
        whitepieces.Pawn[7].position = reverse(whitepieces.Pawn[7].position);
        whitepieces.Pawn[7].index = self.whitepieces.Pawn[7].index;
        blackpieces.King.position = reverse(blackpieces.King.position);
        blackpieces.King.index = self.blackpieces.King.index;
        blackpieces.Queen.position = reverse(blackpieces.Queen.position);
        blackpieces.Queen.index = self.blackpieces.Queen.index;
        blackpieces.Rook[0].position = reverse(blackpieces.Rook[0].position);
        blackpieces.Rook[0].index = self.blackpieces.Rook[0].index;
        blackpieces.Rook[1].position = reverse(blackpieces.Rook[1].position);
        blackpieces.Rook[1].index = self.blackpieces.Rook[1].index;
        blackpieces.Bishop[0].position = reverse(blackpieces.Bishop[0].position);
        blackpieces.Bishop[0].index = self.blackpieces.Bishop[0].index;
        blackpieces.Bishop[1].position = reverse(blackpieces.Bishop[1].position);
        blackpieces.Bishop[1].index = self.blackpieces.Bishop[1].index;
        blackpieces.Knight[0].position = reverse(blackpieces.Knight[0].position);
        blackpieces.Knight[0].index = self.blackpieces.Knight[0].index;
        blackpieces.Knight[1].position = reverse(blackpieces.Knight[1].position);
        blackpieces.Knight[1].index = self.blackpieces.Knight[1].index;
        blackpieces.Pawn[0].position = reverse(blackpieces.Pawn[0].position);
        blackpieces.Pawn[0].index = self.blackpieces.Pawn[0].index;
        blackpieces.Pawn[1].position = reverse(blackpieces.Pawn[1].position);
        blackpieces.Pawn[1].index = self.blackpieces.Pawn[1].index;
        blackpieces.Pawn[2].position = reverse(blackpieces.Pawn[2].position);
        blackpieces.Pawn[2].index = self.blackpieces.Pawn[2].index;
        blackpieces.Pawn[3].position = reverse(blackpieces.Pawn[3].position);
        blackpieces.Pawn[3].index = self.blackpieces.Pawn[3].index;
        blackpieces.Pawn[4].position = reverse(blackpieces.Pawn[4].position);
        blackpieces.Pawn[4].index = self.blackpieces.Pawn[4].index;
        blackpieces.Pawn[5].position = reverse(blackpieces.Pawn[5].position);
        blackpieces.Pawn[5].index = self.blackpieces.Pawn[5].index;
        blackpieces.Pawn[6].position = reverse(blackpieces.Pawn[6].position);
        blackpieces.Pawn[6].index = self.blackpieces.Pawn[6].index;
        blackpieces.Pawn[7].position = reverse(blackpieces.Pawn[7].position);
        blackpieces.Pawn[7].index = self.blackpieces.Pawn[7].index;

        return Position{
            .whitepieces = whitepieces,
            .blackpieces = blackpieces,
            .canCastleWhiteKingside = self.canCastleWhiteKingside,
            .canCastleWhiteQueenside = self.canCastleWhiteQueenside,
            .canCastleBlackKingside = self.canCastleBlackKingside,
            .canCastleBlackQueenside = self.canCastleBlackQueenside,
            .enPassantSquare = reverse(self.enPassantSquare),
            .sidetomove = self.sidetomove,
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
    sidetomove: u8 = 0, // 0 for white, 1 for black

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
    // A typical FEN has up to 6 fields:
    //   1) Piece placement
    //   2) Active color (w or b)
    //   3) Castling rights (KQkq or some subset, or "-")
    //   4) En-passant target square
    //   5) Halfmove clock
    //   6) Fullmove number
    //
    // We tokenize on spaces and parse only the fields we need:
    var tokens = std.mem.tokenizeAny(u8, fen, " ");
    const first_token = tokens.next();
    if (first_token == null) {
        // Invalid: no piece placement
        std.debug.print("FEN string empty or invalid piece placement\n", .{});
        return Position.emptyboard();
    }

    // 1) Parse piece placement
    const piecePlacement = first_token.?;
    // Start with an empty board:
    var position = Position.emptyboard();

    var index: u6 = 0;
    var i: usize = 0;
    while (i < piecePlacement.len) : (i += 1) {
        const ch = piecePlacement[i];
        switch (ch) {
            // Major + minor pieces
            inline 'K', 'Q', 'R', 'B', 'N', 'P', 'k', 'q', 'r', 'b', 'n', 'p' => {
                if (index >= 64) break;
                const bit: u64 = (@as(u64, 1) << @as(u6, index));
                switch (ch) {
                    'K' => {
                        position.whitepieces.King.position |= bit;
                        position.whitepieces.King.index = 0;
                    },
                    'Q' => {
                        position.whitepieces.Queen.position |= bit;
                        position.whitepieces.Queen.index = 0;
                    },
                    'R' => {
                        var rookCount: u6 = 0;
                        while (rookCount < position.whitepieces.Rook.len) : (rookCount += 1) {
                            if (position.whitepieces.Rook[rookCount].position == 0) {
                                position.whitepieces.Rook[rookCount].position = bit;
                                position.whitepieces.Rook[rookCount].index = rookCount;
                                break;
                            }
                        }
                    },
                    'B' => {
                        var bishopCount: u6 = 0;
                        while (bishopCount < position.whitepieces.Bishop.len) : (bishopCount += 1) {
                            if (position.whitepieces.Bishop[bishopCount].position == 0) {
                                position.whitepieces.Bishop[bishopCount].position = bit;
                                position.whitepieces.Bishop[bishopCount].index = bishopCount;
                                break;
                            }
                        }
                    },
                    'N' => {
                        var knightCount: u6 = 0;
                        while (knightCount < position.whitepieces.Knight.len) : (knightCount += 1) {
                            if (position.whitepieces.Knight[knightCount].position == 0) {
                                position.whitepieces.Knight[knightCount].position = bit;
                                position.whitepieces.Knight[knightCount].index = knightCount;
                                break;
                            }
                        }
                    },
                    'P' => {
                        var pawnCount: u6 = 0;
                        while (pawnCount < position.whitepieces.Pawn.len) : (pawnCount += 1) {
                            if (position.whitepieces.Pawn[pawnCount].position == 0) {
                                position.whitepieces.Pawn[pawnCount].position = bit;
                                position.whitepieces.Pawn[pawnCount].index = pawnCount;
                                break;
                            }
                        }
                    },
                    'k' => {
                        position.blackpieces.King.position |= bit;
                        position.blackpieces.King.index = 0;
                    },
                    'q' => {
                        position.blackpieces.Queen.position |= bit;
                        position.blackpieces.Queen.index = 0;
                    },
                    'r' => {
                        var rookCount: u6 = 0;
                        while (rookCount < position.blackpieces.Rook.len) : (rookCount += 1) {
                            if (position.blackpieces.Rook[rookCount].position == 0) {
                                position.blackpieces.Rook[rookCount].position = bit;
                                position.blackpieces.Rook[rookCount].index = rookCount;
                                break;
                            }
                        }
                    },
                    'b' => {
                        var bishopCount: u6 = 0;
                        while (bishopCount < position.blackpieces.Bishop.len) : (bishopCount += 1) {
                            if (position.blackpieces.Bishop[bishopCount].position == 0) {
                                position.blackpieces.Bishop[bishopCount].position = bit;
                                position.blackpieces.Bishop[bishopCount].index = bishopCount;
                                break;
                            }
                        }
                    },
                    'n' => {
                        var knightCount: u6 = 0;
                        while (knightCount < position.blackpieces.Knight.len) : (knightCount += 1) {
                            if (position.blackpieces.Knight[knightCount].position == 0) {
                                position.blackpieces.Knight[knightCount].position = bit;
                                position.blackpieces.Knight[knightCount].index = knightCount;
                                break;
                            }
                        }
                    },
                    'p' => {
                        var pawnCount: u6 = 0;
                        while (pawnCount < position.blackpieces.Pawn.len) : (pawnCount += 1) {
                            if (position.blackpieces.Pawn[pawnCount].position == 0) {
                                position.blackpieces.Pawn[pawnCount].position = bit;
                                position.blackpieces.Pawn[pawnCount].index = pawnCount;
                                break;
                            }
                        }
                    },
                    else => {},
                }
                if (index < 63) {
                    index += 1;
                } else {
                    break;
                }
            },
            '1'...'8' => {
                const empty_squares = ch - '0';
                if (index + empty_squares <= 63) {
                    index += @intCast(empty_squares);
                } else {
                    break;
                }
            },
            '/' => {
                // Just means new rank; nothing special to do besides continue
            },
            else => {
                // For safety, ignore/goto next character
            },
        }
        if (index >= 64) {
            // We read too many squares; the FEN might be malformed, but we just stop.
            break;
        }
    }

    // Because of the existing code convention, we flip at the end:
    position = position.flip();

    // Default to white's turn if not specified
    position.sidetomove = 0;

    const second_token = tokens.next();
    if (second_token == null) {
        // Invalid: no side to move
        std.debug.print("FEN string missing side to move\n", .{});
    } else {
        // Parse side to move
        const sideToMove = second_token.?;
        if (sideToMove[0] == 'b') {
            position.sidetomove = 1;
        } else {
            position.sidetomove = 0;
        }
    }

    const third_token = tokens.next();
    if (third_token != null) {
        const castling = third_token.?;
        // If FEN has '-', there are no castling rights
        if (!std.mem.eql(u8, castling, "-")) {
            if (std.mem.containsAtLeast(u8, castling, 1, "K")) {
                position.canCastleWhiteKingside = true;
            }
            if (std.mem.containsAtLeast(u8, castling, 1, "Q")) {
                position.canCastleWhiteQueenside = true;
            }
            if (std.mem.containsAtLeast(u8, castling, 1, "k")) {
                position.canCastleBlackKingside = true;
            }
            if (std.mem.containsAtLeast(u8, castling, 1, "q")) {
                position.canCastleBlackQueenside = true;
            }
        } else {
            // If exactly "-", then none are allowed
            position.canCastleWhiteKingside = false;
            position.canCastleWhiteQueenside = false;
            position.canCastleBlackKingside = false;
            position.canCastleBlackQueenside = false;
        }
    }

    // Parse en-passant square
    const fourth_token = tokens.next();
    if (fourth_token != null) {
        const enPassant = fourth_token.?;
        if (!std.mem.eql(u8, enPassant, "-")) {
            // Convert algebraic notation (e.g. "e3") to bitboard position
            const file = enPassant[0];
            const rank = enPassant[1];
            // Convert file letter to 0-7 index
            var fileIndex: u6 = undefined;
            switch (file) {
                'a' => fileIndex = 0,
                'b' => fileIndex = 1,
                'c' => fileIndex = 2,
                'd' => fileIndex = 3,
                'e' => fileIndex = 4,
                'f' => fileIndex = 5,
                'g' => fileIndex = 6,
                'h' => fileIndex = 7,
                else => fileIndex = 0,
            }
            // Convert rank number to 0-7 index
            var rankIndex: u6 = undefined;
            switch (rank) {
                '1' => rankIndex = 0,
                '2' => rankIndex = 1,
                '3' => rankIndex = 2,
                '4' => rankIndex = 3,
                '5' => rankIndex = 4,
                '6' => rankIndex = 5,
                '7' => rankIndex = 6,
                '8' => rankIndex = 7,
                else => rankIndex = 0,
            }
            const shift = rankIndex * 8 + fileIndex;
            position.enPassantSquare = @as(u64, 1) << @as(u6, shift);
            position.enPassantSquare = reverse(position.enPassantSquare); // Flip since we flip the whole position
        }
    }

    return position;
}

/// Convert a bitboard position to algebraic notation square (e.g., "e4")
pub fn bitboardToSquare(position: u64) [2]u8 {
    var result: [2]u8 = undefined;

    // Find the set bit position
    var temp = position;
    var square: u6 = 0;
    while (temp > 1) : (temp >>= 1) {
        square += 1;
    }

    // In our board representation:
    // - Files go from right to left (H=0 to A=7)
    // - Ranks go from bottom to top (1=0 to 8=7)
    const file = @as(u8, 'a') + (7 - @as(u8, @intCast(square % 8)));
    const rank = @as(u8, '1') + @as(u8, @intCast(square / 8));

    result[0] = file;
    result[1] = rank;
    return result;
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

test "flip symmetry returns original state after double flip" {
    const pos = Position.init();
    const flipped = pos.flip();
    const doubleFlipped = flipped.flip();
    try std.testing.expectEqual(pos.whitepieces.King.position, doubleFlipped.whitepieces.King.position);
    try std.testing.expectEqual(pos.whitepieces.Queen.position, doubleFlipped.whitepieces.Queen.position);
    inline for (0..pos.whitepieces.Rook.len) |i| {
        try std.testing.expectEqual(pos.whitepieces.Rook[i].position, doubleFlipped.whitepieces.Rook[i].position);
    }
    inline for (0..pos.whitepieces.Bishop.len) |i| {
        try std.testing.expectEqual(pos.whitepieces.Bishop[i].position, doubleFlipped.whitepieces.Bishop[i].position);
    }
    inline for (0..pos.whitepieces.Knight.len) |i| {
        try std.testing.expectEqual(pos.whitepieces.Knight[i].position, doubleFlipped.whitepieces.Knight[i].position);
    }
    inline for (0..pos.whitepieces.Pawn.len) |i| {
        try std.testing.expectEqual(pos.whitepieces.Pawn[i].position, doubleFlipped.whitepieces.Pawn[i].position);
    }
    try std.testing.expectEqual(pos.blackpieces.King.position, doubleFlipped.blackpieces.King.position);
    try std.testing.expectEqual(pos.blackpieces.Queen.position, doubleFlipped.blackpieces.Queen.position);
    inline for (0..pos.blackpieces.Rook.len) |i| {
        try std.testing.expectEqual(pos.blackpieces.Rook[i].position, doubleFlipped.blackpieces.Rook[i].position);
    }
    inline for (0..pos.blackpieces.Bishop.len) |i| {
        try std.testing.expectEqual(pos.blackpieces.Bishop[i].position, doubleFlipped.blackpieces.Bishop[i].position);
    }
    inline for (0..pos.blackpieces.Knight.len) |i| {
        try std.testing.expectEqual(pos.blackpieces.Knight[i].position, doubleFlipped.blackpieces.Knight[i].position);
    }
    inline for (0..pos.blackpieces.Pawn.len) |i| {
        try std.testing.expectEqual(pos.blackpieces.Pawn[i].position, doubleFlipped.blackpieces.Pawn[i].position);
    }
}

test "parse fen with castling rights" {
    const fenStr = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -";
    const pos = parseFen(fenStr);
    try std.testing.expect(pos.canCastleWhiteKingside);
    try std.testing.expect(pos.canCastleWhiteQueenside);
    try std.testing.expect(pos.canCastleBlackKingside);
    try std.testing.expect(pos.canCastleBlackQueenside);
}

test "parse complex fen with castling and en passant" {
    const fenStr = "rnbqk2r/ppp2ppp/3p4/2b1p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq e6";
    const pos = parseFen(fenStr);

    // Verify castling rights
    try std.testing.expect(pos.canCastleWhiteKingside);
    try std.testing.expect(pos.canCastleWhiteQueenside);
    try std.testing.expect(pos.canCastleBlackKingside);
    try std.testing.expect(pos.canCastleBlackQueenside);

    // Verify en passant square
    try std.testing.expect(pos.enPassantSquare != 0);

    // Verify side to move
    try std.testing.expectEqual(pos.sidetomove, 0);
}

test "parse fen with no castling rights" {
    const fenStr = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - -";
    const pos = parseFen(fenStr);

    try std.testing.expect(!pos.canCastleWhiteKingside);
    try std.testing.expect(!pos.canCastleWhiteQueenside);
    try std.testing.expect(!pos.canCastleBlackKingside);
    try std.testing.expect(!pos.canCastleBlackQueenside);
}

test "parse fen with partial castling rights" {
    const fenStr = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w Kk -";
    const pos = parseFen(fenStr);

    try std.testing.expect(pos.canCastleWhiteKingside);
    try std.testing.expect(!pos.canCastleWhiteQueenside);
    try std.testing.expect(pos.canCastleBlackKingside);
    try std.testing.expect(!pos.canCastleBlackQueenside);
}

test "parse fen with black to move" {
    const fenStr = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq -";
    const pos = parseFen(fenStr);

    try std.testing.expectEqual(pos.sidetomove, 1);
}

test "parse invalid fen handling" {
    // Test empty FEN
    const emptyPos = parseFen("");
    try std.testing.expectEqual(emptyPos.whitepieces.King.position, 0);

    // Test malformed FEN
    const malformedPos = parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP");
    try std.testing.expectEqual(malformedPos.sidetomove, 0); // Should default to white
}

test "empty board initialization" {
    const pos = Position.emptyboard();

    // Verify all pieces are at position 0
    try std.testing.expectEqual(pos.whitepieces.King.position, 0);
    try std.testing.expectEqual(pos.whitepieces.Queen.position, 0);
    try std.testing.expectEqual(pos.blackpieces.King.position, 0);
    try std.testing.expectEqual(pos.blackpieces.Queen.position, 0);

    // Verify no castling rights
    try std.testing.expect(!pos.canCastleWhiteKingside);
    try std.testing.expect(!pos.canCastleWhiteQueenside);
    try std.testing.expect(!pos.canCastleBlackKingside);
    try std.testing.expect(!pos.canCastleBlackQueenside);
}

test "board print with scattered pieces" {
    var board = Board{ .position = Position.emptyboard() };

    // Place some pieces in scattered positions
    board.position.whitepieces.King.position = c.E4;
    board.position.blackpieces.Queen.position = c.B6;
    board.position.whitepieces.Pawn[0].position = c.A2;
    board.position.blackpieces.Knight[1].position = c.F5;

    const printout = board.print();

    // The board is stored in a 64-bit integer with bits arranged like this:
    // 63 62 61 60 59 58 57 56  A8 B8 C8 D8 E8 F8 G8 H8
    // 55 54 53 52 51 50 49 48  A7 B7 C7 D7 E7 F7 G7 H7
    // 47 46 45 44 43 42 41 40  A6 B6 C6 D6 E6 F6 G6 H6
    // 39 38 37 36 35 34 33 32  A5 B5 C5 D5 E5 F5 G5 H5
    // 31 30 29 28 27 26 25 24  A4 B4 C4 D4 E4 F4 G4 H4
    // 23 22 21 20 19 18 17 16  A3 B3 C3 D3 E3 F3 G3 H3
    // 15 14 13 12 11 10  9  8  A2 B2 C2 D2 E2 F2 G2 H2
    //  7  6  5  4  3  2  1  0  A1 B1 C1 D1 E1 F1 G1 H1

    // E4 is at bit 27 (4th rank, 5th file)
    try std.testing.expectEqual(printout[27], 'K');

    // B6 is at bit 46 (6th rank, 2nd file)
    try std.testing.expectEqual(printout[46], 'q');

    // A2 is at bit 15 (2nd rank, 1st file)
    try std.testing.expectEqual(printout[15], 'P');

    // F5 is at bit 34 (5th rank, 6th file)
    try std.testing.expectEqual(printout[34], 'n');
}

test "reverse function symmetry" {
    const pos1: u64 = c.E4;
    const pos2 = reverse(pos1);
    const pos3 = reverse(pos2);

    try std.testing.expectEqual(pos1, pos3);
}

test "parse fen with multiple spaces" {
    const fenStr = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR  w  KQkq  -  0  1";
    const pos = parseFen(fenStr);

    // Should handle extra spaces gracefully
    try std.testing.expectEqual(pos.sidetomove, 0);
    try std.testing.expect(pos.canCastleWhiteKingside);
}

test "piece indices are set correctly in initial position" {
    const pos = Position.init();

    // Test white pieces
    try std.testing.expectEqual(pos.whitepieces.King.index, 0);
    try std.testing.expectEqual(pos.whitepieces.Queen.index, 0);
    try std.testing.expectEqual(pos.whitepieces.Rook[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Rook[1].index, 1);
    try std.testing.expectEqual(pos.whitepieces.Bishop[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Bishop[1].index, 1);
    try std.testing.expectEqual(pos.whitepieces.Knight[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Knight[1].index, 1);
    for (0..8) |i| {
        try std.testing.expectEqual(pos.whitepieces.Pawn[i].index, i);
    }

    // Test black pieces
    try std.testing.expectEqual(pos.blackpieces.King.index, 0);
    try std.testing.expectEqual(pos.blackpieces.Queen.index, 0);
    try std.testing.expectEqual(pos.blackpieces.Rook[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Rook[1].index, 1);
    try std.testing.expectEqual(pos.blackpieces.Bishop[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Bishop[1].index, 1);
    try std.testing.expectEqual(pos.blackpieces.Knight[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Knight[1].index, 1);
    for (0..8) |i| {
        try std.testing.expectEqual(pos.blackpieces.Pawn[i].index, i);
    }
}

test "piece indices are preserved in FEN parsing" {
    const fenStr = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -";
    const pos = parseFen(fenStr);

    // Test white pieces
    try std.testing.expectEqual(pos.whitepieces.King.index, 0);
    try std.testing.expectEqual(pos.whitepieces.Queen.index, 0);
    try std.testing.expectEqual(pos.whitepieces.Rook[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Rook[1].index, 1);
    try std.testing.expectEqual(pos.whitepieces.Bishop[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Bishop[1].index, 1);
    try std.testing.expectEqual(pos.whitepieces.Knight[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Knight[1].index, 1);
    for (0..8) |i| {
        try std.testing.expectEqual(pos.whitepieces.Pawn[i].index, i);
    }

    // Test black pieces
    try std.testing.expectEqual(pos.blackpieces.King.index, 0);
    try std.testing.expectEqual(pos.blackpieces.Queen.index, 0);
    try std.testing.expectEqual(pos.blackpieces.Rook[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Rook[1].index, 1);
    try std.testing.expectEqual(pos.blackpieces.Bishop[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Bishop[1].index, 1);
    try std.testing.expectEqual(pos.blackpieces.Knight[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Knight[1].index, 1);
    for (0..8) |i| {
        try std.testing.expectEqual(pos.blackpieces.Pawn[i].index, i);
    }
}

test "piece indices are set correctly in custom position" {
    // Test a position with some pieces removed to ensure indices are still sequential
    const fenStr = "r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq -";
    const pos = parseFen(fenStr);

    // Test white pieces
    try std.testing.expectEqual(pos.whitepieces.King.index, 0);
    try std.testing.expectEqual(pos.whitepieces.Queen.index, 0);
    try std.testing.expectEqual(pos.whitepieces.Rook[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Rook[1].index, 1);
    try std.testing.expectEqual(pos.whitepieces.Bishop[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Knight[0].index, 0);
    try std.testing.expectEqual(pos.whitepieces.Knight[1].index, 1);

    // Test black pieces
    try std.testing.expectEqual(pos.blackpieces.King.index, 0);
    try std.testing.expectEqual(pos.blackpieces.Queen.index, 0);
    try std.testing.expectEqual(pos.blackpieces.Rook[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Rook[1].index, 1);
    try std.testing.expectEqual(pos.blackpieces.Bishop[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Bishop[1].index, 1);
    try std.testing.expectEqual(pos.blackpieces.Knight[0].index, 0);
    try std.testing.expectEqual(pos.blackpieces.Knight[1].index, 1);
}

test "bitboardToSquare converts positions correctly" {
    try std.testing.expectEqualStrings("e2", &bitboardToSquare(c.E2));
    try std.testing.expectEqualStrings("e4", &bitboardToSquare(c.E4));
    try std.testing.expectEqualStrings("a1", &bitboardToSquare(c.A1));
    try std.testing.expectEqualStrings("h8", &bitboardToSquare(c.H8));
}
