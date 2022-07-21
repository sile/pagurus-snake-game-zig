const std = @import("std");
const Size = @import("spatial.zig").Size;
const Position = @import("spatial.zig").Position;
const Region = @import("spatial.zig").Region;

pub const Rgb = struct {
    const Self = @This();

    r: u8,
    g: u8,
    b: u8,

    pub const BLACK: Rgb = .{ .r = 0, .g = 0, .b = 0 };

    pub fn alpha(self: Self, a: u8) Rgba {
        return .{ .r = self.r, .g = self.g, .b = self.b, .a = a };
    }
};

pub const Rgba = struct {
    const Self = @This();

    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn toAlphaBlendRgb(self: Rgba, dst: Rgb) Rgb {
        return .{
            .r = blend(self.r, dst.r, self.a),
            .g = blend(self.g, dst.g, self.a),
            .b = blend(self.b, dst.b, self.a),
        };
    }
};

fn blend(src: u16, dst: u16, alpha: u16) u8 {
    const v = src * alpha + dst * (255 - alpha);
    return @intCast(u8, v / 255);
}

pub const Sprite = struct {
    const Self = @This();

    image_data: []const u8, // RGBA
    image_size: Size,
    sprite_region: Region,

    pub fn create(image_data: []const u8, image_size: Size, sprite_position: Position, sprite_size: Size) Self {
        return .{
            .image_data = image_data,
            .image_size = image_size,
            .sprite_region = .{ .position = sprite_position, .size = sprite_size },
        };
    }

    pub fn pixels(self: Self) PixelIterator {
        return .{ .sprite = self, .position = self.sprite_region.position };
    }
};

pub const PixelIterator = struct {
    const Self = @This();

    pub const Item = struct { position: Position, rgba: Rgba };

    sprite: Sprite,
    position: Position,

    pub fn next(self: *Self) ?PixelIterator.Item {
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

pub const Canvas = struct {
    const Self = @This();

    data: []u8, // RGB
    size: Size,

    pub fn new(allocator: std.mem.Allocator, size: Size) !Self {
        const data = try allocator.alloc(u8, size.width * size.height * 3);
        return Canvas{ .data = data, .size = size };
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn view(self: Self, region: Region) !CanvasView {
        const self_region = self.size.toRegion();
        const contains = self_region.containsRegion(region);
        if (!contains) {
            return error.CanvasOutOfRegion;
        }
        return CanvasView{ .canvas = self, .region = region };
    }

    pub fn fillRgb(self: Self, color: Rgb) void {
        var i: usize = 0;
        while (i < self.data.len) : (i += 3) {
            self.data[i + 0] = color.r;
            self.data[i + 1] = color.g;
            self.data[i + 2] = color.b;
        }
    }

    pub fn drawSprite(self: Self, offset: Position, sprite: Sprite) void {
        var canvas_view = self.view(self.size.toRegion()) catch unreachable;
        canvas_view.drawSprite(offset, sprite);
    }
};

pub const CanvasView = struct {
    const Self = @This();

    canvas: Canvas,
    region: Region,

    pub fn fillRgba(self: Self, color: Rgba) void {
        const w = @intCast(i32, self.canvas.size.width);

        const start = self.region.startPosition();
        const end = self.region.endPosition();
        var y = start.y;
        while (y < end.y) : (y += 1) {
            var x = start.x;
            while (x < end.x) : (x += 1) {
                const i = @intCast(usize, y * w + x) * 3;
                self.updatePixel(i, color);
            }
        }
    }

    pub fn drawSprite(self: Self, offset: Position, sprite: Sprite) void {
        const w = @intCast(i32, self.canvas.size.width);
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
                self.updatePixel(i, pixel.rgba);
            }
        }
    }

    fn updatePixel(self: Self, i: usize, rgba: Rgba) void {
        const rgb = rgba.toAlphaBlendRgb(.{
            .r = self.canvas.data[i + 0],
            .g = self.canvas.data[i + 1],
            .b = self.canvas.data[i + 2],
        });
        self.canvas.data[i + 0] = rgb.r;
        self.canvas.data[i + 1] = rgb.g;
        self.canvas.data[i + 2] = rgb.b;
    }
};
