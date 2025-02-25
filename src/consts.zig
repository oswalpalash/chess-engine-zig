pub const A1 = 0x80;
pub const A2 = 0x8000;
pub const A3 = 0x800000;
pub const A4 = 0x80000000;
pub const A5 = 0x8000000000;
pub const A6 = 0x800000000000;
pub const A7 = 0x80000000000000;
pub const A8 = 0x8000000000000000;
pub const B1 = 0x40;
pub const B2 = 0x4000;
pub const B3 = 0x400000;
pub const B4 = 0x40000000;
pub const B5 = 0x4000000000;
pub const B6 = 0x400000000000;
pub const B7 = 0x40000000000000;
pub const B8 = 0x4000000000000000;
pub const C1 = 0x20;
pub const C2 = 0x2000;
pub const C3 = 0x200000;
pub const C4 = 0x20000000;
pub const C5 = 0x2000000000;
pub const C6 = 0x200000000000;
pub const C7 = 0x20000000000000;
pub const C8 = 0x2000000000000000;
pub const D1 = 0x10;
pub const D2 = 0x1000;
pub const D3 = 0x100000;
pub const D4 = 0x10000000;
pub const D5 = 0x1000000000;
pub const D6 = 0x100000000000;
pub const D7 = 0x10000000000000;
pub const D8 = 0x1000000000000000;
pub const E1 = 0x8;
pub const E2 = 0x800;
pub const E3 = 0x80000;
pub const E4 = 0x8000000;
pub const E5 = 0x800000000;
pub const E6 = 0x80000000000;
pub const E7 = 0x8000000000000;
pub const E8 = 0x800000000000000;
pub const F1 = 0x4;
pub const F2 = 0x400;
pub const F3 = 0x40000;
pub const F4 = 0x4000000;
pub const F5 = 0x400000000;
pub const F6 = 0x40000000000;
pub const F7 = 0x4000000000000;
pub const F8 = 0x400000000000000;
pub const G1 = 0x2;
pub const G2 = 0x200;
pub const G3 = 0x20000;
pub const G4 = 0x2000000;
pub const G5 = 0x200000000;
pub const G6 = 0x20000000000;
pub const G7 = 0x2000000000000;
pub const G8 = 0x200000000000000;
pub const H1 = 0x1;
pub const H2 = 0x100;
pub const H3 = 0x10000;
pub const H4 = 0x1000000;
pub const H5 = 0x100000000;
pub const H6 = 0x10000000000;
pub const H7 = 0x1000000000000;
pub const H8 = 0x100000000000000;

// Piece position tables
pub const PAWN_POSITION_TABLE = [64]i32{ 0, 0, 0, 0, 0, 0, 0, 0, 50, 50, 50, 50, 50, 50, 50, 50, 10, 10, 20, 30, 30, 20, 10, 10, 5, 5, 10, 25, 25, 10, 5, 5, 0, 0, 0, 20, 20, 0, 0, 0, 5, -5, -10, 0, 0, -10, -5, 5, 5, 10, 10, -20, -20, 10, 10, 5, 0, 0, 0, 0, 0, 0, 0, 0 };

pub const KNIGHT_POSITION_TABLE = [64]i32{ -50, -40, -30, -30, -30, -30, -40, -50, -40, -20, 0, 0, 0, 0, -20, -40, -30, 0, 10, 15, 15, 10, 0, -30, -30, 5, 15, 20, 20, 15, 5, -30, -30, 0, 15, 20, 20, 15, 0, -30, -30, 5, 10, 15, 15, 10, 5, -30, -40, -20, 0, 5, 5, 0, -20, -40, -50, -40, -30, -30, -30, -30, -40, -50 };

// New piece-square tables for other pieces
pub const BISHOP_POSITION_TABLE = [64]i32{ -20, -10, -10, -10, -10, -10, -10, -20, -10, 0, 0, 0, 0, 0, 0, -10, -10, 0, 10, 10, 10, 10, 0, -10, -10, 5, 5, 10, 10, 5, 5, -10, -10, 0, 5, 10, 10, 5, 0, -10, -10, 5, 5, 5, 5, 5, 5, -10, -10, 0, 5, 0, 0, 5, 0, -10, -20, -10, -10, -10, -10, -10, -10, -20 };

pub const ROOK_POSITION_TABLE = [64]i32{ 0, 0, 0, 0, 0, 0, 0, 0, 5, 10, 10, 10, 10, 10, 10, 5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 5, 5, 0, 0, 0 };

pub const QUEEN_POSITION_TABLE = [64]i32{ -20, -10, -10, -5, -5, -10, -10, -20, -10, 0, 0, 0, 0, 0, 0, -10, -10, 0, 5, 5, 5, 5, 0, -10, -5, 0, 5, 5, 5, 5, 0, -5, 0, 0, 5, 5, 5, 5, 0, -5, -10, 5, 5, 5, 5, 5, 0, -10, -10, 0, 5, 0, 0, 0, 0, -10, -20, -10, -10, -5, -5, -10, -10, -20 };

// King position tables - one for middlegame and one for endgame
pub const KING_MIDDLEGAME_TABLE = [64]i32{ -30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30, -20, -30, -30, -40, -40, -30, -30, -20, -10, -20, -20, -20, -20, -20, -20, -10, 20, 20, 0, 0, 0, 0, 20, 20, 20, 30, 10, 0, 0, 10, 30, 20 };

pub const KING_ENDGAME_TABLE = [64]i32{ -50, -40, -30, -20, -20, -30, -40, -50, -30, -20, -10, 0, 0, -10, -20, -30, -30, -10, 20, 30, 30, 20, -10, -30, -30, -10, 30, 40, 40, 30, -10, -30, -30, -10, 30, 40, 40, 30, -10, -30, -30, -10, 20, 30, 30, 20, -10, -30, -30, -30, 0, 0, 0, 0, -30, -30, -50, -30, -30, -30, -30, -30, -30, -50 };

// Central squares for control evaluation
pub const CENTER_SQUARES = D4 | E4 | D5 | E5;
pub const EXTENDED_CENTER = C3 | D3 | E3 | F3 | C4 | D4 | E4 | F4 | C5 | D5 | E5 | F5 | C6 | D6 | E6 | F6;

// Constants for evaluation
pub const DOUBLED_PAWN_PENALTY = -10;
pub const ISOLATED_PAWN_PENALTY = -20;
pub const PASSED_PAWN_BONUS = 20;
pub const BISHOP_PAIR_BONUS = 50;
pub const KNIGHT_OUTPOST_BONUS = 15;
pub const ROOK_ON_OPEN_FILE_BONUS = 15;
pub const ROOK_ON_SEMI_OPEN_FILE_BONUS = 10;
pub const QUEEN_ON_OPEN_FILE_BONUS = 5;
pub const MOBILITY_FACTOR = 2;
pub const CENTER_CONTROL_BONUS = 5;
pub const KING_PAWN_SHIELD_BONUS = 10;
pub const KING_SAFETY_ATTACK_ZONE = 3;
pub const ENDGAME_MATERIAL_THRESHOLD = 3000; // Total material value below which we consider it an endgame
