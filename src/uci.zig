pub const UciCommand = @import("uci/command.zig").UciCommand;
pub const UciProtocol = @import("uci/protocol.zig").UciProtocol;
pub const moveToUci = @import("uci/helpers.zig").moveToUci;
pub const bitboardToSquare = @import("uci/helpers.zig").bitboardToSquare;

pub fn main() !void {
    var gpa = @import("std").heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var protocol = UciProtocol.init(allocator);
    defer protocol.deinit();
    try protocol.mainLoop();
}
