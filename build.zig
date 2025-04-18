const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("zig-snake", "src/main.zig");
    exe.setBuildMode(mode);
    exe.addModule("internal/game", "src/internal/game.zig");
    exe.addModule("internal/gui", "src/internal/gui.zig");
    exe.install();
};
