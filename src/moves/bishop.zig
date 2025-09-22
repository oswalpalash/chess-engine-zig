const std = @import("std");
const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");

fn placeBishop(board: *b.Board, piece: b.Piece) void {
    var updated = piece;
    const idx: usize = @intCast(piece.index);
    if (piece.color == 0) {
        if (piece.is_promoted) {
            board.position.whitepieces.Promoted.Bishop[idx] = updated;
        } else {
            board.position.whitepieces.Bishop[idx] = updated;
        }
    } else {
        if (piece.is_promoted) {
            board.position.blackpieces.Promoted.Bishop[idx] = updated;
        } else {
            board.position.blackpieces.Bishop[idx] = updated;
        }
    }
}

fn resolveBaseBishopIndex(piece: b.Piece, board: b.Board) usize {
    const collection = if (piece.color == 0)
        board.position.whitepieces.Bishop
    else
        board.position.blackpieces.Bishop;

    for (collection, 0..) |stored, idx| {
        if (stored.position == piece.position) {
            return idx;
        }
    }

    return 0;
}

pub fn getValidBishopMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;

    const next_side: u8 = if (board.position.sidetomove == 0) 1 else 0;

    const row = board_helpers.rowfrombitmap(piece.position);
    const col = board_helpers.colfrombitmap(piece.position);

    const resolved_index: usize = if (piece.is_promoted)
        @intCast(piece.index)
    else
        resolveBaseBishopIndex(piece, board);

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
            var moved = piece;
            moved.position = newpos;
            moved.index = @intCast(resolved_index);
            placeBishop(&newBoard, moved);
            newBoard.position.sidetomove = next_side;
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
                var moved = piece;
                moved.position = newpos;
                moved.index = @intCast(resolved_index);
                placeBishop(&newBoard, moved);
                newBoard.position.sidetomove = next_side;
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
            var moved = piece;
            moved.position = newpos;
            moved.index = @intCast(resolved_index);
            placeBishop(&newBoard, moved);
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                var moved = piece;
                moved.position = newpos;
                moved.index = @intCast(resolved_index);
                placeBishop(&newBoard, moved);
                newBoard.position.sidetomove = next_side;
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
            var moved = piece;
            moved.position = newpos;
            moved.index = @intCast(resolved_index);
            placeBishop(&newBoard, moved);
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                var moved = piece;
                moved.position = newpos;
                moved.index = @intCast(resolved_index);
                placeBishop(&newBoard, moved);
                newBoard.position.sidetomove = next_side;
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
            var moved = piece;
            moved.position = newpos;
            placeBishop(&newBoard, moved);
            newBoard.position.sidetomove = next_side;
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else {
            const targetPiece = board_helpers.piecefromlocation(newpos, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });
                var moved = piece;
                moved.position = newpos;
                placeBishop(&newBoard, moved);
                newBoard.position.sidetomove = next_side;
                moves[possiblemoves] = newBoard;
                possiblemoves += 1;
            }
            break;
        }
    }

    return moves[0..possiblemoves];
}
