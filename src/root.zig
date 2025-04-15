const std = @import("std");
const os = std.os;

// Direction enum for snake movement
const Direction = enum {
    Up,
    Down,
    Left,
    Right,
};

// Position struct for coordinates
const Position = struct {
    x: i32,
    y: i32,
};

// Game board dimensions
const WIDTH = 40;
const HEIGHT = 20;

// Snake game implementation
pub const SnakeGame = struct {
    allocator: std.mem.Allocator,
    snake: std.ArrayList(Position),
    food: Position,
    direction: Direction,
    running: bool,
    score: usize,
    original_termios: os.linux.termios,

    pub fn init(allocator: std.mem.Allocator) !SnakeGame {
        var snake = std.ArrayList(Position).init(allocator);

        // Initialize snake with 3 segments in the middle
        const start_x = WIDTH / 2;
        const start_y = HEIGHT / 2;
        try snake.append(Position{ .x = start_x, .y = start_y });
        try snake.append(Position{ .x = start_x - 1, .y = start_y });
        try snake.append(Position{ .x = start_x - 2, .y = start_y });

        // Get original terminal settings
        const stdin = std.io.getStdIn().handle;
        var termios = try os.tcgetattr(stdin);
        const original_termios = termios;

        // Set terminal to raw mode
        termios.lflag &= ~@as(os.linux.tcflag_t, os.linux.ECHO | os.linux.ICANON);
        try os.tcsetattr(stdin, .FLUSH, termios);

        var game = SnakeGame{
            .allocator = allocator,
            .snake = snake,
            .food = Position{ .x = 0, .y = 0 },
            .direction = .Right,
            .running = true,
            .score = 0,
            .original_termios = original_termios,
        };

        // Place initial food
        game.placeFood();

        return game;
    }

    pub fn deinit(self: *SnakeGame) void {
        // Restore terminal settings
        const stdin = std.io.getStdIn().handle;
        _ = os.tcsetattr(stdin, .FLUSH, self.original_termios) catch {};

        // Free resources
        self.snake.deinit();
    }

    fn placeFood(self: *SnakeGame) void {
        var prng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        const random = prng.random();

        // Try to place food in a position not occupied by the snake
        var found = false;
        while (!found) {
            const x = random.intRangeAtMost(i32, 1, WIDTH - 2);
            const y = random.intRangeAtMost(i32, 1, HEIGHT - 2);
            found = true;

            // Check if the position is occupied by the snake
            for (self.snake.items) |segment| {
                if (segment.x == x and segment.y == y) {
                    found = false;
                    break;
                }
            }

            if (found) {
                self.food = Position{ .x = x, .y = y };
            }
        }
    }

    fn handleInput(self: *SnakeGame) !void {
        const stdin = std.io.getStdIn().handle;
        var buf: [1]u8 = undefined;

        // Check if there's input available
        const nread = std.os.read(stdin, &buf) catch 0;
        if (nread > 0) {
            switch (buf[0]) {
                'w' => {
                    if (self.direction != .Down) self.direction = .Up;
                },
                's' => {
                    if (self.direction != .Up) self.direction = .Down;
                },
                'a' => {
                    if (self.direction != .Right) self.direction = .Left;
                },
                'd' => {
                    if (self.direction != .Left) self.direction = .Right;
                },
                'q' => self.running = false,
                else => {},
            }
        }
    }

    fn update(self: *SnakeGame) !bool {
        // Get the head position
        const head = self.snake.items[0];

        // Calculate new head position based on direction
        var new_head = Position{ .x = head.x, .y = head.y };
        switch (self.direction) {
            .Up => new_head.y -= 1,
            .Down => new_head.y += 1,
            .Left => new_head.x -= 1,
            .Right => new_head.x += 1,
        }

        // Check if snake hit the wall
        if (new_head.x < 0 or new_head.x >= WIDTH or new_head.y < 0 or new_head.y >= HEIGHT) {
            return false;
        }

        // Check if snake hit itself
        for (self.snake.items) |segment| {
            if (segment.x == new_head.x and segment.y == new_head.y) {
                return false;
            }
        }

        // Move snake
        try self.snake.insert(0, new_head);

        // Check if snake ate food
        if (new_head.x == self.food.x and new_head.y == self.food.y) {
            // Grow the snake (don't remove the tail)
            self.score += 10;
            self.placeFood();
        } else {
            // Remove the tail
            _ = self.snake.pop();
        }

        return true;
    }

    fn render(self: *SnakeGame, writer: anytype) !void {
        try writer.print("\x1B[2J\x1B[H", .{}); // Clear screen and move cursor to top-left

        // Create the game board
        var board: [HEIGHT][WIDTH]u8 = undefined;
        for (0..HEIGHT) |y| {
            for (0..WIDTH) |x| {
                board[y][x] = ' ';
            }
        }

        // Draw borders
        for (0..WIDTH) |x| {
            board[0][x] = '#';
            board[HEIGHT - 1][x] = '#';
        }
        for (0..HEIGHT) |y| {
            board[y][0] = '#';
            board[y][WIDTH - 1] = '#';
        }

        // Draw snake
        for (self.snake.items) |segment| {
            if (segment.x >= 0 and segment.x < WIDTH and segment.y >= 0 and segment.y < HEIGHT) {
                board[@intCast(segment.y)][@intCast(segment.x)] = 'O';
            }
        }

        // Mark snake head
        if (self.snake.items.len > 0) {
            const head = self.snake.items[0];
            if (head.x >= 0 and head.x < WIDTH and head.y >= 0 and head.y < HEIGHT) {
                board[@intCast(head.y)][@intCast(head.x)] = '@';
            }
        }

        // Draw food
        board[@intCast(self.food.y)][@intCast(self.food.x)] = '*';

        // Print the board
        for (0..HEIGHT) |y| {
            for (0..WIDTH) |x| {
                try writer.print("{c}", .{board[y][x]});
            }
            try writer.print("\n", .{});
        }

        // Print score and controls
        try writer.print("\nScore: {}\n", .{self.score});
        try writer.print("Controls: WASD to move, Q to quit\n", .{});
    }

    pub fn run(self: *SnakeGame) !void {
        const stdout = std.io.getStdOut().writer();

        while (self.running) {
            try self.handleInput();
            const alive = try self.update();

            if (!alive) {
                self.running = false;
            }

            try self.render(stdout);

            // Delay to control game speed
            std.time.sleep(100 * std.time.ns_per_ms);
        }

        // Game over screen
        try stdout.print("\x1B[2J\x1B[H", .{}); // Clear screen
        try stdout.print("Game Over! Final Score: {}\n", .{self.score});
        try stdout.print("Press any key to exit...\n", .{});

        // Wait for a keypress before exiting
        var buf: [1]u8 = undefined;
        _ = std.os.read(std.io.getStdIn().handle, &buf) catch {};
    }
};
