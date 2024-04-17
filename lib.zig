pub const A = @import("board.zig");
pub const B = @import("moves.zig");
test {
    @import("std").testing.refAllDecls(@This());
}
