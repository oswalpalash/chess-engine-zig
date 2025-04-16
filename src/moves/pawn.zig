const b = @import("../board.zig");
const c = @import("../consts.zig");
const std = @import("std");
const board_helpers = @import("../utils/board_helpers.zig");

// Returns an array of boards representing all possible moves for the given pawn
pub fn getValidPawnMoves(piece: b.Piece, board: b.Board) []b.Board {
    const bitmap: u64 = board_helpers.bitmapfromboard(board);
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

    const currentRow = board_helpers.rowfrombitmap(piece.position);
    const currentCol = board_helpers.colfrombitmap(piece.position);

    // Direction modifiers based on piece color
    const forwardShift: i8 = if (piece.color == 0) 8 else -8;

    // Starting row and promotion row based on color
    const startingRow: u64 = if (piece.color == 0) 2 else 7;

    // Single square forward move
    var oneSquareForward: u64 = 0;
    if (forwardShift > 0) {
        oneSquareForward = piece.position << @as(u6, @intCast(forwardShift));
    } else {
        oneSquareForward = piece.position >> @as(u6, @intCast(-forwardShift));
    }

    if (bitmap & oneSquareForward == 0) {
        if ((piece.color == 0 and currentRow < 7) or (piece.color == 1 and currentRow > 2)) {
            // Regular move
            var newBoard = b.Board{ .position = board.position };
            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = oneSquareForward;
            } else {
                newBoard.position.blackpieces.Pawn[index].position = oneSquareForward;
            }
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        } else if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
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
        if (currentRow == startingRow) {
            var twoSquareForward: u64 = 0;
            if (forwardShift > 0) {
                twoSquareForward = piece.position << @as(u6, @intCast(forwardShift * 2));
            } else {
                twoSquareForward = piece.position >> @as(u6, @intCast(-forwardShift * 2));
            }

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
            const targetPiece = board_helpers.piecefromlocation(leftCapture, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(leftCapture, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(leftCapture, b.Board{ .position = board.position });

                if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
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
            var capturedPawnPos: u64 = 0;

            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = leftCapture;
                // Capture the black pawn that just moved (one square behind the en passant square)
                capturedPawnPos = leftCapture >> 8;
                newBoard = board_helpers.captureblackpiece(capturedPawnPos, newBoard);
            } else {
                newBoard.position.blackpieces.Pawn[index].position = leftCapture;
                // Capture the white pawn that just moved (one square ahead of the en passant square)
                capturedPawnPos = leftCapture << 8;
                newBoard = board_helpers.capturewhitepiece(capturedPawnPos, newBoard);
            }
            newBoard.position.enPassantSquare = 0; // Clear en passant square
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    // Check right capture
    if (rightCapture != 0) {
        if (bitmap & rightCapture != 0) {
            const targetPiece = board_helpers.piecefromlocation(rightCapture, board);
            if (targetPiece.color != piece.color) {
                var newBoard = if (piece.color == 0)
                    board_helpers.captureblackpiece(rightCapture, b.Board{ .position = board.position })
                else
                    board_helpers.capturewhitepiece(rightCapture, b.Board{ .position = board.position });

                if ((piece.color == 0 and currentRow == 7) or (piece.color == 1 and currentRow == 2)) {
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
            var capturedPawnPos: u64 = 0;

            if (piece.color == 0) {
                newBoard.position.whitepieces.Pawn[index].position = rightCapture;
                // Capture the black pawn that just moved
                capturedPawnPos = rightCapture >> 8;
                newBoard = board_helpers.captureblackpiece(capturedPawnPos, newBoard);
            } else {
                newBoard.position.blackpieces.Pawn[index].position = rightCapture;
                // Capture the white pawn that just moved
                capturedPawnPos = rightCapture << 8;
                newBoard = board_helpers.capturewhitepiece(capturedPawnPos, newBoard);
            }
            newBoard.position.enPassantSquare = 0; // Clear en passant square
            moves[possiblemoves] = newBoard;
            possiblemoves += 1;
        }
    }

    return moves[0..possiblemoves];
}

// TODO: Move these dependencies/utilities to utils/ and import them here
extern fn bitmapfromboard(board: b.Board) u64;
extern fn piecefromlocation(location: u64, board: b.Board) b.Piece;
extern fn captureblackpiece(loc: u64, board: b.Board) b.Board;
extern fn capturewhitepiece(loc: u64, board: b.Board) b.Board;
extern fn rowfrombitmap(bitmap: u64) u64;
extern fn colfrombitmap(bitmap: u64) u64; 