const b = @import("board.zig");
const c = @import("consts.zig");
const std = @import("std");

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

// valid pawn moves. only moves for white
// return board array with all possible moves
pub fn ValidPawnMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    var pawn: b.Piece = undefined;
    var index: u64 = 0;
    //@memset(&moves, 0);
    // determine which piece is being moved
    for (board.position.whitepieces.Pawn, 0..) |item, loopidx| {
        if (item.position == piece.position) {
            pawn = item;
            index = loopidx;
        }
    }
    // iterate through all possible moves
    // single move forward only if no piece is in front
    for (pawnShifts) |shift| switch (shift) {
        8 => {
            if (bitmap & (piece.position << 8) == 0) {
                pawn.position = piece.position << 8;
                // update board
                moves[possiblemoves] = b.Board{ .position = board.position };
                moves[possiblemoves].position.whitepieces.Pawn[index].position = pawn.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
            }
        },
        16 => {
            // only allowed on second row
            // not allowed if there is a piece in front
            if (bitmap & (piece.position << 16) == 0 and (piece.position & 0xFF00) != 0 and (bitmap & piece.position << 8) == 0) {
                pawn.position = piece.position << 16;
                // update board
                moves[possiblemoves] = b.Board{ .position = board.position };
                moves[possiblemoves].position.whitepieces.Pawn[index].position = pawn.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
            }
        },
        7 => {
            // remove captured piece from board
            if (bitmap & (piece.position << 7) != 0) {
                pawn.position = piece.position << 7;
                // update board
                moves[possiblemoves] = captureblackpiece(pawn.position, b.Board{ .position = board.position });
                moves[possiblemoves].position.whitepieces.Pawn[index].position = pawn.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
            }
        },
        9 => {
            if (bitmap & (piece.position << 9) != 0) {
                pawn.position = piece.position << 9;
                // update board
                moves[possiblemoves] = captureblackpiece(pawn.position, b.Board{ .position = board.position });
                moves[possiblemoves].position.whitepieces.Pawn[index].position = pawn.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
            }
        },
        else => {},
    };
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
    try std.testing.expectEqual(moves.len, 1);
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

test "row from bitmap of e2 pawn in init board" {
    const board = b.Board{ .position = b.Position.init() };
    const row = rowfrombitmap(board.position.whitepieces.Pawn[4].position);
    const row2 = rowfrombitmap(board.position.blackpieces.Pawn[3].position);
    try std.testing.expectEqual(row, 2);
    try std.testing.expectEqual(row2, 7);
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

test "col from bitmap of e2 pawn in init board" {
    const board = b.Board{ .position = b.Position.init() };
    const col = colfrombitmap(board.position.whitepieces.Pawn[3].position);
    const col2 = colfrombitmap(board.position.blackpieces.Rook[0].position);
    const col3 = colfrombitmap(board.position.whitepieces.King.position);
    try std.testing.expectEqual(col, 4);
    try std.testing.expectEqual(col2, 8);
    try std.testing.expectEqual(col3, 5);
}

// Valid rook moves
pub fn ValidRookMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    var rook: b.Piece = undefined;
    var index: u64 = 0;
    //@memset(&moves, 0);
    // determine which piece is being moved
    for (board.position.whitepieces.Rook, 0..) |item, loopidx| {
        if (item.position == piece.position) {
            rook = item;
            index = loopidx;
        }
    }
    const rookshifts = [7]u6{ 1, 2, 3, 4, 5, 6, 7 };
    const row: u64 = rowfrombitmap(rook.position);
    const col: u64 = colfrombitmap(rook.position);
    var newrook: b.Piece = rook;
    var testpiece: b.Piece = undefined;
    // iterate through all possible forward moves
    // max forward moves is 8-row
    for (rookshifts) |shift| {
        if (row + shift == 9) {
            break;
        }
        // move one row at a time i.e "00" at the end. use newrook
        // account for captures
        // only allow moves if there is no piece in the way
        // if there is a piece in the way, capture it and stop
        // reset newrook to original position after each move to check for other moves
        // only allow captures if the piece is of different colour
        if (bitmap & (newrook.position << (shift * 8)) == 0) {
            testpiece = piecefromlocation(newrook.position << (shift * 8), board);
            if (testpiece.representation != '.') {
                if (testpiece.color == 0) {
                    break;
                }
            }
            newrook.position = newrook.position << (shift * 8);
            // update board
            moves[possiblemoves] = b.Board{ .position = board.position };
            moves[possiblemoves].position.whitepieces.Rook[index].position = newrook.position;
            _ = moves[possiblemoves].print();
            possiblemoves += 1;
        } else {
            if (bitmap & (newrook.position << (shift * 8)) != 0) {
                testpiece = piecefromlocation(newrook.position << (shift * 8), board);
                if (testpiece.representation != '.') {
                    if (testpiece.color == 0) {
                        break;
                    }
                }
                newrook.position = newrook.position << (shift * 8);
                // update board
                moves[possiblemoves] = captureblackpiece(newrook.position, b.Board{ .position = board.position });
                moves[possiblemoves].position.whitepieces.Rook[index].position = newrook.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
                newrook.position = rook.position;
                break;
            }
        }
        newrook.position = rook.position;
    }
    // iterate through all possible backward moves
    for (rookshifts) |shift| {
        if (row - shift == 0) {
            break;
        }
        if (bitmap & (newrook.position >> (shift * 8)) == 0) {
            testpiece = piecefromlocation(newrook.position >> (shift * 8), board);
            if (testpiece.representation != '.') {
                if (testpiece.color == 0) {
                    break;
                }
            }
            newrook.position = newrook.position >> (shift * 8);
            // update board
            moves[possiblemoves] = b.Board{ .position = board.position };
            moves[possiblemoves].position.whitepieces.Rook[index].position = newrook.position;
            _ = moves[possiblemoves].print();
            possiblemoves += 1;
        } else {
            if (bitmap & (newrook.position >> (shift * 8)) != 0) {
                testpiece = piecefromlocation(newrook.position >> (shift * 8), board);
                if (testpiece.representation != '.') {
                    if (testpiece.color == 0) {
                        break;
                    }
                }
                newrook.position = newrook.position >> (shift * 8);
                // update board
                moves[possiblemoves] = captureblackpiece(newrook.position, b.Board{ .position = board.position });
                moves[possiblemoves].position.whitepieces.Rook[index].position = newrook.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
                newrook.position = rook.position;
                break;
            }
        }
        newrook.position = rook.position;
    }
    // iterate through all possible left moves
    for (rookshifts) |shift| {
        if (col - shift == 0) {
            break;
        }
        if (bitmap & (newrook.position << shift) == 0) {
            testpiece = piecefromlocation(newrook.position << shift, board);
            if (testpiece.representation != '.') {
                if (testpiece.color == 0) {
                    break;
                }
            }
            newrook.position = newrook.position << shift;
            // update board
            moves[possiblemoves] = b.Board{ .position = board.position };
            moves[possiblemoves].position.whitepieces.Rook[index].position = newrook.position;
            _ = moves[possiblemoves].print();
            possiblemoves += 1;
        } else {
            if (bitmap & (newrook.position << shift) != 0) {
                testpiece = piecefromlocation(newrook.position << shift, board);
                if (testpiece.representation != '.') {
                    if (testpiece.color == 0) {
                        break;
                    }
                }
                newrook.position = newrook.position << shift;
                // update board
                moves[possiblemoves] = captureblackpiece(newrook.position, b.Board{ .position = board.position });
                moves[possiblemoves].position.whitepieces.Rook[index].position = newrook.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
                newrook.position = rook.position;
                break;
            }
        }
        newrook.position = rook.position;
    }
    // iterate through all possible right moves
    for (rookshifts) |shift| {
        if (col + shift == 9) {
            break;
        }
        if (bitmap & (newrook.position >> shift) == 0) {
            testpiece = piecefromlocation(newrook.position >> shift, board);
            if (testpiece.representation != '.') {
                if (testpiece.color == 0) {
                    break;
                }
            }
            newrook.position = newrook.position >> shift;
            // update board
            moves[possiblemoves] = b.Board{ .position = board.position };
            moves[possiblemoves].position.whitepieces.Rook[index].position = newrook.position;
            _ = moves[possiblemoves].print();
            possiblemoves += 1;
        } else {
            if (bitmap & (newrook.position >> shift) != 0) {
                testpiece = piecefromlocation(newrook.position >> shift, board);
                if (testpiece.representation != '.') {
                    if (testpiece.color == 0) {
                        break;
                    }
                }
                newrook.position = newrook.position >> shift;
                // update board
                moves[possiblemoves] = captureblackpiece(newrook.position, b.Board{ .position = board.position });
                moves[possiblemoves].position.whitepieces.Rook[index].position = newrook.position;
                _ = moves[possiblemoves].print();
                possiblemoves += 1;
                newrook.position = rook.position;
                break;
            }
        }
        newrook.position = rook.position;
    }
    return moves[0..possiblemoves];
}

// test "ValidRookMoves for empty board with rook on e1"
test "ValidRookMoves for empty board with rook on e1" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.E1;
    _ = board.print();
    // verify rook is on e1 by checking row and col
    const row = rowfrombitmap(board.position.whitepieces.Rook[0].position);
    const col = colfrombitmap(board.position.whitepieces.Rook[0].position);
    try std.testing.expectEqual(row, 1);
    try std.testing.expectEqual(col, 5);

    const moves = ValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14);
}

test "ValidRookMoves for empty board with rook on a1 and black piece on a8" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Rook[0].position = c.A1;
    board.position.blackpieces.Rook[0].position = c.A8;
    const moves = ValidRookMoves(board.position.whitepieces.Rook[0], board);
    try std.testing.expectEqual(moves.len, 14);
    try std.testing.expectEqual(moves[6].position.blackpieces.Rook[0].position, 0);
}

test "ValidRookMoves has 0 moves for a1 rook in init board" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidRookMoves(board.position.whitepieces.Rook[1], board);
    try std.testing.expectEqual(moves.len, 0);
}

test "ValidRookMoves has 6 moves for a1 rook in init board with missing a2 pawn" {
    var board = b.Board{ .position = b.Position.init() };
    board.position.whitepieces.Pawn[7].position = 0;
    const moves = ValidRookMoves(board.position.whitepieces.Rook[1], board);
    try std.testing.expectEqual(moves.len, 6);
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
            break;
        }
        // if there is no piece, allow shifting
        // if there is a piece, check if it is of different colour, if so, capture it
        // if it is of same colour, don't allow shifting
        if (bitmap & (piece.position << shift) == 0) {
            dummypiece = piecefromlocation(piece.position << shift, board);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == piece.color) {
                    break;
                }
            }
            king.position = piece.position << shift;
            // update board
            moves[possiblemoves] = b.Board{ .position = board.position };
            moves[possiblemoves].position.whitepieces.King.position = king.position;
            _ = moves[possiblemoves].print();
            possiblemoves += 1;
        } else {
            if (bitmap & (piece.position << shift) != 0) {
                dummypiece = piecefromlocation(piece.position << shift, board);
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != piece.color) {
                        king.position = piece.position << shift;
                        // update board
                        moves[possiblemoves] = captureblackpiece(king.position, b.Board{ .position = board.position });
                        moves[possiblemoves].position.whitepieces.King.position = king.position;
                        _ = moves[possiblemoves].print();
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
            break;
        }
        if (bitmap & (king.position >> shift) == 0) {
            dummypiece = piecefromlocation(piece.position >> shift, board);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == piece.color) {
                    break;
                }
            }
            king.position = piece.position >> shift;
            // update board
            moves[possiblemoves] = b.Board{ .position = board.position };
            moves[possiblemoves].position.whitepieces.King.position = king.position;
            _ = moves[possiblemoves].print();
            possiblemoves += 1;
        } else {
            if (bitmap & (piece.position >> shift) != 0) {
                dummypiece = piecefromlocation(piece.position >> shift, board);
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != piece.color) {
                        king.position = piece.position >> shift;
                        // update board
                        moves[possiblemoves] = captureblackpiece(king.position, b.Board{ .position = board.position });
                        moves[possiblemoves].position.whitepieces.King.position = king.position;
                        _ = moves[possiblemoves].print();
                        possiblemoves += 1;
                    }
                }
            }
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

// Valid knight moves
pub fn ValidKnightMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    var knight: b.Piece = piece;
    var dummypiece: b.Piece = undefined;
    const knightshifts = [4]u6{ 6, 10, 15, 17 };
    const originalcolindex: u64 = colfrombitmap(knight.position);
    var newcolindex: u64 = undefined;
    // forward moves
    for (knightshifts) |shift| {
        if (knight.position << shift == 0) {
            break;
        }
        // if there is no piece, allow shifting
        // if there is a piece, check if it is of different colour, if so, capture it
        // if it is of same colour, don't allow shifting
        if (bitmap & (knight.position << shift) == 0) {
            dummypiece = piecefromlocation(knight.position << shift, board);
            newcolindex = colfrombitmap(knight.position << shift);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == knight.color) {
                    break;
                }
            }
            if (newcolindex > originalcolindex) {
                if (newcolindex - originalcolindex > 2) {
                    // skip this move
                    continue;
                }
            } else {
                if (originalcolindex - newcolindex > 2) {
                    continue;
                }
            }

            dummypiece.position = knight.position << shift;
            // update board
            moves[possiblemoves] = b.Board{ .position = board.position };
            moves[possiblemoves].position.whitepieces.Knight[0].position = dummypiece.position;
            _ = moves[possiblemoves].print();
            possiblemoves += 1;
        } else {
            if (bitmap & (knight.position << shift) != 0) {
                dummypiece = piecefromlocation(knight.position << shift, board);
                newcolindex = colfrombitmap(knight.position << shift);
                if (newcolindex > originalcolindex) {
                    if (newcolindex - originalcolindex > 2) {
                        // skip this move
                        continue;
                    }
                } else {
                    if (originalcolindex - newcolindex > 2) {
                        continue;
                    }
                }
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != knight.color) {
                        dummypiece.position = knight.position << shift;
                        // update board
                        moves[possiblemoves] = captureblackpiece(dummypiece.position, b.Board{ .position = board.position });
                        moves[possiblemoves].position.whitepieces.Knight[0].position = dummypiece.position;
                        _ = moves[possiblemoves].print();
                        possiblemoves += 1;
                    }
                }
            }
        }
    }
    knight = piece;
    // reverse moves
    for (knightshifts) |shift| {
        if (knight.position >> shift == 0) {
            break;
        }
        if (bitmap & (knight.position >> shift) == 0) {
            dummypiece = piecefromlocation(knight.position >> shift, board);
            newcolindex = colfrombitmap(knight.position >> shift);
            if (dummypiece.representation != '.') {
                if (dummypiece.color == knight.color) {
                    break;
                }
            }
            if (newcolindex > originalcolindex) {
                if (newcolindex - originalcolindex > 2) {
                    continue;
                }
            } else {
                if (originalcolindex - newcolindex > 2) {
                    continue;
                }
            }
            dummypiece.position = knight.position >> shift;
            // update board
            moves[possiblemoves] = b.Board{ .position = board.position };
            moves[possiblemoves].position.whitepieces.Knight[0].position = dummypiece.position;
            _ = moves[possiblemoves].print();
            possiblemoves += 1;
        } else {
            if (bitmap & (knight.position >> shift) != 0) {
                dummypiece = piecefromlocation(knight.position >> shift, board);
                newcolindex = colfrombitmap(knight.position >> shift);
                if (newcolindex > originalcolindex) {
                    if (newcolindex - originalcolindex > 2) {
                        continue;
                    }
                } else {
                    if (originalcolindex - newcolindex > 2) {
                        continue;
                    }
                }

                if (newcolindex - originalcolindex >= 2 or newcolindex - originalcolindex <= -2) {
                    break;
                }
                if (dummypiece.representation != '.') {
                    if (dummypiece.color != knight.color) {
                        dummypiece.position = knight.position >> shift;
                        // update board
                        moves[possiblemoves] = captureblackpiece(knight.position, b.Board{ .position = board.position });
                        moves[possiblemoves].position.whitepieces.Knight[0].position = dummypiece.position;
                        _ = moves[possiblemoves].print();
                        possiblemoves += 1;
                    }
                }
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
    try std.testing.expectEqual(moves.len, 8);
}

test "ValidKnightMoves for init board with knight on b1" {
    const board = b.Board{ .position = b.Position.init() };
    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 2);
    try std.testing.expectEqual(moves[0].position.whitepieces.Knight[0].position, c.C3);
    try std.testing.expectEqual(moves[1].position.whitepieces.Knight[0].position, c.A3);
}

test "ValidKnightMoves for empty board with knight on b1 and black piece on c3" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Knight[0].position = c.B1;
    board.position.blackpieces.Pawn[2].position = c.C3;
    const moves = ValidKnightMoves(board.position.whitepieces.Knight[0], board);
    try std.testing.expectEqual(moves.len, 3);
    try std.testing.expectEqual(moves[1].position.blackpieces.Pawn[2].position, 0);
}
