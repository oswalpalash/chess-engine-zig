const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");

pub fn getValidQueenMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    const queen_piece: b.Piece = piece;

    const shifts = [7]u6{ 1, 2, 3, 4, 5, 6, 7 };
    const row: u64 = board_helpers.rowfrombitmap(queen_piece.position);
    const col: u64 = board_helpers.colfrombitmap(queen_piece.position);
    var newqueen: b.Piece = queen_piece;
    var testpiece: b.Piece = undefined;

    // Rook-like moves
    // Forward moves
    for (shifts) |shift| {
        if (row + shift > 8) break;
        const newpos = queen_piece.position << (shift * 8);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
        const newpos = queen_piece.position >> (shift * 8);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
        const newpos = queen_piece.position << shift;
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
        const newpos = queen_piece.position >> shift;
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
        const newpos = queen_piece.position << (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
        const newpos = queen_piece.position << (shift * 7);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
        const newpos = queen_piece.position >> (shift * 7);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
        const newpos = queen_piece.position >> (shift * 9);
        if (newpos == 0) break;

        if (bitmap & newpos == 0) {
            // Empty square
            newqueen.position = newpos;
            moves[possiblemoves] = b.Board{ .position = board.position };
            if (queen_piece.color == 0) {
                moves[possiblemoves].position.whitepieces.Queen = newqueen;
            } else {
                moves[possiblemoves].position.blackpieces.Queen = newqueen;
            }
            possiblemoves += 1;
        } else {
            // Check for capture
            testpiece = board_helpers.piecefromlocation(newpos, board);
            if (testpiece.color != queen_piece.color) {
                newqueen.position = newpos;
                if (queen_piece.color == 0) {
                    moves[possiblemoves] = board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.whitepieces.Queen = newqueen;
                } else {
                    moves[possiblemoves] = board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                    moves[possiblemoves].position.blackpieces.Queen = newqueen;
                }
                possiblemoves += 1;
            }
            break;
        }
    }

    return moves[0..possiblemoves];
}
