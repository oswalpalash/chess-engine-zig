const std = @import("std");
const b = @import("board.zig");
const c = @import("consts.zig");

// Import the reverse function from board.zig
const reverse = b.reverse;

/// Represents a chess move from one square to another
pub const Move = struct {
    from: u64, // Bitboard position of source square
    to: u64, // Bitboard position of target square
    promotion_piece: ?u8 = null, // Optional promotion piece (e.g., 'q' for queen)

    /// Convert a move to UCI string format (e.g., "e2e4" or "e7e8q")
    pub fn toUciString(self: Move) ![5]u8 {
        var result: [5]u8 = undefined;

        // Convert source square
        const from_square = b.bitboardToSquare(self.from);
        result[0] = from_square[0];
        result[1] = from_square[1];

        // Convert target square
        const to_square = b.bitboardToSquare(self.to);
        result[2] = to_square[0];
        result[3] = to_square[1];

        // Add promotion piece if present
        if (self.promotion_piece) |piece| {
            result[4] = piece;
        } else {
            result[4] = 0;
        }

        return result;
    }
};

/// Parse a UCI move string (e.g., "e2e4" or "e7e8q") into a Move structure
pub fn parseUciMove(token: []const u8) !Move {
    if (token.len < 4 or token.len > 5) {
        return error.InvalidMoveFormat;
    }

    // Parse source square
    const from_file = token[0];
    const from_rank = token[1];
    if (from_file < 'a' or from_file > 'h' or from_rank < '1' or from_rank > '8') {
        return error.InvalidSquare;
    }

    // Parse target square
    const to_file = token[2];
    const to_rank = token[3];
    if (to_file < 'a' or to_file > 'h' or to_rank < '1' or to_rank > '8') {
        return error.InvalidSquare;
    }

    // Convert algebraic notation to bitboard positions
    const from_file_idx = from_file - 'a';
    const from_rank_idx = from_rank - '1';
    const to_file_idx = to_file - 'a';
    const to_rank_idx = to_rank - '1';

    // Calculate bitboard positions
    const from_pos = @as(u64, 1) << @intCast(from_rank_idx * 8 + (7 - from_file_idx));
    const to_pos = @as(u64, 1) << @intCast(to_rank_idx * 8 + (7 - to_file_idx));

    // Check for promotion
    var promotion_piece: ?u8 = null;
    if (token.len == 5) {
        const piece = token[4];
        switch (piece) {
            'q', 'r', 'b', 'n' => promotion_piece = piece,
            else => return error.InvalidPromotionPiece,
        }
    }

    return Move{
        .from = from_pos,
        .to = to_pos,
        .promotion_piece = promotion_piece,
    };
}

test "import works" {
    const board = b.Board{ .position = b.Position.init() };
    try std.testing.expectEqual(board.move_count, 0);
    try std.testing.expectEqual(board.position.whitepieces.King.position, c.E1);
}

const pawnShifts = [4]u6{ 8, 16, 7, 9 };

// takes in a board and iterates through all pieces and returns a 64 bit representation of the board
pub fn bitmapfromboard(board: b.Board) u64 {
    var bitmap: u64 = 0;
    const cpiece = b.Piece{ .color = 0, .value = 1, .representation = 'P', .stdval = 1, .position = 0 };
    _ = cpiece;
    inline for (std.meta.fields(@TypeOf(board.position.whitepieces))) |piece| {
        if (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == (b.Piece)) {
            bitmap |= (@as(piece.type, @field(board.position.whitepieces, piece.name))).position;
        } else if (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == ([2]b.Piece) or @TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == ([8]b.Piece)) {
            for (@as(piece.type, @field(board.position.whitepieces, piece.name))) |item| {
                bitmap |= item.position;
            }
        }
    }
    inline for (std.meta.fields(@TypeOf(board.position.blackpieces))) |piece| {
        if (@TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == (b.Piece)) {
            bitmap |= (@as(piece.type, @field(board.position.blackpieces, piece.name))).position;
        } else if (@TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == ([2]b.Piece) or @TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == ([8]b.Piece)) {
            for (@as(piece.type, @field(board.position.blackpieces, piece.name))) |item| {
                bitmap |= item.position;
            }
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
    inline for (std.meta.fields(@TypeOf(board.position.whitepieces))) |piece| {
        if (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == (b.Piece)) {
            if ((@as(piece.type, @field(board.position.whitepieces, piece.name))).position == location) {
                return (@as(piece.type, @field(board.position.whitepieces, piece.name)));
            }
        } else if (@TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == ([2]b.Piece) or @TypeOf(@as(piece.type, @field(board.position.whitepieces, piece.name))) == ([8]b.Piece)) {
            for (@as(piece.type, @field(board.position.whitepieces, piece.name))) |item| {
                if (item.position == location) {
                    return item;
                }
            }
        }
    }
    inline for (std.meta.fields(@TypeOf(board.position.blackpieces))) |piece| {
        if (@TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == (b.Piece)) {
            if ((@as(piece.type, @field(board.position.blackpieces, piece.name))).position == location) {
                return (@as(piece.type, @field(board.position.blackpieces, piece.name)));
            }
        } else if (@TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == ([2]b.Piece) or @TypeOf(@as(piece.type, @field(board.position.blackpieces, piece.name))) == ([8]b.Piece)) {
            for (@as(piece.type, @field(board.position.blackpieces, piece.name))) |item| {
                if (item.position == location) {
                    return item;
                }
            }
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
            boardCopy.position.blackpieces.Queen.position = 0;
            piece.position = 0;
        },
        'r' => {
            if (boardCopy.position.blackpieces.Rook[0].position == loc) {
                boardCopy.position.blackpieces.Rook[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Rook[1].position == loc) {
                boardCopy.position.blackpieces.Rook[1].position = 0;
                piece.position = 0;
            }
        },
        'b' => {
            if (boardCopy.position.blackpieces.Bishop[0].position == loc) {
                boardCopy.position.blackpieces.Bishop[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Bishop[1].position == loc) {
                boardCopy.position.blackpieces.Bishop[1].position = 0;
                piece.position = 0;
            }
        },
        'n' => {
            if (boardCopy.position.blackpieces.Knight[0].position == loc) {
                boardCopy.position.blackpieces.Knight[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.blackpieces.Knight[1].position == loc) {
                boardCopy.position.blackpieces.Knight[1].position = 0;
                piece.position = 0;
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

test "ensure self captures are not allowed. add a3 pawn in init board and check pawn moves for a2 pawn" {
    var board = b.Board{ .position = b.Position.init() };
    board.position.whitepieces.Pawn[7].position = c.A3;
    _ = board.print();
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 0);
}

// Valid pawn moves for both white and black pawns
// Returns an array of boards representing all possible moves for the given pawn
pub fn ValidPawnMoves(piece: b.Piece, board: b.Board) []b.Board {
    // Validate pawn position
    const row = rowfrombitmap(piece.position);
    if ((piece.color == 0 and row == 1) or (piece.color == 1 and row == 8)) {
        return &[_]b.Board{}; // Invalid pawn position
    }

    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u6 = 0;
    var index: u64 = 0;

    // Find which pawn we're moving
    if (piece.color == 0) {
        for (board.position.whitepieces.Pawn, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    } else {
        for (board.position.blackpieces.Pawn, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    }

    const currentRow = rowfrombitmap(piece.position);
    const currentCol = colfrombitmap(piece.position);

    // Direction modifiers based on piece color
    const forwardShift: i8 = if (piece.color == 0) 8 else -8;

    // Starting row and promotion row based on color
    const startingRow: u64 = if (piece.color == 0) 2 else 7;
    const promotionRow: u64 = if (piece.color == 0) 7 else 2;

    // Single square forward move
    var oneSquareForward: u64 = 0;
    if (forwardShift > 0) {
        oneSquareForward = piece.position << @as(u6, @intCast(forwardShift));
    } else {
        oneSquareForward = piece.position >> @as(u6, @intCast(-forwardShift));
    }

    if (bitmap & oneSquareForward == 0) {
        if (currentRow == promotionRow) {
            // Promotion moves - remove pawn and create new pieces
            const promotionPieces = [_]struct {
                white_piece: b.Piece,
                black_piece: b.Piece,
            }{
                .{
                    .white_piece = b.WhiteQueen,
                    .black_piece = b.BlackQueen,
                },
                .{
                    .white_piece = b.WhiteRook,
                    .black_piece = b.BlackRook,
                },
                .{
                    .white_piece = b.WhiteBishop,
                    .black_piece = b.BlackBishop,
                },
                .{
                    .white_piece = b.WhiteKnight,
                    .black_piece = b.BlackKnight,
                },
            };

            for (promotionPieces) |promotion| {
                var promotionBoard = b.Board{ .position = board.position };
                if (piece.color == 0) {
                    // Remove the pawn
                    promotionBoard.position.whitepieces.Pawn[index].position = 0;
                    // Create new piece at promotion square
                    var new_piece = promotion.white_piece;
                    new_piece.position = oneSquareForward;
                    switch (new_piece.representation) {
                        'Q' => promotionBoard.position.whitepieces.Queen = new_piece,
                        'R' => {
                            const rook_idx = findNextAvailableIndex(&promotionBoard.position.whitepieces.Rook);
                            if (rook_idx < promotionBoard.position.whitepieces.Rook.len) {
                                promotionBoard.position.whitepieces.Rook[rook_idx] = new_piece;
                            }
                        },
                        'B' => {
                            const bishop_idx = findNextAvailableIndex(&promotionBoard.position.whitepieces.Bishop);
                            if (bishop_idx < promotionBoard.position.whitepieces.Bishop.len) {
                                promotionBoard.position.whitepieces.Bishop[bishop_idx] = new_piece;
                            }
                        },
                        'N' => {
                            const knight_idx = findNextAvailableIndex(&promotionBoard.position.whitepieces.Knight);
                            if (knight_idx < promotionBoard.position.whitepieces.Knight.len) {
                                promotionBoard.position.whitepieces.Knight[knight_idx] = new_piece;
                            }
                        },
                        else => unreachable,
                    }
                } else {
                    // Remove the pawn
                    promotionBoard.position.blackpieces.Pawn[index].position = 0;
                    // Create new piece at promotion square
                    var new_piece = promotion.black_piece;
                    new_piece.position = oneSquareForward;
                    switch (new_piece.representation) {
                        'q' => promotionBoard.position.blackpieces.Queen = new_piece,
                        'r' => {
                            const rook_idx = findNextAvailableIndex(&promotionBoard.position.blackpieces.Rook);
                            if (rook_idx < promotionBoard.position.blackpieces.Rook.len) {
                                promotionBoard.position.blackpieces.Rook[rook_idx] = new_piece;
                            }
                        },
                        'b' => {
                            const bishop_idx = findNextAvailableIndex(&promotionBoard.position.blackpieces.Bishop);
                            if (bishop_idx < promotionBoard.position.blackpieces.Bishop.len) {
                                promotionBoard.position.blackpieces.Bishop[bishop_idx] = new_piece;
                            }
                        },
                        'n' => {
                            const knight_idx = findNextAvailableIndex(&promotionBoard.position.blackpieces.Knight);
                            if (knight_idx < promotionBoard.position.blackpieces.Knight.len) {
                                promotionBoard.position.blackpieces.Knight[knight_idx] = new_piece;
                            }
                        },
                        else => unreachable,
                    }
                }
                moves[possiblemoves] = promotionBoard;
                possiblemoves += 1;
            }
        } else if ((piece.color == 0 and currentRow < 7) or (piece.color == 1 and currentRow > 2)) {
            // Regular move
            var singleMoveBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                singleMoveBoard.position.whitepieces.Pawn[index].position = oneSquareForward;
            } else {
                singleMoveBoard.position.blackpieces.Pawn[index].position = oneSquareForward;
            }
            moves[possiblemoves] = singleMoveBoard;
            possiblemoves += 1;

            // Two square forward move from starting position
            if (currentRow == startingRow) {
                var twoSquareForward: u64 = 0;
                if (forwardShift > 0) {
                    twoSquareForward = piece.position << @as(u6, @intCast(forwardShift * 2));
                } else {
                    twoSquareForward = piece.position >> @as(u6, @intCast(-forwardShift * 2));
                }

                if (bitmap & twoSquareForward == 0 and bitmap & oneSquareForward == 0) {
                    var doubleMoveBoard = b.Board{ .position = board.position };
                    if (piece.color == 0) {
                        doubleMoveBoard.position.whitepieces.Pawn[index].position = twoSquareForward;
                        doubleMoveBoard.position.enPassantSquare = oneSquareForward;
                    } else {
                        doubleMoveBoard.position.blackpieces.Pawn[index].position = twoSquareForward;
                        doubleMoveBoard.position.enPassantSquare = oneSquareForward;
                    }
                    moves[possiblemoves] = doubleMoveBoard;
                    possiblemoves += 1;
                }
            }
        }
    }

    // Diagonal captures
    var leftCapture: u64 = 0;
    var rightCapture: u64 = 0;

    // Calculate capture positions based on color and column constraints
    if (piece.color == 0) {
        leftCapture = if (currentCol > 1) piece.position << 7 else 0;
        rightCapture = if (currentCol < 8) piece.position << 9 else 0;
    } else {
        leftCapture = if (currentCol < 8) piece.position >> 7 else 0;
        rightCapture = if (currentCol > 1) piece.position >> 9 else 0;
    }

    // Check left capture
    if (leftCapture != 0) {
        if (bitmap & leftCapture != 0) {
            const targetPiece = piecefromlocation(leftCapture, board);
            if (targetPiece.color != piece.color) {
                if (currentRow == promotionRow) {
                    // Promotion on capture
                    const promotionPieces = [_]struct {
                        white_piece: b.Piece,
                        black_piece: b.Piece,
                    }{
                        .{
                            .white_piece = b.WhiteQueen,
                            .black_piece = b.BlackQueen,
                        },
                        .{
                            .white_piece = b.WhiteRook,
                            .black_piece = b.BlackRook,
                        },
                        .{
                            .white_piece = b.WhiteBishop,
                            .black_piece = b.BlackBishop,
                        },
                        .{
                            .white_piece = b.WhiteKnight,
                            .black_piece = b.BlackKnight,
                        },
                    };

                    for (promotionPieces) |promotion| {
                        var capturePromotionBoard = if (piece.color == 0)
                            captureblackpiece(leftCapture, b.Board{ .position = board.position })
                        else
                            capturewhitepiece(leftCapture, b.Board{ .position = board.position });

                        if (piece.color == 0) {
                            // Remove the pawn
                            capturePromotionBoard.position.whitepieces.Pawn[index].position = 0;
                            // Create new piece at capture square
                            var new_piece = promotion.white_piece;
                            new_piece.position = leftCapture;
                            switch (new_piece.representation) {
                                'Q' => capturePromotionBoard.position.whitepieces.Queen = new_piece,
                                'R' => {
                                    const rook_idx = findNextAvailableIndex(&capturePromotionBoard.position.whitepieces.Rook);
                                    if (rook_idx < capturePromotionBoard.position.whitepieces.Rook.len) {
                                        capturePromotionBoard.position.whitepieces.Rook[rook_idx] = new_piece;
                                    }
                                },
                                'B' => {
                                    const bishop_idx = findNextAvailableIndex(&capturePromotionBoard.position.whitepieces.Bishop);
                                    if (bishop_idx < capturePromotionBoard.position.whitepieces.Bishop.len) {
                                        capturePromotionBoard.position.whitepieces.Bishop[bishop_idx] = new_piece;
                                    }
                                },
                                'N' => {
                                    const knight_idx = findNextAvailableIndex(&capturePromotionBoard.position.whitepieces.Knight);
                                    if (knight_idx < capturePromotionBoard.position.whitepieces.Knight.len) {
                                        capturePromotionBoard.position.whitepieces.Knight[knight_idx] = new_piece;
                                    }
                                },
                                else => unreachable,
                            }
                        } else {
                            // Remove the pawn
                            capturePromotionBoard.position.blackpieces.Pawn[index].position = 0;
                            // Create new piece at capture square
                            var new_piece = promotion.black_piece;
                            new_piece.position = leftCapture;
                            switch (new_piece.representation) {
                                'q' => capturePromotionBoard.position.blackpieces.Queen = new_piece,
                                'r' => {
                                    const rook_idx = findNextAvailableIndex(&capturePromotionBoard.position.blackpieces.Rook);
                                    if (rook_idx < capturePromotionBoard.position.blackpieces.Rook.len) {
                                        capturePromotionBoard.position.blackpieces.Rook[rook_idx] = new_piece;
                                    }
                                },
                                'b' => {
                                    const bishop_idx = findNextAvailableIndex(&capturePromotionBoard.position.blackpieces.Bishop);
                                    if (bishop_idx < capturePromotionBoard.position.blackpieces.Bishop.len) {
                                        capturePromotionBoard.position.blackpieces.Bishop[bishop_idx] = new_piece;
                                    }
                                },
                                'n' => {
                                    const knight_idx = findNextAvailableIndex(&capturePromotionBoard.position.blackpieces.Knight);
                                    if (knight_idx < capturePromotionBoard.position.blackpieces.Knight.len) {
                                        capturePromotionBoard.position.blackpieces.Knight[knight_idx] = new_piece;
                                    }
                                },
                                else => unreachable,
                            }
                        }
                        moves[possiblemoves] = capturePromotionBoard;
                        possiblemoves += 1;
                    }
                } else {
                    var captureBoard = if (piece.color == 0)
                        captureblackpiece(leftCapture, b.Board{ .position = board.position })
                    else
                        capturewhitepiece(leftCapture, b.Board{ .position = board.position });

                    if (piece.color == 0) {
                        captureBoard.position.whitepieces.Pawn[index].position = leftCapture;
                    } else {
                        captureBoard.position.blackpieces.Pawn[index].position = leftCapture;
                    }
                    moves[possiblemoves] = captureBoard;
                    possiblemoves += 1;
                }
            }
        } else if (leftCapture == board.position.enPassantSquare) {
            // En passant capture to the left
            var enPassantBoard = b.Board{ .position = board.position };
            var capturedPawnPos: u64 = 0;

            if (piece.color == 0) {
                enPassantBoard.position.whitepieces.Pawn[index].position = leftCapture;
                capturedPawnPos = leftCapture >> 8;
                enPassantBoard = captureblackpiece(capturedPawnPos, enPassantBoard);
            } else {
                enPassantBoard.position.blackpieces.Pawn[index].position = leftCapture;
                capturedPawnPos = leftCapture << 8;
                enPassantBoard = capturewhitepiece(capturedPawnPos, enPassantBoard);
            }
            enPassantBoard.position.enPassantSquare = 0;
            moves[possiblemoves] = enPassantBoard;
            possiblemoves += 1;
        }
    }

    // Check right capture
    if (rightCapture != 0) {
        if (bitmap & rightCapture != 0) {
            const targetPiece = piecefromlocation(rightCapture, board);
            if (targetPiece.color != piece.color) {
                if (currentRow == promotionRow) {
                    // Promotion on capture
                    const promotionPieces = [_]struct {
                        white_piece: b.Piece,
                        black_piece: b.Piece,
                    }{
                        .{
                            .white_piece = b.WhiteQueen,
                            .black_piece = b.BlackQueen,
                        },
                        .{
                            .white_piece = b.WhiteRook,
                            .black_piece = b.BlackRook,
                        },
                        .{
                            .white_piece = b.WhiteBishop,
                            .black_piece = b.BlackBishop,
                        },
                        .{
                            .white_piece = b.WhiteKnight,
                            .black_piece = b.BlackKnight,
                        },
                    };

                    for (promotionPieces) |promotion| {
                        var capturePromotionBoard = if (piece.color == 0)
                            captureblackpiece(rightCapture, b.Board{ .position = board.position })
                        else
                            capturewhitepiece(rightCapture, b.Board{ .position = board.position });

                        if (piece.color == 0) {
                            // Remove the pawn
                            capturePromotionBoard.position.whitepieces.Pawn[index].position = 0;
                            // Create new piece at capture square
                            var new_piece = promotion.white_piece;
                            new_piece.position = rightCapture;
                            switch (new_piece.representation) {
                                'Q' => capturePromotionBoard.position.whitepieces.Queen = new_piece,
                                'R' => {
                                    const rook_idx = findNextAvailableIndex(&capturePromotionBoard.position.whitepieces.Rook);
                                    if (rook_idx < capturePromotionBoard.position.whitepieces.Rook.len) {
                                        capturePromotionBoard.position.whitepieces.Rook[rook_idx] = new_piece;
                                    }
                                },
                                'B' => {
                                    const bishop_idx = findNextAvailableIndex(&capturePromotionBoard.position.whitepieces.Bishop);
                                    if (bishop_idx < capturePromotionBoard.position.whitepieces.Bishop.len) {
                                        capturePromotionBoard.position.whitepieces.Bishop[bishop_idx] = new_piece;
                                    }
                                },
                                'N' => {
                                    const knight_idx = findNextAvailableIndex(&capturePromotionBoard.position.whitepieces.Knight);
                                    if (knight_idx < capturePromotionBoard.position.whitepieces.Knight.len) {
                                        capturePromotionBoard.position.whitepieces.Knight[knight_idx] = new_piece;
                                    }
                                },
                                else => unreachable,
                            }
                        } else {
                            // Remove the pawn
                            capturePromotionBoard.position.blackpieces.Pawn[index].position = 0;
                            // Create new piece at capture square
                            var new_piece = promotion.black_piece;
                            new_piece.position = rightCapture;
                            switch (new_piece.representation) {
                                'q' => capturePromotionBoard.position.blackpieces.Queen = new_piece,
                                'r' => {
                                    const rook_idx = findNextAvailableIndex(&capturePromotionBoard.position.blackpieces.Rook);
                                    if (rook_idx < capturePromotionBoard.position.blackpieces.Rook.len) {
                                        capturePromotionBoard.position.blackpieces.Rook[rook_idx] = new_piece;
                                    }
                                },
                                'b' => {
                                    const bishop_idx = findNextAvailableIndex(&capturePromotionBoard.position.blackpieces.Bishop);
                                    if (bishop_idx < capturePromotionBoard.position.blackpieces.Bishop.len) {
                                        capturePromotionBoard.position.blackpieces.Bishop[bishop_idx] = new_piece;
                                    }
                                },
                                'n' => {
                                    const knight_idx = findNextAvailableIndex(&capturePromotionBoard.position.blackpieces.Knight);
                                    if (knight_idx < capturePromotionBoard.position.blackpieces.Knight.len) {
                                        capturePromotionBoard.position.blackpieces.Knight[knight_idx] = new_piece;
                                    }
                                },
                                else => unreachable,
                            }
                        }
                        moves[possiblemoves] = capturePromotionBoard;
                        possiblemoves += 1;
                    }
                } else {
                    var captureBoard = if (piece.color == 0)
                        captureblackpiece(rightCapture, b.Board{ .position = board.position })
                    else
                        capturewhitepiece(rightCapture, b.Board{ .position = board.position });

                    if (piece.color == 0) {
                        captureBoard.position.whitepieces.Pawn[index].position = rightCapture;
                    } else {
                        captureBoard.position.blackpieces.Pawn[index].position = rightCapture;
                    }
                    moves[possiblemoves] = captureBoard;
                    possiblemoves += 1;
                }
            }
        } else if (rightCapture == board.position.enPassantSquare) {
            // En passant capture to the right
            var enPassantBoard = b.Board{ .position = board.position };
            var capturedPawnPos: u64 = 0;

            if (piece.color == 0) {
                enPassantBoard.position.whitepieces.Pawn[index].position = rightCapture;
                capturedPawnPos = rightCapture >> 8;
                enPassantBoard = captureblackpiece(capturedPawnPos, enPassantBoard);
            } else {
                enPassantBoard.position.blackpieces.Pawn[index].position = rightCapture;
                capturedPawnPos = rightCapture << 8;
                enPassantBoard = capturewhitepiece(capturedPawnPos, enPassantBoard);
            }
            enPassantBoard.position.enPassantSquare = 0;
            moves[possiblemoves] = enPassantBoard;
            possiblemoves += 1;
        }
    }

    return moves[0..possiblemoves];
}

test "ValidPawnMoves from e2 in start position" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2);
}

test "ValidPawnMoves from e7 in empty board" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[3].position = c.E7;
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 4); // Should have 4 promotion options
}

test "ValidPawnMoves for black pawn from e7 in start position" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidPawnMoves(board.position.blackpieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2); // e7 pawn can move to e6 and e5
}

test "ValidPawnMoves for black pawn from e2 in empty board" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[3].position = c.E2;
    const moves = ValidPawnMoves(board.position.blackpieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 4); // Should have 4 promotion options

    // Verify all promotion pieces are present
    var foundQueen = false;
    var foundRook = false;
    var foundBishop = false;
    var foundKnight = false;

    for (moves) |move| {
        // Verify pawn is removed
        try std.testing.expectEqual(move.position.blackpieces.Pawn[3].position, 0);

        // Check which piece was created at E1
        if (move.position.blackpieces.Queen.position == c.E1) {
            foundQueen = true;
            try std.testing.expectEqual(move.position.blackpieces.Queen.representation, 'q');
            try std.testing.expectEqual(move.position.blackpieces.Queen.color, 1);
        } else if (move.position.blackpieces.Rook[0].position == c.E1) {
            foundRook = true;
            try std.testing.expectEqual(move.position.blackpieces.Rook[0].representation, 'r');
            try std.testing.expectEqual(move.position.blackpieces.Rook[0].color, 1);
        } else if (move.position.blackpieces.Bishop[0].position == c.E1) {
            foundBishop = true;
            try std.testing.expectEqual(move.position.blackpieces.Bishop[0].representation, 'b');
            try std.testing.expectEqual(move.position.blackpieces.Bishop[0].color, 1);
        } else if (move.position.blackpieces.Knight[0].position == c.E1) {
            foundKnight = true;
            try std.testing.expectEqual(move.position.blackpieces.Knight[0].representation, 'n');
            try std.testing.expectEqual(move.position.blackpieces.Knight[0].color, 1);
        }
    }

    try std.testing.expect(foundQueen);
    try std.testing.expect(foundRook);
    try std.testing.expect(foundBishop);
    try std.testing.expect(foundKnight);
}

test "ValidPawnMoves for black pawn capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[3].position = c.E6;
    board.position.whitepieces.Pawn[2].position = c.D5;
    const moves = ValidPawnMoves(board.position.blackpieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 2); // Can move to e5 or capture on d5

    var foundCapture = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[3].position == c.D5) {
            foundCapture = true;
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
        }
    }
    try std.testing.expect(foundCapture);
}

test "ValidPawnMoves for black pawn en passant capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[3].position = c.E4;
    board.position.whitepieces.Pawn[2].position = c.D4;
    board.position.enPassantSquare = c.D3; // Simulate white pawn just moved D2->D4
    const moves = ValidPawnMoves(board.position.blackpieces.Pawn[3], board);

    var foundEnPassant = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[3].position == c.D3) {
            foundEnPassant = true;
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
            try std.testing.expectEqual(move.position.enPassantSquare, 0);
        }
    }
    try std.testing.expect(foundEnPassant);
}

test "ValidPawnMoves for black pawn promotion on capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[3].position = c.E2;
    board.position.whitepieces.Pawn[2].position = c.D1;
    const moves = ValidPawnMoves(board.position.blackpieces.Pawn[3], board);

    // Should have 8 moves total - 4 straight promotions and 4 capture promotions
    try std.testing.expectEqual(moves.len, 8);

    var foundPromotionCapture = false;
    for (moves) |move| {
        // Check for capture promotions to d1
        if (move.position.blackpieces.Queen.position == c.D1 or
            move.position.blackpieces.Rook[0].position == c.D1 or
            move.position.blackpieces.Bishop[0].position == c.D1 or
            move.position.blackpieces.Knight[0].position == c.D1)
        {
            foundPromotionCapture = true;
            // Verify captured pawn is removed
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
            // Verify original pawn is removed
            try std.testing.expectEqual(move.position.blackpieces.Pawn[3].position, 0);
        }
    }
    try std.testing.expect(foundPromotionCapture);
}

test "pawn capture e3 f4 or go to e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[3].position = c.E3;
    board.position.blackpieces.Pawn[2].position = c.F4;
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[3], board);
    try std.testing.expectEqual(moves.len, 2);
    try std.testing.expectEqual(moves[1].position.blackpieces.Pawn[2].position, 0);
    try std.testing.expectEqual(moves[0].position.blackpieces.Pawn[2].position, c.F4);
    try std.testing.expectEqual(moves[0].position.whitepieces.Pawn[3].position, c.E4);
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

pub fn colfrombitmap(bitmap: u64) u64 {
    const cols = [8]u6{ 0, 1, 2, 3, 4, 5, 6, 7 };
    for (cols) |i| {
        if (bitmap & (@as(u64, 0x0101010101010101) << i) != 0) {
            return 8 - i;
        }
    }
    return 0;
}

test "rowfrombitmap and colfrombitmap for black rook at a8" {
    const board = b.Board{ .position = b.Position.init() };
    const blackRook = board.position.blackpieces.Rook[1]; // A8 rook
    const row = rowfrombitmap(blackRook.position);
    const col = colfrombitmap(blackRook.position);
    try std.testing.expectEqual(row, 8);
    try std.testing.expectEqual(col, 1);
}

// Valid rook moves
pub fn ValidRookMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    var index: u64 = 0; // Initialize with a default value

    // Find which rook we're moving
    if (piece.color == 0) {
        for (board.position.whitepieces.Rook, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    } else {
        for (board.position.blackpieces.Rook, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    }

    const row: u64 = rowfrombitmap(piece.position);
    const col: u64 = colfrombitmap(piece.position);

    // Define the four directions a rook can move: up, down, left, right
    const directions = [_]struct { shift: i8, max_steps: u6 }{
        .{ .shift = 8, .max_steps = @intCast(8 - row) }, // up
        .{ .shift = -8, .max_steps = @intCast(row - 1) }, // down
        .{ .shift = -1, .max_steps = @intCast(col - 1) }, // left
        .{ .shift = 1, .max_steps = @intCast(8 - col) }, // right
    };

    // Check moves in each direction
    for (directions) |dir| {
        if (dir.max_steps == 0) continue;

        var steps: u6 = 1;
        while (steps <= dir.max_steps) : (steps += 1) {
            const shift: i8 = dir.shift * @as(i8, @intCast(steps));
            var newpos: u64 = undefined;

            if (shift > 0) {
                newpos = piece.position << @as(u6, @intCast(shift));
            } else {
                newpos = piece.position >> @as(u6, @intCast(-shift));
            }

            if (newpos == 0) break;

            // Check if square is empty
            if (bitmap & newpos == 0) {
                var newBoard = b.Board{ .position = board.position };
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Rook[index].position = newpos;
                } else {
                    newBoard.position.blackpieces.Rook[index].position = newpos;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            } else {
                // Square is occupied - check if it's an enemy piece
                const targetPiece = piecefromlocation(newpos, board);
                if (targetPiece.color != piece.color) {
                    var newBoard = if (piece.color == 0)
                        captureblackpiece(newpos, b.Board{ .position = board.position })
                    else
                        capturewhitepiece(newpos, b.Board{ .position = board.position });

                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Rook[index].position = newpos;
                    } else {
                        newBoard.position.blackpieces.Rook[index].position = newpos;
                    }
                    moves[possiblemoves] = newBoard;
                    possiblemoves += 1;
                }
                break; // Stop checking this direction after hitting any piece
            }
        }
    }

    return moves[0..possiblemoves];
}

test "ValidRookMoves for empty board with rook on e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.E4;
    const moves = ValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // 7 horizontal + 7 vertical moves
}

test "ValidRookMoves for black rook captures" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Rook[0].position = c.E4;
    board.position.whitepieces.Pawn[0].position = c.E6; // Can be captured
    board.position.whitepieces.Pawn[1].position = c.C4; // Can be captured
    board.position.blackpieces.Pawn[0].position = c.E3; // Blocks movement

    const moves = ValidRookMoves(board.position.blackpieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 8); // 2 captures + 6 empty squares

    // Verify captures are possible
    var foundCaptures = false;
    for (moves) |move| {
        if (move.position.whitepieces.Pawn[0].position == 0 or
            move.position.whitepieces.Pawn[1].position == 0)
        {
            foundCaptures = true;
            break;
        }
    }
    try std.testing.expect(foundCaptures);
}

test "ValidRookMoves blocked by own pieces" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.E4;
    // Place friendly pieces to block in all directions
    board.position.whitepieces.Pawn[0].position = c.E5;
    board.position.whitepieces.Pawn[1].position = c.E3;
    board.position.whitepieces.Pawn[2].position = c.D4;
    board.position.whitepieces.Pawn[3].position = c.F4;

    const moves = ValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 0); // No moves possible
}

test "ValidRookMoves edge cases" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Test from corner
    board.position.whitepieces.Rook[0].position = c.A1;
    var moves = ValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // 7 up + 7 right

    // Test from edge
    board.position.whitepieces.Rook[0].position = c.A4;
    moves = ValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // 7 horizontal + 7 vertical
}

// New test to verify that the black rook at A8 in the initial board has 0 moves
test "ValidRookMoves for black rook at a8 in initial board" {
    const board = b.Board{ .position = b.Position.init() };
    // Based on our board setup, the black rook at A8 is stored in blackpieces.Rook[1]
    const moves = ValidRookMoves(board.position.blackpieces.Rook[1], board);
    try std.testing.expectEqual(moves.len, 0);
}

// Valid king moves
pub fn ValidKingMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    var king: b.Piece = piece;
    var dummypiece: b.Piece = undefined;
    const directional_kingshifts = [4]u6{ 1, 7, 8, 9 };
    // forward moves
    for (directional_kingshifts) |shift| {
        if (piece.position << shift == 0) {
            continue;
        }
        // if there is no piece, allow shifting
        // if there is a piece, check if it is of different colour, if so, capture it
        // if it is of same colour, don't allow shifting
        if (bitmap & (piece.position << shift) == 0) {
            dummypiece = piecefromlocation(piece.position << shift, board);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == piece.color) {
                    continue;
                }
            }
            king.position = piece.position << shift;
            // update board
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.King.position = king.position;
            } else {
                newBoard.position.blackpieces.King.position = king.position;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            if (bitmap & (piece.position << shift) != 0) {
                dummypiece = piecefromlocation(piece.position << shift, board);
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != piece.color) {
                        king.position = piece.position << shift;
                        // update board with appropriate capture
                        var newBoard = if (piece.color == 0)
                            captureblackpiece(king.position, b.Board{ .position = board.position })
                        else
                            capturewhitepiece(king.position, b.Board{ .position = board.position });

                        if (piece.color == 0) {
                            newBoard.position.whitepieces.King.position = king.position;
                        } else {
                            newBoard.position.blackpieces.King.position = king.position;
                        }
                        moves[possiblemoves] = newBoard;
                        possiblemoves += 1;
                    }
                }
            }
        }
    }
    king = piece;
    // reverse moves
    for (directional_kingshifts) |shift| {
        if (king.position >> shift == 0) {
            continue;
        }
        if (bitmap & (king.position >> shift) == 0) {
            dummypiece = piecefromlocation(piece.position >> shift, board);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == piece.color) {
                    continue;
                }
            }
            king.position = piece.position >> shift;
            // update board
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.King.position = king.position;
            } else {
                newBoard.position.blackpieces.King.position = king.position;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            if (bitmap & (piece.position >> shift) != 0) {
                dummypiece = piecefromlocation(piece.position >> shift, board);
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != piece.color) {
                        king.position = piece.position >> shift;
                        // update board with appropriate capture
                        var newBoard = if (piece.color == 0)
                            captureblackpiece(king.position, b.Board{ .position = board.position })
                        else
                            capturewhitepiece(king.position, b.Board{ .position = board.position });

                        if (piece.color == 0) {
                            newBoard.position.whitepieces.King.position = king.position;
                        } else {
                            newBoard.position.blackpieces.King.position = king.position;
                        }
                        moves[possiblemoves] = newBoard;
                        possiblemoves += 1;
                    }
                }
            }
        }
    }

    // Add castling moves for white king (kingside) if available
    if (piece.color == 0 and board.position.canCastleWhiteKingside and piece.position == c.E1) {
        // Check if squares F1 and G1 are empty
        if ((bitmap & c.F1) == 0 and (bitmap & c.G1) == 0) {
            var castledKing = piece;
            castledKing.position = c.G1; // king moves two squares towards rook
            var newBoard = board;
            newBoard.position.whitepieces.King = castledKing;
            // Update kingside rook: from H1 to F1
            newBoard.position.whitepieces.Rook[1].position = c.F1;
            // Remove castling right
            newBoard.position.canCastleWhiteKingside = false;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    // Add castling moves for black king (kingside) if available
    if (piece.color == 1 and board.position.canCastleBlackKingside and piece.position == c.E8) {
        // Check if squares F8 and G8 are empty
        if ((bitmap & c.F8) == 0 and (bitmap & c.G8) == 0) {
            var castledKing = piece;
            castledKing.position = c.G8; // king moves two squares towards rook
            var newBoard = board;
            newBoard.position.blackpieces.King = castledKing;
            // Update kingside rook: from H8 to F8
            newBoard.position.blackpieces.Rook[1].position = c.F8;
            // Remove castling right
            newBoard.position.canCastleBlackKingside = false;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    return moves[0..possiblemoves];
}

test "ValidKingMoves for empty board with king on e1" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E4;
    _ = board.print();
    const moves = ValidKingMoves(board.position.whitepieces.King, board);
    try std.testing.expectEqual(moves.len, 8);
}

test "ValidKingMoves for init board with king on e1" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidKingMoves(board.position.whitepieces.King, board);
    try std.testing.expectEqual(moves.len, 0);
}

test "ValidKingMoves for empty board with king on e1 and black piece on e2" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E1;
    board.position.blackpieces.Pawn[4].position = c.E2;
    const moves = ValidKingMoves(board.position.whitepieces.King, board);
    try std.testing.expectEqual(moves.len, 5);
}

test "ValidKingMoves for black king on empty board" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E4;
    const moves = ValidKingMoves(board.position.blackpieces.King, board);
    try std.testing.expectEqual(moves.len, 8); // Should have 8 moves in all directions

    // Verify the king's position is updated correctly in the resulting boards
    for (moves) |move| {
        try std.testing.expectEqual(move.position.blackpieces.King.position != c.E4, true);
        try std.testing.expectEqual(move.position.whitepieces.King.position, 0);
    }
}

test "ValidKingMoves for black king with captures" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E4;
    // Place white pieces to capture
    board.position.whitepieces.Pawn[0].position = c.E5;
    board.position.whitepieces.Pawn[1].position = c.F4;
    // Place black piece to block
    board.position.blackpieces.Pawn[0].position = c.D4;

    const moves = ValidKingMoves(board.position.blackpieces.King, board);
    try std.testing.expectEqual(moves.len, 7); // 8 directions - 1 blocked

    // Verify captures work correctly
    var captureFound = false;
    for (moves) |move| {
        if (move.position.blackpieces.King.position == c.E5 or
            move.position.blackpieces.King.position == c.F4)
        {
            captureFound = true;
            // Check that the captured piece is removed
            if (move.position.blackpieces.King.position == c.E5) {
                try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);
            } else {
                try std.testing.expectEqual(move.position.whitepieces.Pawn[1].position, 0);
            }
        }
    }
    try std.testing.expect(captureFound);
}

// Valid knight moves
pub fn ValidKnightMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;

    // Find the correct index for the knight
    var index: u8 = 0;
    if (piece.color == 0) {
        // White knight
        if (board.position.whitepieces.Knight[0].position == piece.position) {
            index = 0;
        } else if (board.position.whitepieces.Knight[1].position == piece.position) {
            index = 1;
        } else {
            // Knight not found, return empty array
            return moves[0..0];
        }
    } else {
        // Black knight
        if (board.position.blackpieces.Knight[0].position == piece.position) {
            index = 0;
        } else if (board.position.blackpieces.Knight[1].position == piece.position) {
            index = 1;
        } else {
            // Knight not found, return empty array
            return moves[0..0];
        }
    }

    // Define all possible knight move shifts
    // These represent the 8 possible L-shaped moves a knight can make
    const knightShifts = [_]struct { shift: i8, mask: u64 }{
        .{ .shift = 6, .mask = 0xFCFCFCFCFCFCFCFC }, // Up 1, Left 2 (not from a,b files)
        .{ .shift = 10, .mask = 0x3F3F3F3F3F3F3F3F }, // Up 1, Right 2 (not from g,h files)
        .{ .shift = 15, .mask = 0xFEFEFEFEFEFEFEFE }, // Up 2, Left 1 (not from a file)
        .{ .shift = 17, .mask = 0x7F7F7F7F7F7F7F7F }, // Up 2, Right 1 (not from h file)
        .{ .shift = -6, .mask = 0x3F3F3F3F3F3F3F3F }, // Down 1, Right 2 (not from g,h files)
        .{ .shift = -10, .mask = 0xFCFCFCFCFCFCFCFC }, // Down 1, Left 2 (not from a,b files)
        .{ .shift = -15, .mask = 0x7F7F7F7F7F7F7F7F }, // Down 2, Right 1 (not from h file)
        .{ .shift = -17, .mask = 0xFEFEFEFEFEFEFEFE }, // Down 2, Left 1 (not from a file)
    };

    // Check each possible knight move
    for (knightShifts) |move| {
        // Apply the mask to ensure we don't wrap around the board
        if ((piece.position & move.mask) == 0) continue;

        var newpos: u64 = undefined;
        if (move.shift > 0) {
            newpos = piece.position << @as(u6, @intCast(move.shift));
        } else {
            newpos = piece.position >> @as(u6, @intCast(-move.shift));
        }

        // Skip if the position is invalid (should not happen with proper masks)
        if (newpos == 0) continue;

        // Check if target square is empty
        if (bitmap & newpos == 0) {
            // Empty square - add move
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Knight[index].position = newpos;
            } else {
                newBoard.position.blackpieces.Knight[index].position = newpos;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            // Square is occupied - check if it's an enemy piece
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                // Capture enemy piece
                var newBoard = if (piece.color == 0)
                    captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    capturewhitepiece(newpos, b.Board{ .position = board.position });

                if (piece.color == 0) {
                    newBoard.position.whitepieces.Knight[index].position = newpos;
                } else {
                    newBoard.position.blackpieces.Knight[index].position = newpos;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        }
    }

    return moves[0..possiblemoves];
}

test "ValidKnightMoves for empty board with knight on e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.E4;
    _ = board.print();
    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 8); // Knight should have all 8 possible moves
}

test "ValidKnightMoves for init board with knight on b1" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to a3 and c3
}

test "ValidKnightMoves for empty board with knight on b1 and black piece on c3" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.B1;
    board.position.blackpieces.Pawn[2].position = c.C3;
    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 3); // Can move to a3, c3 (capture), and d2
}

test "ValidKnightMoves for corner positions" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Test from a1 corner
    board.position.whitepieces.Knight[0].position = c.A1;
    var moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to b3 and c2

    // Test from h8 corner
    board.position.whitepieces.Knight[0].position = c.H8;
    moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to f7 and g6
}

test "ValidKnightMoves with both knights" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.B1;
    board.position.whitepieces.Knight[1].position = c.G1;

    const moves1 = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves1.len, 3); // Can move to a3, c3, and d2

    const moves2 = ValidKnightMoves(board.position.whitepieces.Knight[1], board);
    try std.testing.expectEqual(moves2.len, 3); // Can move to e2, f3, and h3
}

test "ValidKnightMoves captures" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.E4;

    // Place some black pieces in knight's path
    board.position.blackpieces.Pawn[0].position = c.F6; // Can be captured
    board.position.blackpieces.Pawn[1].position = c.D6; // Can be captured
    board.position.whitepieces.Pawn[0].position = c.G5; // Blocked by own piece

    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 7); // 8 possible moves - 1 blocked by own piece

    // Verify captures are possible
    var foundCaptures = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[0].position == 0 or
            move.position.blackpieces.Pawn[1].position == 0)
        {
            foundCaptures = true;
            break;
        }
    }
    try std.testing.expect(foundCaptures);
}

pub fn ValidBishopMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    var index: u64 = 0; // Initialize with a default value

    // Find which bishop we're moving
    if (piece.color == 0) {
        for (board.position.whitepieces.Bishop, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    } else {
        for (board.position.blackpieces.Bishop, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                index = loopidx;
                break;
            }
        }
    }

    const row = rowfrombitmap(piece.position);
    const col = colfrombitmap(piece.position);

    // Bishop moves along diagonals
    const bishopshifts = [7]u6{ 1, 2, 3, 4, 5, 6, 7 };

    // Up-Right diagonal moves (NE)
    for (bishopshifts) |shift| {
        if (row + shift > 8 or col + shift > 8) break;

        const newpos = piece.position << (shift * 7);
        if (newpos == 0) break;

        // Check if target square is empty
        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Bishop[index].position = newpos;
            } else {
                newBoard.position.blackpieces.Bishop[index].position = newpos;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            // Check if enemy piece (possible capture)
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    capturewhitepiece(newpos, b.Board{ .position = board.position });
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Bishop[index].position = newpos;
                } else {
                    newBoard.position.blackpieces.Bishop[index].position = newpos;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
            break; // Stop in this direction after capture or blocked
        }
    }

    // Up-Left diagonal moves (NW)
    for (bishopshifts) |shift| {
        if (row + shift > 8 or col <= shift) break;

        const newpos = piece.position << (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Bishop[index].position = newpos;
            } else {
                newBoard.position.blackpieces.Bishop[index].position = newpos;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    capturewhitepiece(newpos, b.Board{ .position = board.position });
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Bishop[index].position = newpos;
                } else {
                    newBoard.position.blackpieces.Bishop[index].position = newpos;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
            break;
        }
    }

    // Down-Right diagonal moves (SE)
    for (bishopshifts) |shift| {
        if (row <= shift or col + shift > 8) break;

        const newpos = piece.position >> (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Bishop[index].position = newpos;
            } else {
                newBoard.position.blackpieces.Bishop[index].position = newpos;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    capturewhitepiece(newpos, b.Board{ .position = board.position });
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Bishop[index].position = newpos;
                } else {
                    newBoard.position.blackpieces.Bishop[index].position = newpos;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
            break;
        }
    }

    // Down-Left diagonal moves (SW)
    for (bishopshifts) |shift| {
        if (row <= shift or col <= shift) break;

        const newpos = piece.position >> (shift * 7);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Bishop[index].position = newpos;
            } else {
                newBoard.position.blackpieces.Bishop[index].position = newpos;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    capturewhitepiece(newpos, b.Board{ .position = board.position });
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Bishop[index].position = newpos;
                } else {
                    newBoard.position.blackpieces.Bishop[index].position = newpos;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
            break;
        }
    }

    return moves[0..possiblemoves];
}

test "ValidBishopMoves for empty board with bishop on e4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Bishop[0].position = c.E4;
    _ = board.print();

    const moves = ValidBishopMoves(board.position.whitepieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 13); // Bishop on e4 can move to 13 squares

    // Verify specific positions
    var foundPositions = [_]bool{false} ** 13;
    const expectedPositions = [_]u64{
        c.D5, c.C6, c.B7, c.A8, // Up-Left diagonal
        c.F5, c.G6, c.H7, // Up-Right diagonal
        c.D3, c.C2, c.B1, // Down-Left diagonal
        c.F3, c.G2, c.H1, // Down-Right diagonal
    };

    for (moves) |move| {
        const pos = move.position.whitepieces.Bishop[0].position;
        for (expectedPositions, 0..) |expected, i| {
            if (pos == expected) {
                foundPositions[i] = true;
            }
        }
    }

    // Verify all expected positions were found
    for (foundPositions) |found| {
        try std.testing.expect(found);
    }
}

test "ValidBishopMoves for bishop on c1 in initial position" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidBishopMoves(board.position.whitepieces.Bishop[1], board);
    try std.testing.expectEqual(moves.len, 0); // Bishop should be blocked by pawns
}

test "ValidBishopMoves with captures" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Bishop[0].position = c.E4;

    // Place black pieces to capture
    board.position.blackpieces.Pawn[0].position = c.C6; // Up-Left
    board.position.blackpieces.Pawn[1].position = c.G6; // Up-Right
    board.position.blackpieces.Pawn[2].position = c.C2; // Down-Left
    board.position.blackpieces.Pawn[3].position = c.G2; // Down-Right

    // Place white piece to block
    board.position.whitepieces.Pawn[0].position = c.F5; // Blocks further Up-Right movement

    const moves = ValidBishopMoves(board.position.whitepieces.Bishop[0], board);

    // Expected moves:
    // Up-Left: d5, c6(capture)
    // Up-Right: f5(blocked)
    // Down-Left: d3, c2(capture)
    // Down-Right: f3, g2(capture)
    try std.testing.expectEqual(moves.len, 6);

    // Verify captures result in removed pieces
    var captureFound = false;
    for (moves) |move| {
        if (move.position.whitepieces.Bishop[0].position == c.C6) {
            try std.testing.expectEqual(move.position.blackpieces.Pawn[0].position, 0);
            captureFound = true;
        }
    }
    try std.testing.expect(captureFound);
}

test "ValidBishopMoves edge cases" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Test from corner
    board.position.whitepieces.Bishop[0].position = c.A1;
    var moves = ValidBishopMoves(board.position.whitepieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 7); // Can only move diagonally up-right

    // Test from edge
    board.position.whitepieces.Bishop[0].position = c.A4;
    moves = ValidBishopMoves(board.position.whitepieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 7); // Can move diagonally up-right and down-right
}

pub fn ValidQueenMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    const queen: b.Piece = piece;

    const shifts = [7]u6{ 1, 2, 3, 4, 5, 6, 7 };
    const row: u64 = rowfrombitmap(queen.position);
    const col: u64 = colfrombitmap(queen.position);
    var newqueen: b.Piece = queen;
    var testpiece: b.Piece = undefined;

    // Rook-like moves
    // Forward moves
    for (shifts) |shift| {
        if (row + shift > 8) break;
        const newpos = queen.position << (shift * 8);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = piecefromlocation(newpos, board);
            if (testpiece.color != queen.color) {
                newqueen.position = newpos;
                if (queen.color == 0) {
                    moves[possiblemoves] = captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Backward moves
    for (shifts) |shift| {
        if (row <= shift) break;
        const newpos = queen.position >> (shift * 8);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = piecefromlocation(newpos, board);
            if (testpiece.color != queen.color) {
                newqueen.position = newpos;
                if (queen.color == 0) {
                    moves[possiblemoves] = captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Left moves
    for (shifts) |shift| {
        if (col <= shift) break;
        const newpos = queen.position << shift;
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = piecefromlocation(newpos, board);
            if (testpiece.color != queen.color) {
                newqueen.position = newpos;
                if (queen.color == 0) {
                    moves[possiblemoves] = captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Right moves
    for (shifts) |shift| {
        if (col + shift > 8) break;
        const newpos = queen.position >> shift;
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = piecefromlocation(newpos, board);
            if (testpiece.color != queen.color) {
                newqueen.position = newpos;
                if (queen.color == 0) {
                    moves[possiblemoves] = captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Bishop-like moves
    // Up-Left diagonal
    for (shifts) |shift| {
        if (row + shift > 8 or col <= shift) break;
        const newpos = queen.position << (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = piecefromlocation(newpos, board);
            if (testpiece.color != queen.color) {
                newqueen.position = newpos;
                if (queen.color == 0) {
                    moves[possiblemoves] = captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Up-Right diagonal
    for (shifts) |shift| {
        if (row + shift > 8 or col + shift > 8) break;
        const newpos = queen.position << (shift * 7);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = piecefromlocation(newpos, board);
            if (testpiece.color != queen.color) {
                newqueen.position = newpos;
                if (queen.color == 0) {
                    moves[possiblemoves] = captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Down-Left diagonal
    for (shifts) |shift| {
        if (row <= shift or col <= shift) break;
        const newpos = queen.position >> (shift * 7);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = piecefromlocation(newpos, board);
            if (testpiece.color != queen.color) {
                newqueen.position = newpos;
                if (queen.color == 0) {
                    moves[possiblemoves] = captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    // Down-Right diagonal
    for (shifts) |shift| {
        if (row <= shift or col + shift > 8) break;
        const newpos = queen.position >> (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = piecefromlocation(newpos, board);
            if (testpiece.color != queen.color) {
                newqueen.position = newpos;
                if (queen.color == 0) {
                    moves[possiblemoves] = captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    return moves[0..possiblemoves];
}

// Test cases for ValidQueenMoves
test "ValidQueenMoves for initial board (no moves expected)" {
    const board = b.Board{ .position = b.Position.init() };
    const queen = board.position.whitepieces.Queen;
    const moves = ValidQueenMoves(queen, board);
    try std.testing.expectEqual(moves.len, 0); // Queen is blocked by own pieces
}

test "ValidQueenMoves for empty board with queen on d4" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.D4;
    _ = board.print();

    const moves = ValidQueenMoves(board.position.whitepieces.Queen, board);

    // Expected moves: 27 moves (all directions until the edge of the board)
    try std.testing.expect(moves.len == 27);
}

test "ValidQueenMoves for empty board with queen on a1" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.A1;
    _ = board.print();

    const moves = ValidQueenMoves(board.position.whitepieces.Queen, board);

    // From a1, queen can move to:
    // a2-a8, b1-h1, b2-h8 => total 7 + 7 + 7 = 21 moves
    try std.testing.expect(moves.len == 21);
}

test "ValidQueenMoves with obstacles" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.D4;
    // Place friendly pieces at d5 and e4
    board.position.whitepieces.Pawn[0].position = c.D5;
    board.position.whitepieces.Pawn[1].position = c.E4;
    // Place enemy piece at c5 and e5
    board.position.blackpieces.Pawn[0].position = c.C5;
    board.position.blackpieces.Pawn[1].position = c.E5;
    _ = board.print();

    const moves = ValidQueenMoves(board.position.whitepieces.Queen, board);

    // Expected moves:
    // d5 blocked by own piece (no move up)
    // d3, d2, d1
    // e4 captures own piece (invalid), so no moves east
    // c4, b4, a4
    // e5 captures enemy piece
    // c5 captures enemy piece
    // e3, f2, g1
    // c3, b2, a1

    try std.testing.expect(moves.len == 14);
}

// Color-specific move functions
pub fn getValidPawnMoves(piece: b.Piece, board: b.Board) []b.Board {
    return ValidPawnMoves(piece, board);
}

test "getValidPawnMoves works for white pawns" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidPawnMoves(board.position.whitepieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2); // e2 pawn can move to e3 and e4
}

test "getValidPawnMoves works for black pawns" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidPawnMoves(board.position.blackpieces.Pawn[4], board);
    try std.testing.expectEqual(moves.len, 2); // e7 pawn can move to e6 and e5
}

pub fn getValidRookMoves(piece: b.Piece, board: b.Board) []b.Board {
    return ValidRookMoves(piece, board);
}

test "getValidRookMoves works for white rooks" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.E4;
    const moves = getValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // Rook on e4 can move to 14 squares
}

test "getValidRookMoves works for black rooks" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Rook[0].position = c.E4;
    const moves = getValidRookMoves(board.position.blackpieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14); // Rook on e4 can move to 14 squares (7 horizontal + 7 vertical)
}

pub fn getValidKnightMoves(piece: b.Piece, board: b.Board) []b.Board {
    return ValidKnightMoves(piece, board);
}

test "getValidKnightMoves works for white knights" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // b1 knight can move to a3 and c3
}

test "getValidKnightMoves works for black knights" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = getValidKnightMoves(board.position.blackpieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // b8 knight can move to a6 and c6
}

pub fn getValidBishopMoves(piece: b.Piece, board: b.Board) []b.Board {
    return ValidBishopMoves(piece, board);
}

test "getValidBishopMoves works for white bishops" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Bishop[0].position = c.E4;
    const moves = getValidBishopMoves(board.position.whitepieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 13); // Bishop on e4 can move to 13 squares
}

test "getValidBishopMoves works for black bishops" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Bishop[0].position = c.E4;
    const moves = getValidBishopMoves(board.position.blackpieces.Bishop[0], board);
    try std.testing.expectEqual(moves.len, 13); // Bishop on e4 can move to 13 squares
}

pub fn getValidQueenMoves(piece: b.Piece, board: b.Board) []b.Board {
    return ValidQueenMoves(piece, board);
}

test "getValidQueenMoves works for white queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Queen.position = c.E4;
    const moves = getValidQueenMoves(board.position.whitepieces.Queen, board);
    try std.testing.expectEqual(moves.len, 27); // Queen on e4 can move to 27 squares
}

test "getValidQueenMoves works for black queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Queen.position = c.E4;
    const moves = getValidQueenMoves(board.position.blackpieces.Queen, board);
    try std.testing.expectEqual(moves.len, 27); // Queen on e4 can move to 27 squares
}

pub fn getValidKingMoves(piece: b.Piece, board: b.Board) []b.Board {
    return ValidKingMoves(piece, board);
}

test "getValidKingMoves works for white king" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.King.position = c.E4;
    const moves = getValidKingMoves(board.position.whitepieces.King, board);
    try std.testing.expectEqual(moves.len, 8); // King on e4 can move to 8 squares
}

test "getValidKingMoves works for black king" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E4;
    const moves = getValidKingMoves(board.position.blackpieces.King, board);
    try std.testing.expectEqual(moves.len, 8); // King on e4 can move to 8 squares
}

test "ValidKnightMoves unordered test for knight on b1" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.B1;
    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    var foundC3 = false;
    var foundA3 = false;
    for (moves) |move| {
        const newPos = move.position.whitepieces.Knight[0].position;
        if (newPos == c.C3) foundC3 = true;
        if (newPos == c.A3) foundA3 = true;
    }
    try std.testing.expect(foundC3);
    try std.testing.expect(foundA3);
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
            boardCopy.position.whitepieces.Queen.position = 0;
            piece.position = 0;
        },
        'R' => {
            if (boardCopy.position.whitepieces.Rook[0].position == loc) {
                boardCopy.position.whitepieces.Rook[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Rook[1].position == loc) {
                boardCopy.position.whitepieces.Rook[1].position = 0;
                piece.position = 0;
            }
        },
        'B' => {
            if (boardCopy.position.whitepieces.Bishop[0].position == loc) {
                boardCopy.position.whitepieces.Bishop[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Bishop[1].position == loc) {
                boardCopy.position.whitepieces.Bishop[1].position = 0;
                piece.position = 0;
            }
        },
        'N' => {
            if (boardCopy.position.whitepieces.Knight[0].position == loc) {
                boardCopy.position.whitepieces.Knight[0].position = 0;
                piece.position = 0;
            } else if (boardCopy.position.whitepieces.Knight[1].position == loc) {
                boardCopy.position.whitepieces.Knight[1].position = 0;
                piece.position = 0;
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

test "ValidPawnMoves promotion on reaching 8th rank" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 4); // Must have all 4 promotion options (Q,R,B,N)

    // Verify all promotion pieces are available
    var foundQueen = false;
    var foundRook = false;
    var foundBishop = false;
    var foundKnight = false;

    for (moves) |move| {
        // Verify pawn is removed
        try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);

        // Check which piece was created at E8
        if (move.position.whitepieces.Queen.position == c.E8) {
            foundQueen = true;
            try std.testing.expectEqual(move.position.whitepieces.Queen.representation, 'Q');
            try std.testing.expectEqual(move.position.whitepieces.Queen.color, 0);
        } else if (move.position.whitepieces.Rook[0].position == c.E8) {
            foundRook = true;
            try std.testing.expectEqual(move.position.whitepieces.Rook[0].representation, 'R');
            try std.testing.expectEqual(move.position.whitepieces.Rook[0].color, 0);
        } else if (move.position.whitepieces.Bishop[0].position == c.E8) {
            foundBishop = true;
            try std.testing.expectEqual(move.position.whitepieces.Bishop[0].representation, 'B');
            try std.testing.expectEqual(move.position.whitepieces.Bishop[0].color, 0);
        } else if (move.position.whitepieces.Knight[0].position == c.E8) {
            foundKnight = true;
            try std.testing.expectEqual(move.position.whitepieces.Knight[0].representation, 'N');
            try std.testing.expectEqual(move.position.whitepieces.Knight[0].color, 0);
        }
    }

    try std.testing.expect(foundQueen);
    try std.testing.expect(foundRook);
    try std.testing.expect(foundBishop);
    try std.testing.expect(foundKnight);
}

test "ValidPawnMoves promotion with capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    board.position.blackpieces.Pawn[0].position = c.F8;
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);

    // Should have 4 regular promotions and 4 capture promotions
    try std.testing.expectEqual(moves.len, 8);

    var regularPromotions: u32 = 0;
    var capturePromotions: u32 = 0;

    for (moves) |move| {
        // Verify original pawn is removed
        try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);

        // Count regular promotions (to E8)
        if (move.position.whitepieces.Queen.position == c.E8 or
            move.position.whitepieces.Rook[0].position == c.E8 or
            move.position.whitepieces.Bishop[0].position == c.E8 or
            move.position.whitepieces.Knight[0].position == c.E8)
        {
            regularPromotions += 1;
        }

        // Count capture promotions (to F8)
        if (move.position.whitepieces.Queen.position == c.F8 or
            move.position.whitepieces.Rook[0].position == c.F8 or
            move.position.whitepieces.Bishop[0].position == c.F8 or
            move.position.whitepieces.Knight[0].position == c.F8)
        {
            capturePromotions += 1;
            // Verify captured pawn is removed
            try std.testing.expectEqual(move.position.blackpieces.Pawn[0].position, 0);
        }
    }

    try std.testing.expectEqual(regularPromotions, 4);
    try std.testing.expectEqual(capturePromotions, 4);
}

test "ValidPawnMoves invalid pawn positions" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // White pawn on first rank (invalid)
    board.position.whitepieces.Pawn[0].position = c.E1;
    var moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 0);

    // Black pawn on eighth rank (invalid)
    board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Pawn[0].position = c.E8;
    moves = ValidPawnMoves(board.position.blackpieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 0);
}

test "ValidPawnMoves two square move requires clear path" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E2;
    board.position.blackpieces.Pawn[0].position = c.E4; // Block the two-square move but not one-square
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 1); // Should only have the one-square move
}

test "ValidPawnMoves for h2 pawn in initial position" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[7], board);
    try std.testing.expectEqual(moves.len, 2); // Can move to h3 and h4

    var foundH3 = false;
    var foundH4 = false;
    for (moves) |move| {
        if (move.position.whitepieces.Pawn[7].position == c.H3) {
            foundH3 = true;
        }
        if (move.position.whitepieces.Pawn[7].position == c.H4) {
            foundH4 = true;
        }
    }

    try std.testing.expect(foundH3);
    try std.testing.expect(foundH4);
}

// Helper function to find next available piece index
fn findNextAvailableIndex(pieces: []const b.Piece) u8 {
    // Find first empty slot (position == 0)
    for (pieces, 0..) |piece, i| {
        if (piece.position == 0) {
            return @intCast(i);
        }
    }
    // If no empty slots found, return length (though this shouldn't happen in valid chess)
    return @intCast(pieces.len);
}

pub fn allvalidmoves(board: b.Board) []b.Board {
    // Check for checkmate first
    const s = @import("state.zig");
    if (s.isCheckmate(board, board.position.sidetomove == 0)) {
        return &[_]b.Board{};
    }

    var moves: [1024]b.Board = undefined;
    var movecount: usize = 0;

    // Copy board and set side to move for each generated move
    var boardCopy = board;

    if (board.position.sidetomove == 0) { // White pieces
        // King moves
        const kingMoves = getValidKingMoves(board.position.whitepieces.King, board);
        for (kingMoves) |move| {
            // Only allow moves that don't leave us in check
            if (!s.isCheck(move, true)) {
                boardCopy = move;
                moves[movecount] = boardCopy;
                movecount += 1;
            }
        }

        // Queen moves
        const queenMoves = getValidQueenMoves(board.position.whitepieces.Queen, board);
        for (queenMoves) |move| {
            if (!s.isCheck(move, true)) {
                boardCopy = move;
                moves[movecount] = boardCopy;
                movecount += 1;
            }
        }

        // Rook moves
        var rookMoveCount: usize = 0;
        for (board.position.whitepieces.Rook) |rook| {
            if (rook.position == 0) continue;
            const rookMoves = getValidRookMoves(rook, board);
            rookMoveCount += rookMoves.len;
            for (rookMoves) |move| {
                if (!s.isCheck(move, true)) {
                    boardCopy = move;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Bishop moves
        var bishopMoveCount: usize = 0;
        for (board.position.whitepieces.Bishop) |bishop| {
            if (bishop.position == 0) continue;
            const bishopMoves = getValidBishopMoves(bishop, board);
            bishopMoveCount += bishopMoves.len;
            for (bishopMoves) |move| {
                if (!s.isCheck(move, true)) {
                    boardCopy = move;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Knight moves
        var knightMoveCount: usize = 0;
        for (board.position.whitepieces.Knight) |knight| {
            if (knight.position == 0) continue;
            const knightMoves = getValidKnightMoves(knight, board);
            knightMoveCount += knightMoves.len;
            for (knightMoves) |move| {
                if (!s.isCheck(move, true)) {
                    boardCopy = move;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Pawn moves
        var pawnMoveCount: usize = 0;
        for (board.position.whitepieces.Pawn) |pawn| {
            if (pawn.position == 0) continue;
            const pawnMoves = getValidPawnMoves(pawn, board);
            pawnMoveCount += pawnMoves.len;
            for (pawnMoves) |move| {
                if (!s.isCheck(move, true)) {
                    boardCopy = move;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }
    } else { // Black pieces
        // King moves
        const kingMoves = getValidKingMoves(board.position.blackpieces.King, board);
        for (kingMoves) |move| {
            // Only allow moves that don't leave us in check
            if (!s.isCheck(move, false)) {
                boardCopy = move;
                moves[movecount] = boardCopy;
                movecount += 1;
            }
        }

        // Queen moves
        const queenMoves = getValidQueenMoves(board.position.blackpieces.Queen, board);
        for (queenMoves) |move| {
            if (!s.isCheck(move, false)) {
                boardCopy = move;
                moves[movecount] = boardCopy;
                movecount += 1;
            }
        }

        // Rook moves
        var rookMoveCount: usize = 0;
        for (board.position.blackpieces.Rook) |rook| {
            if (rook.position == 0) continue;
            const rookMoves = getValidRookMoves(rook, board);
            rookMoveCount += rookMoves.len;
            for (rookMoves) |move| {
                if (!s.isCheck(move, false)) {
                    boardCopy = move;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Bishop moves
        var bishopMoveCount: usize = 0;
        for (board.position.blackpieces.Bishop) |bishop| {
            if (bishop.position == 0) continue;
            const bishopMoves = getValidBishopMoves(bishop, board);
            bishopMoveCount += bishopMoves.len;
            for (bishopMoves) |move| {
                if (!s.isCheck(move, false)) {
                    boardCopy = move;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Knight moves
        var knightMoveCount: usize = 0;
        for (board.position.blackpieces.Knight) |knight| {
            if (knight.position == 0) continue;
            const knightMoves = getValidKnightMoves(knight, board);
            knightMoveCount += knightMoves.len;
            for (knightMoves) |move| {
                if (!s.isCheck(move, false)) {
                    boardCopy = move;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }

        // Pawn moves
        var pawnMoveCount: usize = 0;
        for (board.position.blackpieces.Pawn) |pawn| {
            if (pawn.position == 0) continue;
            const pawnMoves = getValidPawnMoves(pawn, board);
            pawnMoveCount += pawnMoves.len;
            for (pawnMoves) |move| {
                if (!s.isCheck(move, false)) {
                    boardCopy = move;
                    moves[movecount] = boardCopy;
                    movecount += 1;
                }
            }
        }
    }

    return moves[0..movecount];
}

test "parseUciMove basic move" {
    const move = try parseUciMove("e2e4");
    try std.testing.expectEqual(move.from, c.E2);
    try std.testing.expectEqual(move.to, c.E4);
    try std.testing.expectEqual(move.promotion_piece, null);
}

test "parseUciMove promotion move" {
    const move = try parseUciMove("e7e8q");
    try std.testing.expectEqual(move.from, c.E7);
    try std.testing.expectEqual(move.to, c.E8);
    try std.testing.expectEqual(move.promotion_piece.?, 'q');
}

test "parseUciMove invalid format" {
    try std.testing.expectError(error.InvalidMoveFormat, parseUciMove("e2"));
    try std.testing.expectError(error.InvalidMoveFormat, parseUciMove("e2e4e5"));
}

test "parseUciMove invalid squares" {
    try std.testing.expectError(error.InvalidSquare, parseUciMove("i2e4"));
    try std.testing.expectError(error.InvalidSquare, parseUciMove("e9e4"));
    try std.testing.expectError(error.InvalidSquare, parseUciMove("e2i4"));
    try std.testing.expectError(error.InvalidSquare, parseUciMove("e2e9"));
}

test "parseUciMove invalid promotion" {
    try std.testing.expectError(error.InvalidPromotionPiece, parseUciMove("e7e8k"));
}

test "Move toUciString basic move" {
    const move = Move{ .from = c.E2, .to = c.E4, .promotion_piece = null };
    const uci = try move.toUciString();
    try std.testing.expectEqualStrings(uci[0..4], "e2e4");
    try std.testing.expectEqual(uci[4], 0);
}

test "Move toUciString promotion move" {
    const move = Move{ .from = c.E7, .to = c.E8, .promotion_piece = 'q' };
    const uci = try move.toUciString();
    try std.testing.expectEqualStrings(uci[0..5], "e7e8q");
}

/// Apply a move to a board position and return the new board state
pub fn applyMove(board: b.Board, move: Move) !b.Board {
    // First find which piece is at the 'from' position
    const piece = piecefromlocation(move.from, board);
    if (piece.position == 0) return error.InvalidMove;

    // Get valid moves for just this piece
    const valid_moves = switch (piece.representation) {
        'P', 'p' => getValidPawnMoves(piece, board),
        'R', 'r' => getValidRookMoves(piece, board),
        'N', 'n' => getValidKnightMoves(piece, board),
        'B', 'b' => getValidBishopMoves(piece, board),
        'Q', 'q' => getValidQueenMoves(piece, board),
        'K', 'k' => getValidKingMoves(piece, board),
        else => return error.InvalidMove,
    };

    // Find the matching move in valid moves
    for (valid_moves) |valid_move| {
        // Find the piece that moved by comparing board states
        var found_piece_pos: u64 = 0;

        // Check white pieces
        inline for (std.meta.fields(@TypeOf(valid_move.position.whitepieces))) |field| {
            const old_piece = @field(board.position.whitepieces, field.name);
            const new_piece = @field(valid_move.position.whitepieces, field.name);

            if (@TypeOf(old_piece) == b.Piece) {
                if (old_piece.position == move.from) {
                    found_piece_pos = new_piece.position;
                }
            } else if (@TypeOf(old_piece) == [2]b.Piece or @TypeOf(old_piece) == [8]b.Piece) {
                for (old_piece, 0..) |p, i| {
                    if (p.position == move.from) {
                        found_piece_pos = new_piece[i].position;
                    }
                }
            }
        }

        // Check black pieces if we haven't found the move
        if (found_piece_pos == 0) {
            inline for (std.meta.fields(@TypeOf(valid_move.position.blackpieces))) |field| {
                const old_piece = @field(board.position.blackpieces, field.name);
                const new_piece = @field(valid_move.position.blackpieces, field.name);

                if (@TypeOf(old_piece) == b.Piece) {
                    if (old_piece.position == move.from) {
                        found_piece_pos = new_piece.position;
                    }
                } else if (@TypeOf(old_piece) == [2]b.Piece or @TypeOf(old_piece) == [8]b.Piece) {
                    for (old_piece, 0..) |p, i| {
                        if (p.position == move.from) {
                            found_piece_pos = new_piece[i].position;
                        }
                    }
                }
            }
        }

        // If this valid move matches our input move, return it
        var result = valid_move;
        if (found_piece_pos == move.to) {
            // Handle promotion if specified
            if (move.promotion_piece) |promotion| {
                // Find the pawn that was promoted and update its representation
                if (board.position.sidetomove == 0) {
                    // White pawn promotion
                    for (&result.position.whitepieces.Pawn) |*pawn| {
                        if (pawn.position == move.to) {
                            pawn.representation = std.ascii.toUpper(promotion);
                            break;
                        }
                    }
                } else {
                    // Black pawn promotion
                    for (&result.position.blackpieces.Pawn) |*pawn| {
                        if (pawn.position == move.to) {
                            pawn.representation = promotion;
                            break;
                        }
                    }
                }
                //  update side to move
                result.position.sidetomove = 1 - board.position.sidetomove;
                return result;
            }
            result.position.sidetomove = 1 - board.position.sidetomove;
            return result;
        }
    }

    return error.InvalidMove;
}

test "applyMove basic pawn move" {
    const board = b.Board{ .position = b.Position.init() };
    const move = Move{
        .from = c.E2,
        .to = c.E4,
        .promotion_piece = null,
    };

    const new_board = try applyMove(board, move);
    try std.testing.expectEqual(new_board.position.whitepieces.Pawn[4].position, c.E4);
}

test "applyMove pawn capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    // Set up a capture position
    board.position.whitepieces.Pawn[0].position = c.E4;
    board.position.blackpieces.Pawn[0].position = c.F5;

    const move = Move{
        .from = c.E4,
        .to = c.F5,
        .promotion_piece = null,
    };

    const new_board = try applyMove(board, move);
    try std.testing.expectEqual(new_board.position.whitepieces.Pawn[0].position, c.F5);
    try std.testing.expectEqual(new_board.position.blackpieces.Pawn[0].position, 0);
}
// todo: add test for pawn promotion

test "applyMove invalid move" {
    const board = b.Board{ .position = b.Position.init() };
    const move = Move{
        .from = c.E2,
        .to = c.E5, // Invalid - pawn can't move 3 squares
        .promotion_piece = null,
    };

    try std.testing.expectError(error.InvalidMove, applyMove(board, move));
}

test "applyMove castling" {
    var board = b.Board{ .position = b.Position.init() };
    // Clear pieces between king and rook
    board.position.whitepieces.Knight[1].position = 0;
    board.position.whitepieces.Bishop[1].position = 0;

    const move = Move{
        .from = c.E1,
        .to = c.G1,
        .promotion_piece = null,
    };

    const new_board = try applyMove(board, move);
    try std.testing.expectEqual(new_board.position.whitepieces.King.position, c.G1);
    try std.testing.expectEqual(new_board.position.whitepieces.Rook[1].position, c.F1);
}

test "ValidQueenMoves captures for black queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Queen.position = c.E4;

    // Place white pieces to capture
    board.position.whitepieces.Pawn[0].position = c.E6; // Vertical capture
    board.position.whitepieces.Pawn[1].position = c.G4; // Horizontal capture
    board.position.whitepieces.Pawn[2].position = c.G6; // Diagonal capture

    const moves = ValidQueenMoves(board.position.blackpieces.Queen, board);

    // Verify captures are possible
    var verticalCapture = false;
    var horizontalCapture = false;
    var diagonalCapture = false;

    for (moves) |move| {
        if (move.position.blackpieces.Queen.position == c.E6) {
            try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, 0);
            verticalCapture = true;
        }
        if (move.position.blackpieces.Queen.position == c.G4) {
            try std.testing.expectEqual(move.position.whitepieces.Pawn[1].position, 0);
            horizontalCapture = true;
        }
        if (move.position.blackpieces.Queen.position == c.G6) {
            try std.testing.expectEqual(move.position.whitepieces.Pawn[2].position, 0);
            diagonalCapture = true;
        }
    }

    try std.testing.expect(verticalCapture);
    try std.testing.expect(horizontalCapture);
    try std.testing.expect(diagonalCapture);
}

test "ValidQueenMoves blocked by own pieces for black queen" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Queen.position = c.E4;

    // Place friendly pieces to block
    board.position.blackpieces.Pawn[0].position = c.E5; // Block vertical
    board.position.blackpieces.Pawn[1].position = c.F4; // Block horizontal
    board.position.blackpieces.Pawn[2].position = c.F5; // Block diagonal

    const moves = ValidQueenMoves(board.position.blackpieces.Queen, board);

    // Verify blocked squares are not in valid moves
    for (moves) |move| {
        try std.testing.expect(move.position.blackpieces.Queen.position != c.E5);
        try std.testing.expect(move.position.blackpieces.Queen.position != c.F4);
        try std.testing.expect(move.position.blackpieces.Queen.position != c.F5);
    }
}

test "ValidQueenMoves captures in all directions" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.Queen.position = c.E4;

    // Place white pieces in all 8 directions
    board.position.whitepieces.Pawn[0].position = c.E5; // North
    board.position.whitepieces.Pawn[1].position = c.F5; // Northeast
    board.position.whitepieces.Pawn[2].position = c.F4; // East
    board.position.whitepieces.Pawn[3].position = c.F3; // Southeast
    board.position.whitepieces.Pawn[4].position = c.E3; // South
    board.position.whitepieces.Pawn[5].position = c.D3; // Southwest
    board.position.whitepieces.Pawn[6].position = c.D4; // West
    board.position.whitepieces.Pawn[7].position = c.D5; // Northwest

    const moves = ValidQueenMoves(board.position.blackpieces.Queen, board);

    // Should have exactly 8 capture moves
    var captureCount: usize = 0;
    for (moves) |move| {
        for (board.position.whitepieces.Pawn) |pawn| {
            if (move.position.blackpieces.Queen.position == pawn.position) {
                captureCount += 1;
            }
        }
    }

    try std.testing.expectEqual(captureCount, 8);
}

test "debug knight move sequence" {
    var board = b.Board{ .position = b.Position.init() };

    // Move sequence with verification
    const moves = [_]Move{
        Move{ .from = c.B1, .to = c.C3, .promotion_piece = null }, // white knight
        Move{ .from = c.C7, .to = c.C6, .promotion_piece = null }, // black pawn
        Move{ .from = c.C3, .to = c.D5, .promotion_piece = null }, // white knight
        Move{ .from = c.C6, .to = c.D5, .promotion_piece = null }, // black pawn captures
        Move{ .from = c.G1, .to = c.H3, .promotion_piece = null }, // white knight
        Move{ .from = c.F7, .to = c.F6, .promotion_piece = null }, // black pawn
        Move{ .from = c.H3, .to = c.G5, .promotion_piece = null }, // white knight
        Move{ .from = c.F6, .to = c.G5, .promotion_piece = null }, // black pawn captures
        Move{ .from = c.A2, .to = c.A3, .promotion_piece = null }, // white pawn
        Move{ .from = c.G8, .to = c.F6, .promotion_piece = null }, // black knight
    };

    std.debug.print("\nInitial position:\n", .{});
    _ = board.print();

    for (moves, 0..) |move, i| {
        board = try applyMove(board, move);
        std.debug.print("\nAfter move {d}:\n", .{i + 1});
        _ = board.print();
        std.debug.print("Side to move: {d}\n", .{board.position.sidetomove});
    }
}

test "ValidKingMoves for black king with castling" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.blackpieces.King.position = c.E8;
    board.position.blackpieces.Rook[1].position = c.H8;
    board.position.canCastleBlackKingside = true;

    const moves = ValidKingMoves(board.position.blackpieces.King, board);

    // Verify castling is included in the moves
    var castlingFound = false;
    for (moves) |move| {
        if (move.position.blackpieces.King.position == c.G8 and
            move.position.blackpieces.Rook[1].position == c.F8)
        {
            castlingFound = true;
            try std.testing.expectEqual(move.position.canCastleBlackKingside, false);
        }
    }
    try std.testing.expect(castlingFound);
}

test "allvalidmoves when in check only returns moves that get out of check" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Set up a check position: white king on e1, black queen on e8 (checking the king)
    board.position.whitepieces.King.position = c.E1;
    board.position.blackpieces.Queen.position = c.E8;

    // Add a white piece that can block the check
    board.position.whitepieces.Rook[0].position = c.D1;

    // Set white to move
    board.position.sidetomove = 0;

    // Get all valid moves
    const moves = allvalidmoves(board);

    // Verify that we have at least one valid move
    try std.testing.expect(moves.len > 0);

    // Verify that all returned moves get out of check
    const s = @import("state.zig");
    for (moves) |move| {
        try std.testing.expect(!s.isCheck(move, true));
    }

    // Verify that at least one move is the king moving or the rook blocking
    var foundValidMove = false;

    for (moves) |move| {
        if (move.position.whitepieces.King.position != c.E1 or
            move.position.whitepieces.Rook[0].position == c.E1)
        {
            foundValidMove = true;
            break;
        }
    }

    try std.testing.expect(foundValidMove);
}

test "allvalidmoves allows capturing the checking piece" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Set up a check position: white king on e4, black knight on f6 (checking the king)
    board.position.whitepieces.King.position = c.E4;
    board.position.blackpieces.Knight[0].position = c.F6;

    // Add a white piece that can capture the knight
    board.position.whitepieces.Bishop[0].position = c.G5;

    // Set white to move
    board.position.sidetomove = 0;

    // Get all valid moves
    const moves = allvalidmoves(board);

    // Verify that all returned moves get out of check
    const s = @import("state.zig");
    for (moves) |move| {
        try std.testing.expect(!s.isCheck(move, true));
    }

    // Verify that one of the moves is the bishop capturing the knight
    var foundCapture = false;
    for (moves) |move| {
        if (move.position.whitepieces.Bishop[0].position == c.F6 and
            move.position.blackpieces.Knight[0].position == 0)
        {
            foundCapture = true;
            break;
        }
    }

    try std.testing.expect(foundCapture);
}

test "ValidKnightMoves comprehensive edge cases" {
    var board = b.Board{ .position = b.Position.emptyboard() };

    // Test from all corners
    board.position.whitepieces.Knight[0].position = c.A1;
    var moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to b3 and c2

    board.position.whitepieces.Knight[0].position = c.H1;
    moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to f2 and g3

    board.position.whitepieces.Knight[0].position = c.A8;
    moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to b6 and c7

    board.position.whitepieces.Knight[0].position = c.H8;
    moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2); // Can only move to f7 and g6
}

test "ValidKnightMoves captures in all directions" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.E4;

    // Place black pieces in all possible knight-move positions
    const targetSquares = [_]u64{
        c.F6, c.G5, c.G3, c.F2, c.D2, c.C3, c.C5, c.D6
    };
    
    for (targetSquares, 0..) |square, i| {
        if (i < 8) {
            board.position.blackpieces.Pawn[i].position = square;
        }
    }

    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 8); // Should be able to capture in all directions

    // Verify each move results in a capture
    var captureCount: u32 = 0;
    for (moves) |move| {
        for (targetSquares) |target| {
            if (move.position.whitepieces.Knight[0].position == target) {
                captureCount += 1;
                // Verify the captured piece is removed
                var pieceFound = false;
                for (board.position.blackpieces.Pawn) |pawn| {
                    if (move.position.blackpieces.Pawn[pawn.index].position == target) {
                        pieceFound = true;
                        break;
                    }
                }
                try std.testing.expect(!pieceFound);
            }
        }
    }
    try std.testing.expectEqual(captureCount, 8);
}

test "ValidKnightMoves blocked by own pieces" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.E4;

    // Place white pieces in all possible knight-move positions
    board.position.whitepieces.Pawn[0].position = c.F6;
    board.position.whitepieces.Pawn[1].position = c.G5;
    board.position.whitepieces.Pawn[2].position = c.G3;
    board.position.whitepieces.Pawn[3].position = c.F2;
    board.position.whitepieces.Pawn[4].position = c.D2;
    board.position.whitepieces.Pawn[5].position = c.C3;
    board.position.whitepieces.Pawn[6].position = c.C5;
    board.position.whitepieces.Pawn[7].position = c.D6;

    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 0); // Should have no valid moves

    // Verify original positions are unchanged
    try std.testing.expectEqual(board.position.whitepieces.Knight[0].position, c.E4);
    for (board.position.whitepieces.Pawn) |pawn| {
        try std.testing.expect(pawn.position != 0);
    }
}

test "ValidKnightMoves multiple knights interaction" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    
    // Place two knights near each other
    board.position.whitepieces.Knight[0].position = c.E4;
    board.position.whitepieces.Knight[0].index = 0;
    board.position.whitepieces.Knight[1].position = c.F6;
    board.position.whitepieces.Knight[1].index = 1;

    // Get moves for first knight
    const moves1 = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    // Get moves for second knight
    const moves2 = ValidKnightMoves(board.position.whitepieces.Knight[1], board);

    // Verify moves don't include each other's squares
    for (moves1) |move| {
        try std.testing.expect(move.position.whitepieces.Knight[0].position != c.F6);
    }
    for (moves2) |move| {
        try std.testing.expect(move.position.whitepieces.Knight[1].position != c.E4);
    }

    // Verify the moved knight maintains its index
    for (moves1) |move| {
        try std.testing.expectEqual(move.position.whitepieces.Knight[0].index, 0);
    }
    for (moves2) |move| {
        try std.testing.expectEqual(move.position.whitepieces.Knight[1].index, 1);
    }
}

test "ValidKnightMoves preserves board state except for moved piece" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    
    // Setup a complex position
    board.position.whitepieces.Knight[0].position = c.E4;
    board.position.whitepieces.King.position = c.E1;
    board.position.blackpieces.King.position = c.E8;
    board.position.whitepieces.Pawn[0].position = c.E2;
    board.position.blackpieces.Pawn[0].position = c.F6;

    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);

    // For each move, verify only the knight and potentially captured piece changed
    for (moves) |move| {
        // Verify unchanged pieces maintain their positions
        try std.testing.expectEqual(move.position.whitepieces.King.position, c.E1);
        try std.testing.expectEqual(move.position.blackpieces.King.position, c.E8);
        try std.testing.expectEqual(move.position.whitepieces.Pawn[0].position, c.E2);
        
        // If knight moved to F6, verify black pawn was captured
        if (move.position.whitepieces.Knight[0].position == c.F6) {
            try std.testing.expectEqual(move.position.blackpieces.Pawn[0].position, 0);
        } else if (move.position.whitepieces.Knight[0].position != c.F6) {
            try std.testing.expectEqual(move.position.blackpieces.Pawn[0].position, c.F6);
        }
    }
}
