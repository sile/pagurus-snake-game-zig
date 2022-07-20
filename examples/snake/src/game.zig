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

pub const Context = struct {
    is_redraw_needed: bool,

    pub fn new() Context {
        return .{ .is_redraw_needed = false };
    }
};

pub const SnakeGame = struct {
    logical_window: LogicalWindow,
    stage: Stage,

    pub fn initialize(self: *SnakeGame) !void {
        const canvas_size = Size.square(384);
        self.logical_window = LogicalWindow.new(canvas_size);
        self.stage = Stage{ .title = TitleStage.new() };
    }

    pub fn handleEvent(self: *SnakeGame, event_with_data: EventWithData) !bool {
        var context = Context.new();
        self.stage.handleEvent(event_with_data, &context);
        if (context.is_redraw_needed) {
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

    pub fn handleEvent(self: *Stage, ewd: EventWithData, context: *Context) void {
        switch (self.*) {
            .title => |*x| {
                x.handleEvent(ewd, context);
            },
            .playing => {},
            .game_over => {},
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

    fn handleEvent(self: *TitleStage, ewd: EventWithData, context: *Context) void {
        const buttons = ButtonGroup{ .buttons = &[_]*assets.ButtonWidget{ &self.play_button, &self.exit_button } };
        buttons.handleEvent(ewd, context);

        _ = self;
        _ = ewd;
        _ = context;
    }

    fn render(self: TitleStage, canvas: CanvasView) void {
        canvas.drawSprite(xy(112, 206), self.play_button.currentSprite());
        canvas.drawSprite(xy(112, 250), self.exit_button.currentSprite());
    }
};

pub const PlayingStage = struct {};

pub const GameOverStage = struct {};

pub const ButtonGroup = struct {
    buttons: []*assets.ButtonWidget,

    pub fn handleEvent(self: ButtonGroup, ewd: EventWithData, context: *Context) void {
        const focused = find_focus: for (self.buttons) |b, i| {
            if (b.isFocused()) {
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
