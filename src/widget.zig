const Size = @import("spatial.zig").Size;
const Position = @import("spatial.zig").Position;
const Region = @import("spatial.zig").Region;
const Event = @import("event.zig").Event;
const assets = @import("assets.zig");
const Sprite = @import("image.zig").Sprite;

pub const LogicalWindow = struct {
    const Self = @This();

    canvas_region: Region,
    logical_window_size: Size,
    actual_window_size: Size,

    pub fn new(canvas_size: Size) Self {
        return .{
            .canvas_region = canvas_size.toRegion(),
            .logical_window_size = canvas_size,
            .actual_window_size = Size.square(0),
        };
    }

    pub fn handleEvent(self: *Self, event: Event) Event {
        switch (event) {
            .window_redraw_needed => |e| {
                self.handleWindowSizeChange(e.window.redrawNeeded.size);
            },
            else => {},
        }
        return event;
    }

    fn handleWindowSizeChange(self: *Self, size: Size) void {
        self.actual_window_size = size;
        self.logical_window_size = self.canvas_region.size;

        var canvas = self.canvas_region.size;
        var actual_window = self.actual_window_size;
        if (canvas.aspectRatio() > actual_window.aspectRatio()) {
            const scale = @intToFloat(f32, canvas.width) / @intToFloat(f32, actual_window.width);
            self.logical_window_size.height =
                @floatToInt(u32, @round(@intToFloat(f32, actual_window.height) * scale));
            const padding = (self.logical_window_size.height - canvas.height) / 2;
            self.canvas_region.position = Position.xy(0, @intCast(i32, padding));
        } else if (canvas.aspectRatio() < actual_window.aspectRatio()) {
            const scale = @intToFloat(f32, canvas.height) / @intToFloat(f32, actual_window.height);
            self.logical_window_size.width =
                @floatToInt(u32, @round(@intToFloat(f32, actual_window.width) * scale));
            const padding = (self.logical_window_size.width - canvas.width) / 2;
            self.canvas_region.position = Position.xy(@intCast(i32, padding), 0);
        } else {
            self.canvas_region.position = Position.ORIGIN;
        }
    }
};

pub const Button = struct {
    const Self = @This();

    pub const State = enum { normal, focused, pressed, clicked };

    pub const PLAY: Self = new(.{
        .normal = assets.PLAY_BUTTON_NORMAL,
        .focused = assets.PLAY_BUTTON_FOCUSED,
        .pressed = assets.PLAY_BUTTON_PRESSED,
    });

    pub const EXIT: Self = new(.{
        .normal = assets.EXIT_BUTTON_NORMAL,
        .focused = assets.EXIT_BUTTON_FOCUSED,
        .pressed = assets.EXIT_BUTTON_PRESSED,
    });

    pub const RETRY: Self = new(.{
        .normal = assets.RETRY_BUTTON_NORMAL,
        .focused = assets.RETRY_BUTTON_FOCUSED,
        .pressed = assets.RETRY_BUTTON_PRESSED,
    });

    pub const TITLE: Self = new(.{
        .normal = assets.TITLE_BUTTON_NORMAL,
        .focused = assets.TITLE_BUTTON_FOCUSED,
        .pressed = assets.TITLE_BUTTON_PRESSED,
    });

    state: State,
    sprites: ButtonSprites,

    fn new(sprites: ButtonSprites) Self {
        return .{ .state = State.normal, .sprites = sprites };
    }

    pub fn currentSprite(self: Self) Sprite {
        switch (self.state) {
            .normal => {
                return self.sprites.normal;
            },
            .focused => {
                return self.sprites.focused;
            },
            .pressed => {
                return self.sprites.pressed;
            },
            .clicked => {
                return self.sprites.pressed;
            },
        }
    }
};

const ButtonSprites = struct { normal: Sprite, focused: Sprite, pressed: Sprite };

pub const ButtonGroup = struct {
    const Self = @This();

    buttons: []*Button,

    pub fn handleEvent(self: Self, event: Event) bool {
        const focused = find_focus: for (self.buttons) |b, i| {
            if (b.state != Button.State.normal) {
                break :find_focus i;
            }
        } else {
            switch (event) {
                .key_up => {
                    self.buttons[0].state = Button.State.focused;
                    return true;
                },
                else => {},
            }
            return false;
        };

        switch (event) {
            .key_up => |e| {
                switch (e.key.up.key) {
                    .up => {
                        if (focused > 0) {
                            self.buttons[focused].state = Button.State.normal;
                            self.buttons[focused - 1].state = Button.State.focused;
                            return true;
                        }
                    },
                    .down => {
                        if (focused < self.buttons.len - 1) {
                            self.buttons[focused].state = Button.State.normal;
                            self.buttons[focused + 1].state = Button.State.focused;
                            return true;
                        }
                    },
                    .@"return" => {
                        if (self.buttons[focused].state == Button.State.pressed) {
                            self.buttons[focused].state = Button.State.clicked;
                            return true;
                        }
                    },
                    else => {},
                }
            },
            .key_down => |e| {
                switch (e.key.down.key) {
                    .@"return" => {
                        self.buttons[focused].state = Button.State.pressed;
                        return true;
                    },
                    else => {},
                }
            },
            else => {},
        }

        return false;
    }
};
