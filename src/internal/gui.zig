const std = @import("std");
const GameState = @import("game.zig").GameState;
const Position = @import("game.zig").Position;

pub fn render(state: *GameState, stdout: *std.io.Writer) !void {
    // clear screen and position cursor at top left
    try stdout.writeAll("\x1b[2J\x1b[H");
    // draw top border
    try stdout.writeAll("+" ++ std.mem.repeat("-", state.boardWidth) ++ "+\n");
    for (std.math.range(0, state.boardHeight)) |y| {
        try stdout.writeAll("|");
        for (std.math.range(0, state.boardWidth)) |x| {
            var ch: u8 = ' ';
            var drawn = false;
            for (state.snake.body) |pos| {
                if (pos.x == x and pos.y == y) {
                    ch = '*';
                    drawn = true;
                    break;
                }
            }
            if (!drawn and state.food.pos.x == x and state.food.pos.y == y) {
                ch = 'O';
            }
            try stdout.writeAll(&.{ch});
        }
        try stdout.writeAll("|\n");
    }
    // draw bottom border
    try stdout.writeAll("+" ++ std.mem.repeat("-", state.boardWidth) ++ "+\n");
    if (state.gameOver) {
        try stdout.writeAll("GAME OVER\n");
    }
};
