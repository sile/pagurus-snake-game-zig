const system = @import("system.zig");
const Event = @import("event.zig").Event;
const std = @import("std");

pub const IMG_BACKGROUND = @embedFile("../assets/background.rawrgba");

// TODO: move
pub const Size = struct {
    width: u32,
    height: u32,

    pub fn equal(self: Size, other: Size) bool {
        return self.width == other.width and self.height == other.height;
    }

    pub fn toRegion(self: Size) Region {
        return .{ .position = xy(0, 0), .size = self };
    }

    pub fn square(size: usize) Size {
        return .{ .width = size, .height = size };
    }

    pub fn aspectRatio(self: Size) f32 {
        return @intToFloat(f32, self.width) / @intToFloat(f32, self.height);
    }
};

pub const Position = struct {
    x: i32,
    y: i32,

    pub const ORIGIN: Position = .{ .x = 0, .y = 0 };

    fn isLessThanOrEqualTo(self: Position, other: Position) bool {
        return self.x <= other.x and self.y <= other.y;
    }
};

pub const Region = struct {
    position: Position,
    size: Size,

    pub fn startPosition(self: Region) Position {
        return self.position;
    }

    pub fn endPosition(self: Region) Position {
        return .{ .x = self.position.x + @intCast(i32, self.size.width), .y = self.position.y + @intCast(i32, self.size.height) };
    }

    pub fn containsRegion(self: Region, other: Region) bool {
        return self.startPosition().isLessThanOrEqualTo(other.startPosition()) and
            other.endPosition().isLessThanOrEqualTo(self.endPosition());
    }

    pub fn containsPosition(self: Region, pos: Position) bool {
        return self.containsRegion(.{ .position = pos, .size = wh(0, 0) });
    }
};

pub const Rgb = struct {
    r: u8,
    g: u8,
    b: u8,

    pub const BLACK: Rgb = .{ .r = 0, .g = 0, .b = 0 };
};

pub const Rgba = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn toAlphaBlendRgb(self: Rgba, dst: Rgb) Rgb {
        return .{ .r = blend(self.r, dst.r, self.a), .g = blend(self.g, dst.g, self.a), .b = blend(self.b, dst.b, self.a) };
    }
};

fn blend(src: u16, dst: u16, alpha: u16) u8 {
    const v = src * alpha + dst * (255 - alpha);
    return @intCast(u8, v / 255);
}

pub const PixelIterator = struct {
    pub const Item = struct { position: Position, rgba: Rgba };

    sprite: Sprite,
    position: Position,

    pub fn next(self: *PixelIterator) ?PixelIterator.Item {
        if (self.position.y == self.sprite.sprite_region.endPosition().y) {
            return null;
        }

        const current = self.position;
        self.position.x += 1;
        if (self.position.x == self.sprite.sprite_region.endPosition().x) {
            self.position.x = self.sprite.sprite_region.position.x;
            self.position.y += 1;
        }

        const i = (@intCast(usize, current.y) * @intCast(usize, self.sprite.image_size.width) + @intCast(usize, current.x)) * 4;
        const pixel = .{ //
            .r = self.sprite.image_data[i],
            .g = self.sprite.image_data[i + 1],
            .b = self.sprite.image_data[i + 2],
            .a = self.sprite.image_data[i + 3],
        };

        var relative_position = current;
        relative_position.x -= self.sprite.sprite_region.position.x;
        relative_position.y -= self.sprite.sprite_region.position.y;
        return PixelIterator.Item{ .position = relative_position, .rgba = pixel };
    }
};

// TODO: move
pub const Sprite = struct {
    // RGBA
    image_data: []const u8,
    image_size: Size,
    sprite_region: Region,

    pub fn pixels(self: Sprite) PixelIterator {
        return .{ .sprite = self, .position = self.sprite_region.position };
    }
};

pub fn createSprite(image_data: []const u8, image_size: Size, sprite_position: Position, sprite_size: Size) Sprite {
    return .{ .image_data = image_data, .image_size = image_size, .sprite_region = .{ .position = sprite_position, .size = sprite_size } };
}

pub fn xy(x: i32, y: i32) Position {
    return .{ .x = x, .y = y };
}

pub fn wh(width: u32, height: u32) Size {
    return .{ .width = width, .height = height };
}

pub fn square(size: u32) Size {
    return wh(size, size);
}

pub const Canvas = struct {
    // RGB
    image_data: []u8,
    image_size: Size,

    pub fn new(allocator: std.mem.Allocator, size: Size) !Canvas {
        const data = try allocator.alloc(u8, size.width * size.height * 3);
        return Canvas{ .image_data = data, .image_size = size };
    }

    pub fn deinit(self: Canvas, allocator: std.mem.Allocator) void {
        allocator.free(self.image_data);
    }

    pub fn view(self: Canvas, region: Region) !CanvasView {
        const self_region = self.image_size.toRegion();
        const contains = self_region.containsRegion(region);
        if (!contains) {
            return error.CanvasOutOfRegion;
        }
        return CanvasView{ .canvas = self, .region = region };
    }

    pub fn fillRgb(self: Canvas, color: Rgb) void {
        var i: usize = 0;
        while (i < self.image_data.len) : (i += 3) {
            self.image_data[i + 0] = color.r;
            self.image_data[i + 1] = color.g;
            self.image_data[i + 2] = color.b;
        }
    }

    pub fn drawSprite(self: Canvas, offset: Position, sprite: Sprite) void {
        var canvas_view = self.view(self.image_size.toRegion()) catch unreachable;
        canvas_view.drawSprite(offset, sprite);
    }
};

pub const CanvasView = struct {
    canvas: Canvas,
    region: Region,

    pub fn drawSprite(self: CanvasView, offset: Position, sprite: Sprite) void {
        const w = @intCast(i32, self.canvas.image_size.width);
        var canvas_offset = offset;
        canvas_offset.x += self.region.position.x;
        canvas_offset.y += self.region.position.y;

        var pixels = sprite.pixels();
        while (pixels.next()) |pixel| {
            var canvas_pos = canvas_offset;
            canvas_pos.x += pixel.position.x;
            canvas_pos.y += pixel.position.y;

            if (self.region.containsPosition(canvas_pos)) {
                const i = @intCast(usize, canvas_pos.y * w + canvas_pos.x) * 3;

                const rgb = pixel.rgba.toAlphaBlendRgb(.{ //
                    .r = self.canvas.image_data[i + 0],
                    .g = self.canvas.image_data[i + 1],
                    .b = self.canvas.image_data[i + 2],
                });
                self.canvas.image_data[i + 0] = rgb.r;
                self.canvas.image_data[i + 1] = rgb.g;
                self.canvas.image_data[i + 2] = rgb.b;
            }
        }
    }
};

pub const LogicalWindow = struct {
    canvas_region: Region,
    logical_window_size: Size,
    actual_window_size: Size,

    pub fn new(canvas_size: Size) LogicalWindow {
        return .{ //
            .canvas_region = canvas_size.toRegion(),
            .logical_window_size = canvas_size,
            .actual_window_size = Size.square(0),
        };
    }

    pub fn handleEvent(self: *LogicalWindow, event: Event) Event {
        // TODO: handle mouse event
        switch (event) {
            .window_redraw_needed => |e| {
                self.handleWindowSizeChange(e.window.redrawNeeded.size);
            },
            else => {},
        }
        return event;
    }

    fn handleWindowSizeChange(self: *LogicalWindow, size: Size) void {
        self.actual_window_size = size;
        self.logical_window_size = self.canvas_region.size;

        var canvas = self.canvas_region.size;
        var actual_window = self.actual_window_size;
        if (canvas.aspectRatio() > actual_window.aspectRatio()) {
            const scale = @intToFloat(f32, canvas.width) / @intToFloat(f32, actual_window.width);
            self.logical_window_size.height =
                @floatToInt(u32, @round(@intToFloat(f32, actual_window.height) * scale));
            const padding = (self.logical_window_size.height - canvas.height) / 2;
            self.canvas_region.position = xy(0, @intCast(i32, padding));
        } else if (canvas.aspectRatio() < actual_window.aspectRatio()) {
            const scale = @intToFloat(f32, canvas.height) / @intToFloat(f32, actual_window.height);
            self.logical_window_size.width =
                @floatToInt(u32, @round(@intToFloat(f32, actual_window.width) * scale));
            const padding = (self.logical_window_size.width - canvas.width) / 2;
            self.canvas_region.position = xy(@intCast(i32, padding), 0);
        } else {
            self.canvas_region.position = Position.ORIGIN;
        }
    }
};

pub const BACKGROUND: Sprite = createSprite(IMG_BACKGROUND.*[0..], square(384), xy(0, 0), square(384));

pub const ButtonState = enum { normal, focused, pressed, clicked };

pub const ButtonSprites = struct { normal: Sprite, focused: Sprite, pressed: Sprite };

pub const ButtonWidget = struct { //
    state: ButtonState,
    sprites: ButtonSprites,

    pub fn new(sprites: ButtonSprites) ButtonWidget {
        return .{ .state = ButtonState.normal, .sprites = sprites };
    }

    pub fn currentSprite(self: ButtonWidget) Sprite {
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

pub const IMG_BUTTONS = @embedFile("../assets/buttons.rawrgba");

pub const PLAY_BUTTON_NORMAL: Sprite = createSprite(IMG_BUTTONS.*[0..], wh(480, 132), xy(160, 0), wh(160, 33));
pub const PLAY_BUTTON_FOCUSED: Sprite = createSprite(IMG_BUTTONS.*[0..], wh(480, 132), xy(320, 0), wh(160, 33));
pub const PLAY_BUTTON_PRESSED: Sprite = createSprite(IMG_BUTTONS.*[0..], wh(480, 132), xy(0, 0), wh(160, 33));

pub const PLAY_BUTTON_WIDGET: ButtonWidget = ButtonWidget.new(.{
    .normal = PLAY_BUTTON_NORMAL,
    .focused = PLAY_BUTTON_FOCUSED,
    .pressed = PLAY_BUTTON_PRESSED,
});

pub const EXIT_BUTTON_NORMAL: Sprite = createSprite(IMG_BUTTONS.*[0..], wh(480, 132), xy(160, 33), wh(160, 33));
pub const EXIT_BUTTON_FOCUSED: Sprite = createSprite(IMG_BUTTONS.*[0..], wh(480, 132), xy(320, 33), wh(160, 33));
pub const EXIT_BUTTON_PRESSED: Sprite = createSprite(IMG_BUTTONS.*[0..], wh(480, 132), xy(0, 33), wh(160, 33));

pub const EXIT_BUTTON_WIDGET: ButtonWidget = ButtonWidget.new(.{
    .normal = EXIT_BUTTON_NORMAL,
    .focused = EXIT_BUTTON_FOCUSED,
    .pressed = EXIT_BUTTON_PRESSED,
});
