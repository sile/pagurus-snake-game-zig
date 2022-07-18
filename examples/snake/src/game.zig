const System = @import("system.zig").System;
const EventWithData = @import("event.zig").EventWithData;

pub const SnakeGame = struct {
    x: i32,

    pub fn new() SnakeGame {
        return SnakeGame{ .x = 10 };
    }

    pub fn initialize(self: *SnakeGame, system: *System) !void {
        _ = self;
        _ = system;
    }

    pub fn handleEvent(self: *SnakeGame, system: *System, event: EventWithData) !bool {
        _ = self;
        _ = system;
        _ = event;
        return true;
    }
};
