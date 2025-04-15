const std = @import("std");
const game = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var snake_game = try game.SnakeGame.init(allocator);
    defer snake_game.deinit();

    try snake_game.run();
}
