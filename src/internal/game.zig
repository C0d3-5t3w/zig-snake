const std = @import("std");

pub const Position = struct {
    x: i32,
    y: i32,
};

pub const Direction = enum {
    Up,
    Down,
    Left,
    Right,
};

pub const Snake = struct {
    body: []Position,
    dir: Direction,
};

pub const Food = struct {
    pos: Position,
};

pub const GameState = struct {
    snake: Snake,
    food: Food,
    boardWidth: i32,
    boardHeight: i32,
    gameOver: bool,
};

pub fn initGame(state: *GameState, allocator: *std.mem.Allocator, width: i32, height: i32) !void {
    state.boardWidth = width;
    state.boardHeight = height;
    state.gameOver = false;
    // initialize snake at center with 3 segments
    var initial = try allocator.alloc(Position, 3);
    initial[0] = Position{ .x = width / 2, .y = height / 2 };
    initial[1] = Position{ .x = width / 2 - 1, .y = height / 2 };
    initial[2] = Position{ .x = width / 2 - 2, .y = height / 2 };
    state.snake = Snake{ .body = initial, .dir = Direction.Right };
    // place food at an initial position
    state.food = Food{ .pos = Position{ .x = width / 4, .y = height / 4 } };
};

pub fn updateGame(state: *GameState, allocator: *std.mem.Allocator) !void {
    if (state.gameOver) return;
    const head = state.snake.body[0];
    var newHead = head;
    switch (state.snake.dir) {
        Direction.Up => newHead.y -= 1,
        Direction.Down => newHead.y += 1,
        Direction.Left => newHead.x -= 1,
        Direction.Right => newHead.x += 1,
    }
    if (newHead.x < 0 or newHead.x >= state.boardWidth or newHead.y < 0 or newHead.y >= state.boardHeight) {
        state.gameOver = true;
        return;
    }
    for (state.snake.body) |pos| {
        if (pos.x == newHead.x and pos.y == newHead.y) {
            state.gameOver = true;
            return;
        }
    }
    // grow snake by inserting new head
    var newBody = try allocator.realloc(state.snake.body, state.snake.body.len, state.snake.body.len + 1);
    std.mem.move(Position, newBody[1..], newBody[0 .. newBody.len - 1]);
    newBody[0] = newHead;
    state.snake.body = newBody;
    if (newHead.x == state.food.pos.x and newHead.y == state.food.pos.y) {
        // food eaten, place new food using a simple offset
        state.food.pos.x = (state.food.pos.x + 3) % state.boardWidth;
        state.food.pos.y = (state.food.pos.y + 2) % state.boardHeight;
    } else {
        // remove tail (shrink snake)
        state.snake.body = state.snake.body[0 .. state.snake.body.len - 1];
    }
};
