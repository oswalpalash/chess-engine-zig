const b = @import("../board.zig");
const c = @import("../consts.zig");
const board_helpers = @import("../utils/board_helpers.zig");

pub fn getValidRookMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
    var moves: [256]b.Board = undefined;
    var possiblemoves: usize = 0;
    var index: usize = 0; // Initialize with a default value

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

    const row: u64 = board_helpers.rowfrombitmap(piece.position);
    const col: u64 = board_helpers.colfrombitmap(piece.position);

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
                const targetPiece = board_helpers.piecefromlocation(newpos, board);
                if (targetPiece.color != piece.color) {
                    var newBoard = if (piece.color == 0)
                        board_helpers.captureblackpiece(newpos, b.Board{ .position = board.position })
                    else
                        board_helpers.capturewhitepiece(newpos, b.Board{ .position = board.position });

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
