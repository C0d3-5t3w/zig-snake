const std = @import("std");
const game = @import("internal/game.zig");
const gui = @import("internal/gui.zig");

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var gameState: game.GameState = undefined;
    try game.initGame(&gameState, allocator, 40, 20);
    var stdout = std.io.getStdOut().writer();
    // simple timer-based game loop
    while (!gameState.gameOver) {
        // For demo purposes, the direction stays constant.
        // In a real game, input handling would update gameState.snake.dir.
        try game.updateGame(&gameState, allocator);
        try gui.render(&gameState, stdout);
        std.time.sleep(200 * std.time.millisecond);
    }
    try stdout.writeAll("Press any key to exit...\n");
    _ = std.io.getStdIn().readAllAlloc(allocator, 1);
};
