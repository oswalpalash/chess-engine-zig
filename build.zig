const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create executable
    const exe = b.addExecutable(.{
        .name = "play",
        .root_source_file = .{ .path = "src/uci.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add module dependencies
    const board_module = b.addModule("board", .{
        .source_file = .{ .path = "src/board.zig" },
    });
    const consts_module = b.addModule("consts", .{
        .source_file = .{ .path = "src/consts.zig" },
    });
    const moves_module = b.addModule("moves", .{
        .source_file = .{ .path = "src/moves.zig" },
    });
    const state_module = b.addModule("state", .{
        .source_file = .{ .path = "src/state.zig" },
    });
    const eval_module = b.addModule("eval", .{
        .source_file = .{ .path = "src/eval.zig" },
    });

    // Add module dependencies to executable using the new syntax
    exe.addModule("board", board_module);
    exe.addModule("consts", consts_module);
    exe.addModule("moves", moves_module);
    exe.addModule("state", state_module);
    exe.addModule("eval", eval_module);

    // Install the executable in the prefix
    b.installArtifact(exe);

    // Create "run" step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Create "run" step that can be invoked with "zig build run"
    const run_step = b.step("run", "Run the chess engine");
    run_step.dependOn(&run_cmd.step);

    // Add tests
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add module dependencies to tests using the new syntax
    unit_tests.addModule("board", board_module);
    unit_tests.addModule("consts", consts_module);
    unit_tests.addModule("moves", moves_module);
    unit_tests.addModule("state", state_module);
    unit_tests.addModule("eval", eval_module);

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Create "test" step that can be invoked with "zig build test"
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
