const std = @import("std");

var initialized = false;
var enabled = false;

fn init() void {
    if (initialized) return;
    initialized = true;

    const value = std.process.getEnvVarOwned(std.heap.page_allocator, "CHESS_ENGINE_DEBUG") catch null;
    defer if (value) |v| std.heap.page_allocator.free(v);

    if (value) |v| {
        const trimmed = std.mem.trim(u8, v, " \t\n\r");
        if (trimmed.len == 0) return;

        if (std.ascii.eqlIgnoreCase(trimmed, "1") or
            std.ascii.eqlIgnoreCase(trimmed, "true") or
            std.ascii.eqlIgnoreCase(trimmed, "yes") or
            std.ascii.eqlIgnoreCase(trimmed, "on"))
        {
            enabled = true;
            return;
        }

        const parsed = std.fmt.parseInt(i64, trimmed, 10) catch null;
        if (parsed != null) {
            enabled = parsed.? != 0;
        }
    }
}

pub fn isEnabled() bool {
    if (!initialized) {
        init();
    }
    return enabled;
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    if (!isEnabled()) return;
    std.debug.print(fmt, args);
}
