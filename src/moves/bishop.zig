const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");

pub fn getValidBishopMoves(piece: b.Piece, board: b.Board) []b.Board {
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    if (piece.position == 0) return moves[0..possiblemoves];

    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var index: usize = 0;

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

    const row = board_helpers.rowfrombitmap(piece.position);
    const col = board_helpers.colfrombitmap(piece.position);

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
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
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
