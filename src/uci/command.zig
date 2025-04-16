const std = @import("std");

pub const UciCommand = enum {
    uci,
    debug,
    isready,
    setoption,
    register,
    ucinewgame,
    position,
    go,
    stop,
    ponderhit,
    quit,
    unknown,

    /// Parse a string into a UciCommand
    pub fn fromString(str: []const u8) UciCommand {
        const trimmed = std.mem.trim(u8, str, &std.ascii.whitespace);
        var iter = std.mem.splitScalar(u8, trimmed, ' ');
        const cmd = iter.next() orelse return .unknown;

        if (std.mem.eql(u8, cmd, "uci")) return .uci;
        if (std.mem.eql(u8, cmd, "debug")) return .debug;
        if (std.mem.eql(u8, cmd, "isready")) return .isready;
        if (std.mem.eql(u8, cmd, "setoption")) return .setoption;
        if (std.mem.eql(u8, cmd, "register")) return .register;
        if (std.mem.eql(u8, cmd, "ucinewgame")) return .ucinewgame;
        if (std.mem.eql(u8, cmd, "position")) return .position;
        if (std.mem.eql(u8, cmd, "go")) return .go;
        if (std.mem.eql(u8, cmd, "stop")) return .stop;
        if (std.mem.eql(u8, cmd, "ponderhit")) return .ponderhit;
        if (std.mem.eql(u8, cmd, "quit")) return .quit;

        return .unknown;
    }
};
