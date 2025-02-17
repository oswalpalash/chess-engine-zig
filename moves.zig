const b = @import("board.zig");
const c = @import("consts.zig");
const std = @import("std");

// Import the reverse function from board.zig
const reverse = b.reverse;

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

    // determine which piece is being moved
    if (piece.color == 0) {
        for (board.position.whitepieces.Pawn, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                pawn = item;
                index = loopidx;
            }
        }
    } else {
        for (board.position.blackpieces.Pawn, 0..) |item, loopidx| {
            if (item.position == piece.position) {
                pawn = item;
                index = loopidx;
            }
        }
    }

    const currentRow = rowfrombitmap(piece.position);
    const currentCol = colfrombitmap(piece.position);

    // Single square forward move
    const oneSquareForward = piece.position << 8;
    if (bitmap & oneSquareForward == 0) {
        if (currentRow < 7) {
            // Regular move
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = oneSquareForward;
            } else {
                newBoard.position.blackpieces.Pawn[index].position = oneSquareForward;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else if (currentRow == 7) {
            // Promotion
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = oneSquareForward;
                newBoard.position.whitepieces.Pawn[index].representation = 'Q';
            } else {
                newBoard.position.blackpieces.Pawn[index].position = oneSquareForward;
                newBoard.position.blackpieces.Pawn[index].representation = 'q';
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }

        // Two square forward move from starting position
        if (currentRow == 2) {
            const twoSquareForward = piece.position << 16;
            if (bitmap & twoSquareForward == 0) {
                var newBoard = b.Board{ .position = board.position };
                if (piece.color == 0) {
                    newBoard.position.whitepieces.Pawn[index].position = twoSquareForward;
                    // Set en passant square
                    newBoard.position.enPassantSquare = oneSquareForward;
                } else {
                    newBoard.position.blackpieces.Pawn[index].position = twoSquareForward;
                    newBoard.position.enPassantSquare = oneSquareForward;
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        }
    }

    // Diagonal captures
    const leftCapture = if (currentCol > 1) piece.position << 7 else 0;
    const rightCapture = if (currentCol < 8) piece.position << 9 else 0;

    // Check left capture
    if (leftCapture != 0) {
        if (bitmap & leftCapture != 0) {
            const targetPiece = piecefromlocation(leftCapture, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0) 
                    captureblackpiece(leftCapture, b.Board{ .position = board.position })
                else 
                    capturewhitepiece(leftCapture, b.Board{ .position = board.position });

                if (currentRow == 7) {
                    // Promotion on capture
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = leftCapture;
                        newBoard.position.whitepieces.Pawn[index].representation = 'Q';
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = leftCapture;
                        newBoard.position.blackpieces.Pawn[index].representation = 'q';
                    }
                } else {
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = leftCapture;
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = leftCapture;
                    }
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        } else if (leftCapture == board.position.enPassantSquare) {
            // En passant capture to the left
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = leftCapture;
                // Capture the black pawn that just moved
                newBoard = captureblackpiece(leftCapture >> 8, newBoard);
            } else {
                newBoard.position.blackpieces.Pawn[index].position = leftCapture;
                newBoard = capturewhitepiece(leftCapture >> 8, newBoard);
            }
            newBoard.position.enPassantSquare = 0; // Clear en passant square
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    // Check right capture
    if (rightCapture != 0) {
        if (bitmap & rightCapture != 0) {
            const targetPiece = piecefromlocation(rightCapture, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    captureblackpiece(rightCapture, b.Board{ .position = board.position })
                else
                    capturewhitepiece(rightCapture, b.Board{ .position = board.position });

                if (currentRow == 7) {
                    // Promotion on capture
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = rightCapture;
                        newBoard.position.whitepieces.Pawn[index].representation = 'Q';
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = rightCapture;
                        newBoard.position.blackpieces.Pawn[index].representation = 'q';
                    }
                } else {
                    if (piece.color == 0) {
                        newBoard.position.whitepieces.Pawn[index].position = rightCapture;
                    } else {
                        newBoard.position.blackpieces.Pawn[index].position = rightCapture;
                    }
                }
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
        } else if (rightCapture == board.position.enPassantSquare) {
            // En passant capture to the right
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = rightCapture;
                // Capture the black pawn that just moved
                newBoard = captureblackpiece(rightCapture >> 8, newBoard);
            } else {
                newBoard.position.blackpieces.Pawn[index].position = rightCapture;
                newBoard = capturewhitepiece(rightCapture >> 8, newBoard);
            }
            newBoard.position.enPassantSquare = 0; // Clear en passant square
            moves[possiblemoves] = newBoard;
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
            _ = moves[possiblemoves].print();
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

// Valid knight moves
pub fn ValidKnightMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: u64 = 0;
    var knight: b.Piece = piece;
    var index: u64 = 0;

    // Find which knight we're moving
    for (board.position.whitepieces.Knight, 0..) |item, loopidx| {
        if (item.position == piece.position) {
            knight = item;
            index = loopidx;
            break;
        }
    }

    // All possible knight moves relative to current position
    const knightMoves = [8]struct { row: i8, col: i8 }{
        .{ .row = 2, .col = 1 }, // Up 2, right 1
        .{ .row = 2, .col = -1 }, // Up 2, left 1
        .{ .row = -2, .col = 1 }, // Down 2, right 1
        .{ .row = -2, .col = -1 }, // Down 2, left 1
        .{ .row = 1, .col = 2 }, // Up 1, right 2
        .{ .row = 1, .col = -2 }, // Up 1, left 2
        .{ .row = -1, .col = 2 }, // Down 1, right 2
        .{ .row = -1, .col = -2 }, // Down 1, left 2
    };

    const currentRow: i8 = @intCast(rowfrombitmap(knight.position));
    const currentCol: i8 = @intCast(colfrombitmap(knight.position));

    for (knightMoves) |move| {
        const newRow = currentRow + move.row;
        const newCol = currentCol + move.col;

        // Check if new position is within board boundaries
        if (newRow < 1 or newRow > 8 or newCol < 1 or newCol > 8) {
            continue;
        }

        // Calculate new position
        var newPos: u64 = knight.position;
        const rowDiff: i8 = newRow - currentRow;
        const colDiff: i8 = newCol - currentCol;

        if (rowDiff > 0) {
            newPos = newPos << @as(u6, @intCast(@as(u8, @intCast(rowDiff)) * 8));
        } else {
            newPos = newPos >> @as(u6, @intCast(@as(u8, @intCast(-rowDiff)) * 8));
        }

        if (colDiff > 0) {
            newPos = newPos >> @as(u6, @intCast(@as(u8, @intCast(colDiff))));
        } else {
            newPos = newPos << @as(u6, @intCast(@as(u8, @intCast(-colDiff))));
        }

        // Check if target square is empty or has enemy piece
        if (bitmap & newPos == 0) {
            // Empty square
            var newBoard = b.Board{ .position = board.position };
            newBoard.position.whitepieces.Knight[index].position = newPos;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            // Check if enemy piece
            const targetPiece = piecefromlocation(newPos, board);
            if (targetPiece.color != knight.color) {
                var newBoard = captureblackpiece(newPos, b.Board{ .position = board.position });
                newBoard.position.whitepieces.Knight[index].position = newPos;
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

    // Identify which white bishop in the array we're moving
    var bishop: b.Piece = piece;
    var index: u64 = 0;
    for (board.position.whitepieces.Bishop, 0..) |item, loopidx| {
        if (item.position == piece.position) {
            bishop = item;
            index = loopidx;
            break;
        }
    }

    const bishopshifts = [7]u6{ 1, 2, 3, 4, 5, 6, 7 };
    const row = rowfrombitmap(bishop.position);
    const col = colfrombitmap(bishop.position);

    // Up-Right diagonal moves
    for (bishopshifts) |shift| {
        if (row + shift > 8 or col + shift > 8) break;

        const newpos = bishop.position << (shift * 7);
        if (newpos == 0) break;

        // Check if target square is empty
        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            newBoard.position.whitepieces.Bishop[index].position = newpos;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            // Check if enemy piece (possible capture)
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != bishop.color) {
                var newBoard = captureblackpiece(newpos, b.Board{ .position = board.position });
                newBoard.position.whitepieces.Bishop[index].position = newpos;
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
            break; // Stop in this direction after capture or blocked
        }
    }

    // Up-Left diagonal moves
    for (bishopshifts) |shift| {
        if (row + shift > 8 or col <= shift) break;

        const newpos = bishop.position << (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            newBoard.position.whitepieces.Bishop[index].position = newpos;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != bishop.color) {
                var newBoard = captureblackpiece(newpos, b.Board{ .position = board.position });
                newBoard.position.whitepieces.Bishop[index].position = newpos;
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
            break;
        }
    }

    // Down-Right diagonal moves
    for (bishopshifts) |shift| {
        if (row <= shift or col + shift > 8) break;

        const newpos = bishop.position >> (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            newBoard.position.whitepieces.Bishop[index].position = newpos;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != bishop.color) {
                var newBoard = captureblackpiece(newpos, b.Board{ .position = board.position });
                newBoard.position.whitepieces.Bishop[index].position = newpos;
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
            break;
        }
    }

    // Down-Left diagonal moves
    for (bishopshifts) |shift| {
        if (row <= shift or col <= shift) break;

        const newpos = bishop.position >> (shift * 7);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            var newBoard = b.Board{ .position = board.position };
            newBoard.position.whitepieces.Bishop[index].position = newpos;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = piecefromlocation(newpos, board);
            if (targetPiece.color != bishop.color) {
                var newBoard = captureblackpiece(newpos, b.Board{ .position = board.position });
                newBoard.position.whitepieces.Bishop[index].position = newpos;
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
                    // TODO: Implement capturewhitepiece
                    moves[possiblemoves] = b.Board{ .position = board.position };
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
                    // TODO: Implement capturewhitepiece
                    moves[possiblemoves] = b.Board{ .position = board.position };
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
                    // TODO: Implement capturewhitepiece
                    moves[possiblemoves] = b.Board{ .position = board.position };
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
                    // TODO: Implement capturewhitepiece
                    moves[possiblemoves] = b.Board{ .position = board.position };
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
                    // TODO: Implement capturewhitepiece
                    moves[possiblemoves] = b.Board{ .position = board.position };
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
                    // TODO: Implement capturewhitepiece
                    moves[possiblemoves] = b.Board{ .position = board.position };
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
                    // TODO: Implement capturewhitepiece
                    moves[possiblemoves] = b.Board{ .position = board.position };
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
                    // TODO: Implement capturewhitepiece
                    moves[possiblemoves] = b.Board{ .position = board.position };
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
    if (piece.color == 0) {
        return ValidPawnMoves(piece, board);
    } else {
        var flippedBoard = board;
        flippedBoard.position = flippedBoard.position.flip();
        var flippedPiece = piece;
        flippedPiece.position = b.reverse(piece.position);

        // Save the original en-passant square and flip it
        const originalEnPassant = board.position.enPassantSquare;
        if (originalEnPassant != 0) {
            flippedBoard.position.enPassantSquare = b.reverse(originalEnPassant);
        }

        const moves = ValidPawnMoves(flippedPiece, flippedBoard);
        var flippedMoves: [256]b.Board = undefined;

        for (moves, 0..) |move, i| {
            flippedMoves[i] = move;
            flippedMoves[i].position = flippedMoves[i].position.flip();
            // Restore the original en-passant square if it wasn't cleared by the move
            if (flippedMoves[i].position.enPassantSquare != 0) {
                flippedMoves[i].position.enPassantSquare = originalEnPassant;
            }
        }

        return flippedMoves[0..moves.len];
    }
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
    if (piece.color == 0) {
        return ValidRookMoves(piece, board);
    } else {
        var flippedBoard = board;
        flippedBoard.position = flippedBoard.position.flip();
        var flippedPiece = piece;
        flippedPiece.position = b.reverse(piece.position);
        flippedPiece.color = 0; // Make it a white piece for ValidRookMoves

        // Find which rook it is and update it in the flipped board
        for (board.position.blackpieces.Rook, 0..) |item, i| {
            if (item.position == piece.position) {
                flippedBoard.position.whitepieces.Rook[i].position = flippedPiece.position;
                flippedBoard.position.whitepieces.Rook[i].color = 0;
                break;
            }
        }

        const moves = ValidRookMoves(flippedPiece, flippedBoard);
        var flippedMoves: [256]b.Board = undefined;

        for (moves, 0..) |move, i| {
            flippedMoves[i] = move;
            flippedMoves[i].position = flippedMoves[i].position.flip();
        }

        return flippedMoves[0..moves.len];
    }
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
    if (piece.color == 0) {
        return ValidKnightMoves(piece, board);
    } else {
        var flippedBoard = board;
        flippedBoard.position = flippedBoard.position.flip();
        var flippedPiece = piece;
        flippedPiece.position = b.reverse(piece.position);

        const moves = ValidKnightMoves(flippedPiece, flippedBoard);
        var flippedMoves: [256]b.Board = undefined;

        for (moves, 0..) |move, i| {
            flippedMoves[i] = move;
            flippedMoves[i].position = flippedMoves[i].position.flip();
        }

        return flippedMoves[0..moves.len];
    }
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
    if (piece.color == 0) {
        return ValidBishopMoves(piece, board);
    } else {
        var flippedBoard = board;
        flippedBoard.position = flippedBoard.position.flip();
        var flippedPiece = piece;
        flippedPiece.position = b.reverse(piece.position);

        const moves = ValidBishopMoves(flippedPiece, flippedBoard);
        var flippedMoves: [256]b.Board = undefined;

        for (moves, 0..) |move, i| {
            flippedMoves[i] = move;
            flippedMoves[i].position = flippedMoves[i].position.flip();
        }

        return flippedMoves[0..moves.len];
    }
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
    if (piece.color == 0) {
        return ValidQueenMoves(piece, board);
    } else {
        var flippedBoard = board;
        flippedBoard.position = flippedBoard.position.flip();
        var flippedPiece = piece;
        flippedPiece.position = b.reverse(piece.position);

        const moves = ValidQueenMoves(flippedPiece, flippedBoard);
        var flippedMoves: [256]b.Board = undefined;

        for (moves, 0..) |move, i| {
            flippedMoves[i] = move;
            flippedMoves[i].position = flippedMoves[i].position.flip();
        }

        return flippedMoves[0..moves.len];
    }
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
    if (piece.color == 0) {
        return ValidKingMoves(piece, board);
    } else {
        var flippedBoard = board;
        flippedBoard.position = flippedBoard.position.flip();
        var flippedPiece = piece;
        flippedPiece.position = b.reverse(piece.position);

        const moves = ValidKingMoves(flippedPiece, flippedBoard);
        var flippedMoves: [256]b.Board = undefined;

        for (moves, 0..) |move, i| {
            flippedMoves[i] = move;
            flippedMoves[i].position = flippedMoves[i].position.flip();
        }

        return flippedMoves[0..moves.len];
    }
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
    try std.testing.expectEqual(moves.len, 1);
    try std.testing.expectEqual(moves[0].position.whitepieces.Pawn[0].representation, 'Q');
}

test "ValidPawnMoves promotion on capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E7;
    board.position.blackpieces.Pawn[0].position = c.F8;
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 2); // One forward promotion, one capture promotion
    var foundCapture = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[0].position == 0) {
            foundCapture = true;
            try std.testing.expectEqual(move.position.whitepieces.Pawn[0].representation, 'Q');
        }
    }
    try std.testing.expect(foundCapture);
}

test "ValidPawnMoves en passant capture" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E5;
    board.position.blackpieces.Pawn[0].position = c.F5;
    board.position.enPassantSquare = c.F6; // Simulate black pawn just moved F7->F5
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 2); // Forward move and en passant capture
    var foundEnPassant = false;
    for (moves) |move| {
        if (move.position.blackpieces.Pawn[0].position == 0 and 
            move.position.whitepieces.Pawn[0].position == c.F6) {
            foundEnPassant = true;
            try std.testing.expectEqual(move.position.enPassantSquare, 0);
        }
    }
    try std.testing.expect(foundEnPassant);
}

test "ValidPawnMoves blocked by own piece" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E2;
    board.position.whitepieces.Pawn[1].position = c.E3;
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 0);
}

test "ValidPawnMoves two square move sets en passant square" {
    var board = b.Board{ .position = b.Position.emptyboard() };
    board.position.whitepieces.Pawn[0].position = c.E2;
    const moves = ValidPawnMoves(board.position.whitepieces.Pawn[0], board);
    try std.testing.expectEqual(moves.len, 2);
    var foundTwoSquare = false;
    for (moves) |move| {
        if (move.position.whitepieces.Pawn[0].position == c.E4) {
            foundTwoSquare = true;
            try std.testing.expectEqual(move.position.enPassantSquare, c.E3);
        }
    }
    try std.testing.expect(foundTwoSquare);
}
