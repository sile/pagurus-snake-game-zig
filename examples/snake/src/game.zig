const System = @import("system.zig").System;

pub const SnakeGame = struct {
    x: i32,

    pub fn new() SnakeGame {
        return SnakeGame{ .x = 10 };
    }

    pub fn initialize(self: *SnakeGame, system: *System) !void {
        _ = self;
        _ = system;
    }
};
