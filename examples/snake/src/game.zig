const system = @import("system.zig");
const EventWithData = @import("event.zig").EventWithData;
const assets = @import("assets.zig");
const xy = assets.xy;
const Canvas = assets.Canvas;
const CanvasView = assets.CanvasView;
const Size = assets.Size;
const Position = assets.Position;
const LogicalWindow = assets.LogicalWindow;
const ALLOCATOR = @import("main.zig").ALLOCATOR;

pub const SnakeGame = struct {
    logical_window: LogicalWindow,
    stage: Stage,

    pub fn initialize(self: *SnakeGame) !void {
        const canvas_size = Size.square(384);
        self.logical_window = LogicalWindow.new(canvas_size);
        self.stage = Stage{ .title = TitleStage.new() };
    }

    pub fn handleEvent(self: *SnakeGame, event_with_data: EventWithData) !bool {
        if (self.stage.handleEvent(event_with_data)) {
            self.drawVideoFrame() catch @panic("TODO");
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

pub const Stage = union(enum) {
    title: TitleStage,
    playing: PlayingStage,
    game_over: GameOverStage,

    pub fn handleEvent(self: *Stage, ewd: EventWithData) bool {
        switch (self.*) {
            .title => |*x| {
                return x.handleEvent(ewd);
            },
            .playing => {
                return false;
            },
            .game_over => {
                return false;
            },
        }
    }

    pub fn render(self: Stage, canvas: CanvasView) void {
        switch (self) {
            .title => |x| x.render(canvas),
            .playing => {},
            .game_over => {},
        }
    }
};

pub const TitleStage = struct {
    play_button: assets.ButtonWidget,
    exit_button: assets.ButtonWidget,

    pub fn new() TitleStage {
        return .{ .play_button = assets.PLAY_BUTTON_WIDGET, .exit_button = assets.EXIT_BUTTON_WIDGET };
    }

    fn handleEvent(self: *TitleStage, ewd: EventWithData) bool {
        _ = self;
        _ = ewd;
        return false;
    }

    fn render(self: TitleStage, canvas: CanvasView) void {
        canvas.drawSprite(xy(112, 206), self.play_button.currentSprite());
        canvas.drawSprite(xy(112, 250), self.exit_button.currentSprite());
    }
};

pub const PlayingStage = struct {};

pub const GameOverStage = struct {};
