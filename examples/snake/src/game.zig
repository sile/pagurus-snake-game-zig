const system = @import("system.zig");
const EventWithData = @import("event.zig").EventWithData;
const Key = @import("event.zig").Key;
const assets = @import("assets.zig");
const xy = assets.xy;
const Canvas = assets.Canvas;
const CanvasView = assets.CanvasView;
const Size = assets.Size;
const Position = assets.Position;
const LogicalWindow = assets.LogicalWindow;
const ALLOCATOR = @import("main.zig").ALLOCATOR;
const std = @import("std");

pub const Context = struct {
    prng: *std.rand.DefaultPrng,
    is_redraw_needed: bool,
    exit: bool,

    pub fn new(prng: *std.rand.DefaultPrng) Context {
        return .{ .prng = prng, .is_redraw_needed = false, .exit = false };
    }
};

pub const SnakeGame = struct {
    logical_window: LogicalWindow,
    stage: Stage,
    prng: std.rand.DefaultPrng,

    pub fn initialize(self: *SnakeGame) !void {
        const canvas_size = Size.square(384);
        self.logical_window = LogicalWindow.new(canvas_size);
        self.stage = Stage{ .title = TitleStage.new() };
        self.prng = std.rand.DefaultPrng.init(@floatToInt(u64, system.clockUnixTime()));
    }

    pub fn handleEvent(self: *SnakeGame, event_with_data: EventWithData) !bool {
        var context = Context.new(&self.prng);
        self.stage.handleEvent(event_with_data, &context);
        if (context.is_redraw_needed) {
            self.drawVideoFrame() catch @panic("TODO");
        }
        if (context.exit) {
            return false;
        }

        const event = self.logical_window.handleEvent(event_with_data.event);
        switch (event) {
            .terminating => {
                return false;
            },
            .window_redraw_needed => {
                self.drawVideoFrame() catch @panic("TODO");
            },
            else => {},
        }
        return true;
    }

    fn drawVideoFrame(self: SnakeGame) !void {
        var canvas = try Canvas.new(ALLOCATOR, self.logical_window.logical_window_size);
        defer canvas.deinit(ALLOCATOR);

        canvas.fillRgb(.{ .r = 0, .g = 0, .b = 0 });
        var canvas_view = try canvas.view(self.logical_window.canvas_region);
        canvas_view.drawSprite(Position.ORIGIN, assets.BACKGROUND);

        self.stage.render(canvas_view);

        system.videoDraw(canvas.image_data, canvas.image_size);
    }
};

pub const StageType = enum { title, playing, game_over };

pub const Stage = union(StageType) {
    title: TitleStage,
    playing: PlayingStage,
    game_over: GameOverStage,

    pub fn handleEvent(self: *Stage, ewd: EventWithData, context: *Context) void {
        const next_stage_type = switch (self.*) {
            .title => |*x| x.handleEvent(ewd, context),
            .playing => |*x| x.handleEvent(ewd, context),
            .game_over => |*x| x.handleEvent(ewd, context),
        };

        if (next_stage_type) |ty| {
            switch (ty) {
                .title => {
                    self.* = .{ .title = TitleStage.new() };
                },
                .playing => {
                    self.* = .{ .playing = PlayingStage.new(context) };
                },
                .game_over => {
                    switch (self.*) {
                        .playing => |x| {
                            self.* = .{ .game_over = GameOverStage.new(x.state) };
                        },
                        else => {
                            unreachable;
                        },
                    }
                },
            }
            context.is_redraw_needed = true;
        }
    }

    pub fn render(self: Stage, canvas: CanvasView) void {
        switch (self) {
            .title => |x| x.render(canvas),
            .playing => |x| x.render(canvas),
            .game_over => |x| x.render(canvas),
        }
    }
};

pub const TitleStage = struct {
    play_button: assets.ButtonWidget,
    exit_button: assets.ButtonWidget,

    pub fn new() TitleStage {
        return .{ .play_button = assets.PLAY_BUTTON_WIDGET, .exit_button = assets.EXIT_BUTTON_WIDGET };
    }

    fn handleEvent(self: *TitleStage, ewd: EventWithData, context: *Context) ?StageType {
        const buttons = ButtonGroup{ .buttons = &[_]*assets.ButtonWidget{ &self.play_button, &self.exit_button } };
        buttons.handleEvent(ewd, context);
        if (self.play_button.state == assets.ButtonState.clicked) {
            return StageType.playing;
        } else if (self.exit_button.state == assets.ButtonState.clicked) {
            context.exit = true;
            return null;
        } else {
            return null;
        }
    }

    fn render(self: TitleStage, canvas: CanvasView) void {
        canvas.drawSprite(xy(112, 206), self.play_button.currentSprite());
        canvas.drawSprite(xy(112, 250), self.exit_button.currentSprite());
    }
};

const SNAKE_MOVE_INTERVAL: f64 = 0.2;

pub const PlayingStage = struct {
    const Self = @This();

    state: GameState,
    nextDirection: Direction = Direction.up,

    pub fn new(context: *Context) PlayingStage {
        _ = system.clockSetTimeout(SNAKE_MOVE_INTERVAL);
        return .{
            .state = GameState.new(context),
        };
    }

    fn handleEvent(self: *PlayingStage, ewd: EventWithData, context: *Context) ?StageType {
        switch (ewd.event) {
            .key_up => |e| {
                return self.handleKeyUpEvent(e.key.up.key, context);
            },
            .timeout => {
                self.state.snake.direction = self.nextDirection;
                if (self.state.snake.moveOne()) {
                    if (self.state.snake.head.equal(self.state.apple)) {
                        self.state.spawnApple(context);
                    } else {
                        self.state.snake.tail_index -= 1;
                    }
                    _ = system.clockSetTimeout(SNAKE_MOVE_INTERVAL);
                    context.is_redraw_needed = true;
                    return null;
                } else {
                    return StageType.game_over;
                }
            },
            else => {
                return null;
            },
        }
    }

    fn handleKeyUpEvent(self: *PlayingStage, key: Key, context: *Context) ?StageType {
        _ = self;
        _ = context;
        switch (key) {
            .up => {
                if (self.state.snake.direction != Direction.down) {
                    self.nextDirection = Direction.up;
                }
            },
            .down => {
                if (self.state.snake.direction != Direction.up) {
                    self.nextDirection = Direction.down;
                }
            },
            .left => {
                if (self.state.snake.direction != Direction.right) {
                    self.nextDirection = Direction.left;
                }
            },
            .right => {
                if (self.state.snake.direction != Direction.left) {
                    self.nextDirection = Direction.right;
                }
            },
            else => {},
        }
        return null;
    }

    fn render(self: PlayingStage, canvas: CanvasView) void {
        self.state.render(canvas);
    }
};

pub const GameOverStage = struct {
    const Self = @This();

    state: GameState,
    retry_button: assets.ButtonWidget,
    title_button: assets.ButtonWidget,

    pub fn new(state: GameState) Self {
        return .{ //
            .state = state,
            .retry_button = assets.RETRY_BUTTON_WIDGET,
            .title_button = assets.TITLE_BUTTON_WIDGET,
        };
    }

    fn handleEvent(self: *Self, ewd: EventWithData, context: *Context) ?StageType {
        const buttons = ButtonGroup{ .buttons = &[_]*assets.ButtonWidget{ &self.retry_button, &self.title_button } };
        buttons.handleEvent(ewd, context);
        if (self.retry_button.state == assets.ButtonState.clicked) {
            return StageType.playing;
        } else if (self.title_button.state == assets.ButtonState.clicked) {
            return StageType.title;
        } else {
            return null;
        }
    }

    fn render(self: Self, canvas: CanvasView) void {
        canvas.drawSprite(xy(112, 206), self.retry_button.currentSprite());
        canvas.drawSprite(xy(112, 250), self.title_button.currentSprite());
    }
};

pub const ButtonGroup = struct {
    buttons: []*assets.ButtonWidget,

    pub fn handleEvent(self: ButtonGroup, ewd: EventWithData, context: *Context) void {
        const focused = find_focus: for (self.buttons) |b, i| {
            if (b.state != assets.ButtonState.normal) {
                break :find_focus i;
            }
        } else {
            switch (ewd.event) {
                .key_up => {
                    self.buttons[0].state = assets.ButtonState.focused;
                    context.is_redraw_needed = true;
                },
                else => {},
            }
            return;
        };

        switch (ewd.event) {
            .key_up => |e| {
                switch (e.key.up.key) {
                    .up => {
                        if (focused > 0) {
                            self.buttons[focused].state = assets.ButtonState.normal;
                            self.buttons[focused - 1].state = assets.ButtonState.focused;
                            context.is_redraw_needed = true;
                        }
                    },
                    .down => {
                        if (focused < self.buttons.len - 1) {
                            self.buttons[focused].state = assets.ButtonState.normal;
                            self.buttons[focused + 1].state = assets.ButtonState.focused;
                            context.is_redraw_needed = true;
                        }
                    },
                    .@"return" => {
                        if (self.buttons[focused].state == assets.ButtonState.pressed) {
                            self.buttons[focused].state = assets.ButtonState.clicked;
                            context.is_redraw_needed = true;
                        }
                    },
                    else => {},
                }
            },
            .key_down => |e| {
                switch (e.key.down.key) {
                    .@"return" => {
                        self.buttons[focused].state = assets.ButtonState.pressed;
                        context.is_redraw_needed = true;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
};

pub const GameState = struct {
    const Self = @This();

    snake: Snake,
    apple: Position,

    pub fn new(context: *Context) Self {
        const snake = Snake.new();
        var self = Self{ .snake = snake, .apple = .{ .x = 0, .y = 0 } };
        self.spawnApple(context);
        return self;
    }

    pub fn spawnApple(self: *Self, context: *Context) void {
        while (true) {
            const apple = randomPosition(context.prng);

            if (self.snake.conflicts(apple)) {
                continue;
            }

            self.apple = apple;
            break;
        }
    }

    pub fn render(self: Self, canvas: CanvasView) void {
        // Apple.
        canvas.drawSprite(cellPositionToCanvasPosition(self.apple), assets.APPLE);

        // Snake.
        canvas.drawSprite(cellPositionToCanvasPosition(self.snake.head), assets.SNAKE_HEAD);
        for (self.snake.currentTail()) |tail| {
            canvas.drawSprite(cellPositionToCanvasPosition(tail), assets.SNAKE_TAIL);
        }
    }
};

fn cellPositionToCanvasPosition(pos: Position) Position {
    return .{ .x = (pos.x + 1) * 32, .y = (pos.y + 1) * 32 };
}

pub const Direction = enum { up, down, left, right };

pub const Snake = struct {
    const Self = @This();

    head: Position,
    tail: [100]Position,
    tail_index: usize,
    direction: Direction,

    pub fn new() Self {
        return .{ .head = .{ .x = 5, .y = 5 }, .tail = undefined, .tail_index = 0, .direction = Direction.up };
    }

    pub fn moveOne(self: *Self) bool {
        var new_head = self.head;
        switch (self.direction) {
            .up => {
                new_head.y -= 1;
                if (new_head.y < 0) {
                    return false;
                }
            },
            .down => {
                new_head.y += 1;
                if (new_head.y > 9) {
                    return false;
                }
            },
            .left => {
                new_head.x -= 1;
                if (new_head.x < 0) {
                    return false;
                }
            },
            .right => {
                new_head.x += 1;
                if (new_head.x > 9) {
                    return false;
                }
            },
        }

        var i = self.tail_index;
        while (0 < i) : (i -= 1) {
            self.tail[i] = self.tail[i - 1];
        }
        self.tail[0] = self.head;
        self.tail_index += 1;
        self.head = new_head;
        return true;
    }

    pub fn conflicts(self: Self, item: Position) bool {
        if (self.head.equal(item)) {
            return true;
        }
        for (self.currentTail()) |t| {
            if (t.equal(item)) {
                return true;
            }
        }
        return false;
    }

    pub fn currentTail(self: Self) []const Position {
        return self.tail[0..self.tail_index];
    }
};

fn randomPosition(prng: *std.rand.DefaultPrng) Position {
    const rand = prng.random();
    return .{ .x = rand.intRangeAtMost(i32, 0, 9), .y = rand.intRangeAtMost(i32, 0, 9) };
}
