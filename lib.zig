pub const A = @import("board.zig");
pub const B = @import("moves.zig");
pub const C = @import("consts.zig");
pub const D = @import("state.zig");
pub const E = @import("advanced_tests.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
