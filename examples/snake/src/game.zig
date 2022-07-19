const system = @import("system.zig");
const EventWithData = @import("event.zig").EventWithData;
const assets = @import("assets.zig");

pub const SnakeGame = struct {
    x: i32,

    pub fn new() SnakeGame {
        return SnakeGame{ .x = 10 };
    }

    pub fn initialize(self: *SnakeGame) !void {
        _ = self;

        // TODO: convert to RGB
        system.videoDraw(assets.BACKGROUND.image_data, assets.BACKGROUND.image_size);
    }

    pub fn handleEvent(self: *SnakeGame, event: EventWithData) !bool {
        _ = self;
        _ = event;
        return true;
    }
};
