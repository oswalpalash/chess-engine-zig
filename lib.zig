pub const A = @import("board.zig");
pub const B = @import("moves.zig");
pub const C = @import("consts.zig");
test {
    @import("std").testing.refAllDecls(@This());
}
