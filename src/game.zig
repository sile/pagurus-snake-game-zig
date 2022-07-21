const std = @import("std");
const system = @import("system.zig");
const EventWithData = @import("event.zig").EventWithData;
const Key = @import("event.zig").Key;
const assets = @import("assets.zig");
const image = @import("image.zig");
const Canvas = image.Canvas;
const CanvasView = image.CanvasView;
const Size = @import("spatial.zig").Size;
const Position = @import("spatial.zig").Position;
const xy = Position.xy;
const widget = @import("widget.zig");
const LogicalWindow = widget.LogicalWindow;
const Button = widget.Button;
const ButtonGroup = widget.ButtonGroup;
const ALLOCATOR = @import("main.zig").ALLOCATOR;
const BLACK = @import("image.zig").Rgb.BLACK;

const STATE_HIGH_SCORE = "high_score";

pub const Context = struct {
    prng: *std.rand.DefaultPrng,
    is_redraw_needed: bool,
    high_score: *u8,
    exit: bool,

    pub fn new(prng: *std.rand.DefaultPrng, high_score: *u8) Context {
        return .{
            .prng = prng,
            .is_redraw_needed = false,
            .exit = false,
            .high_score = high_score,
        };
    }
};

pub const SnakeGame = struct {
    logical_window: LogicalWindow,
    stage: Stage,
    prng: std.rand.DefaultPrng,
    high_score: u8,

    pub fn initialize(self: *SnakeGame) !void {
        const canvas_size = Size.square(384);
        self.logical_window = LogicalWindow.new(canvas_size);
        self.stage = Stage{ .title = TitleStage.new(0) };
        self.prng = std.rand.DefaultPrng.init(@floatToInt(u64, system.clockUnixTime()));
        self.high_score = 0;

        _ = system.stateLoad(STATE_HIGH_SCORE);
    }

    pub fn handleEvent(self: *SnakeGame, event_with_data: EventWithData) !bool {
        var context = Context.new(&self.prng, &self.high_score);

        const event = self.logical_window.handleEvent(event_with_data.event);
        switch (event) {
            .terminating => {
                return false;
            },
            .window_redraw_needed => {
                context.is_redraw_needed = true;
            },
            .state_loaded => {
                if (event_with_data.data) |data| {
                    self.high_score = data[0];
                    context.is_redraw_needed = true;
                }
            },
            else => {},
        }

        self.stage.handleEvent(event_with_data, &context);
        if (context.is_redraw_needed) {
            try self.drawVideoFrame();
        }
        if (context.exit) {
            return false;
        }

        return true;
    }

    fn drawVideoFrame(self: SnakeGame) !void {
        var canvas = try Canvas.new(ALLOCATOR, self.logical_window.logical_window_size);
        defer canvas.deinit(ALLOCATOR);

        canvas.fillRgb(BLACK);
        var canvas_view = try canvas.view(self.logical_window.canvas_region);
        canvas_view.drawSprite(Position.ORIGIN, assets.BACKGROUND);

        self.stage.render(canvas_view);

        system.videoDraw(canvas.data, canvas.size);
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
                    self.* = .{ .title = TitleStage.new(context.high_score.*) };
                },
                .playing => {
                    self.* = .{ .playing = PlayingStage.new(context) };
                },
                .game_over => {
                    switch (self.*) {
                        .playing => |x| {
                            self.* = .{ .game_over = GameOverStage.new(x.state, context) };
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
    const Self = @This();

    play_button: Button,
    exit_button: Button,
    high_score: u8,

    pub fn new(high_score: u8) Self {
        return .{
            .play_button = Button.PLAY,
            .exit_button = Button.EXIT,
            .high_score = high_score,
        };
    }

    fn handleEvent(self: *Self, ewd: EventWithData, context: *Context) ?StageType {
        self.high_score = context.high_score.*;

        const buttons = ButtonGroup{ .buttons = &[_]*Button{ &self.play_button, &self.exit_button } };
        if (buttons.handleEvent(ewd.event)) {
            context.is_redraw_needed = true;
        }

        if (self.play_button.state == Button.State.clicked) {
            return StageType.playing;
        } else if (self.exit_button.state == Button.State.clicked) {
            context.exit = true;
            return null;
        } else {
            return null;
        }
    }

    fn render(self: Self, canvas: CanvasView) void {
        canvas.drawSprite(xy(112, 206), self.play_button.currentSprite());
        canvas.drawSprite(xy(112, 250), self.exit_button.currentSprite());

        canvas.drawSprite(xy(64, 96), assets.STRING_SNAKE);
        renderHighScore(self.high_score, canvas);
    }
};

fn renderHighScore(score: u8, canvas: CanvasView) void {
    canvas.drawSprite(xy(180, 160), assets.STRING_HIGH_SCORE);
    canvas.drawSprite(xy(180 + 112, 160), assets.NUM_SMALL[score / 10]);
    canvas.drawSprite(xy(180 + 112 + 11, 160), assets.NUM_SMALL[score % 10]);
}

const SNAKE_MOVE_INTERVAL: f64 = 0.2;

pub const PlayingStage = struct {
    const Self = @This();

    state: GameState,
    nextDirection: Direction = Direction.up,

    pub fn new(context: *Context) Self {
        _ = system.clockSetTimeout(SNAKE_MOVE_INTERVAL);
        return .{
            .state = GameState.new(context),
        };
    }

    fn handleEvent(self: *Self, ewd: EventWithData, context: *Context) ?StageType {
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

    fn handleKeyUpEvent(self: *Self, key: Key, context: *Context) ?StageType {
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

    fn render(self: Self, canvas: CanvasView) void {
        self.state.render(canvas);
    }
};

pub const GameOverStage = struct {
    const Self = @This();

    state: GameState,
    retry_button: Button,
    title_button: Button,
    high_score: u8,

    pub fn new(state: GameState, context: *Context) Self {
        if (state.score() > context.high_score.*) {
            context.high_score.* = state.score();
            _ = system.stateSave(STATE_HIGH_SCORE, &.{state.score()});
        }

        return .{
            .state = state,
            .retry_button = Button.RETRY,
            .title_button = Button.TITLE,
            .high_score = context.high_score.*,
        };
    }

    fn handleEvent(self: *Self, ewd: EventWithData, context: *Context) ?StageType {
        const buttons = ButtonGroup{ .buttons = &[_]*Button{ &self.retry_button, &self.title_button } };
        if (buttons.handleEvent(ewd.event)) {
            context.is_redraw_needed = true;
        }

        if (self.retry_button.state == Button.State.clicked) {
            return StageType.playing;
        } else if (self.title_button.state == Button.State.clicked) {
            return StageType.title;
        } else {
            return null;
        }
    }

    fn render(self: Self, canvas: CanvasView) void {
        self.state.render(canvas);

        canvas.drawSprite(xy(64, 40), assets.STRING_GAME);
        canvas.drawSprite(xy(64, 100), assets.STRING_OVER);
        renderHighScore(self.high_score, canvas);

        canvas.fillRgba(BLACK.alpha(60));

        canvas.drawSprite(xy(112, 206), self.retry_button.currentSprite());
        canvas.drawSprite(xy(112, 250), self.title_button.currentSprite());
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

    pub fn score(self: Self) u8 {
        return @intCast(u8, self.snake.tail_index);
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

        // Score.
        const n = self.score();
        canvas.drawSprite(xy(32 * 10, 8), assets.NUM_LARGE[n / 10]);
        canvas.drawSprite(xy(32 * 10 + 16, 8), assets.NUM_LARGE[n % 10]);
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
