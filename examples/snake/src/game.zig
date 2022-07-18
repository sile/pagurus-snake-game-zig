const System = @import("system.zig").System;
const EventWithData = @import("event.zig").EventWithData;

pub const SnakeGame = struct {
    x: i32,

    pub fn new() SnakeGame {
        return SnakeGame{ .x = 10 };
    }

    pub fn initialize(self: *SnakeGame) !void {
        _ = self;
    }

    pub fn handleEvent(self: *SnakeGame, event: EventWithData) !bool {
        _ = self;
        _ = event;
        return true;
    }
};
