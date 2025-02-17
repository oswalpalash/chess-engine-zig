const std = @import("std");

/// Engine identification constants
pub const ENGINE_NAME = "ZigChess";
pub const ENGINE_AUTHOR = "Palash";

/// Represents a UCI command
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
        // Trim whitespace from the input string
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

/// Main UCI protocol handler
pub const UciProtocol = struct {
    allocator: std.mem.Allocator,
    debug_mode: bool = false,
    test_writer: ?std.ArrayList(u8).Writer = null, // Use ArrayList writer for testing

    pub fn init(allocator: std.mem.Allocator) UciProtocol {
        return UciProtocol{
            .allocator = allocator,
            .test_writer = null,
        };
    }

    /// Process a single UCI command
    pub fn processCommand(self: *UciProtocol, line: []const u8) !void {
        const cmd = UciCommand.fromString(line);

        // Log the received command if in debug mode
        if (self.debug_mode) {
            std.debug.print("Received command: {s} (parsed as {any})\n", .{ line, cmd });
        }

        switch (cmd) {
            .uci => {
                // Send engine identification
                try self.respond("id name " ++ ENGINE_NAME);
                try self.respond("id author " ++ ENGINE_AUTHOR);
                // TODO: Send options here when we add them
                try self.respond("uciok");
            },
            .isready => {
                try self.respond("readyok");
            },
            .setoption => {
                // Parse the setoption command format: setoption name <id> [value <x>]
                var iter = std.mem.splitScalar(u8, line, ' ');
                _ = iter.next(); // Skip "setoption"
                const name_token = iter.next();
                if (name_token != null and std.mem.eql(u8, name_token.?, "name")) {
                    if (self.debug_mode) {
                        std.debug.print("Received setoption command. Will be implemented in future.\n", .{});
                    }
                }
            },
            .ucinewgame => {
                if (self.debug_mode) {
                    std.debug.print("Received ucinewgame command. Will be implemented in future.\n", .{});
                }
                // TODO: Reset game state and clear any persistent data
            },
            else => {
                // For now, just echo other commands back
                try self.respond(line);
            },
        }
    }

    /// Main loop to process UCI commands
    pub fn mainLoop(self: *UciProtocol) !void {
        const stdin = std.io.getStdIn().reader();
        var buf: [1024]u8 = undefined;

        while (true) {
            if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
                // Process the command
                try self.processCommand(line);

                // Check for quit command
                if (UciCommand.fromString(line) == .quit) {
                    break;
                }
            } else {
                break; // EOF reached
            }
        }
    }

    /// Send a response back to the UCI interface
    fn respond(self: *UciProtocol, msg: []const u8) !void {
        if (self.test_writer) |w| {
            try w.print("{s}\n", .{msg});
        } else {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("{s}\n", .{msg});
        }
    }
};

test "UciCommand parsing" {
    try std.testing.expectEqual(UciCommand.fromString("uci"), .uci);
    try std.testing.expectEqual(UciCommand.fromString("debug"), .debug);
    try std.testing.expectEqual(UciCommand.fromString("isready"), .isready);
    try std.testing.expectEqual(UciCommand.fromString("quit"), .quit);
    try std.testing.expectEqual(UciCommand.fromString("invalid"), .unknown);
}

test "UciCommand parsing with arguments" {
    try std.testing.expectEqual(UciCommand.fromString("position startpos"), .position);
    try std.testing.expectEqual(UciCommand.fromString("go depth 6"), .go);
    try std.testing.expectEqual(UciCommand.fromString("setoption name Hash value 128"), .setoption);
}

test "UciCommand parsing with whitespace" {
    try std.testing.expectEqual(UciCommand.fromString("  uci  "), .uci);
    try std.testing.expectEqual(UciCommand.fromString("quit  "), .quit);
    try std.testing.expectEqual(UciCommand.fromString(" isready"), .isready);
}

test "UciProtocol initialization" {
    const protocol = UciProtocol.init(std.testing.allocator);
    try std.testing.expectEqual(protocol.debug_mode, false);
}

test "UCI command identification" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();

    try protocol.processCommand("uci");

    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "id name " ++ ENGINE_NAME) != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "id author " ++ ENGINE_AUTHOR) != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "uciok") != null);
}

test "UCI isready command response" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();

    try protocol.processCommand("isready");

    const output = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, output, "readyok") != null);
}

test "setoption command handling" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    try protocol.processCommand("setoption name Hash value 128");
    // Currently just verifying it doesn't error
    try std.testing.expect(true);
}

test "ucinewgame command handling" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    var protocol = UciProtocol.init(std.testing.allocator);
    protocol.test_writer = buf.writer();
    protocol.debug_mode = true;

    try protocol.processCommand("ucinewgame");
    // Currently just verifying it doesn't error
    try std.testing.expect(true);
}
