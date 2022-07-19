const system = @import("system.zig");
const EventWithData = @import("event.zig").EventWithData;
const assets = @import("assets.zig");
const Canvas = assets.Canvas;
const Size = assets.Size;
const Position = assets.Position;

// TODO: rename
var IMAGE_DATA: [384 * 384 * 3]u8 = undefined;

pub const SnakeGame = struct {
    canvas: Canvas,

    pub fn initialize(self: *SnakeGame) !void {
        const canvas_size = Size.square(384);
        self.canvas = .{ .image_data = IMAGE_DATA[0..], .image_size = canvas_size };
        self.canvas.drawSprite(Position.ORIGIN, assets.BACKGROUND);
        system.videoDraw(self.canvas.image_data, self.canvas.image_size);
    }

    pub fn handleEvent(self: *SnakeGame, event: EventWithData) !bool {
        _ = self;
        _ = event;
        return true;
    }
};
