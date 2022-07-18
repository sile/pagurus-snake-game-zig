const std = @import("std");
const assets = @import("assets.zig");
const SnakeGame = @import("game.zig").SnakeGame;
const System = @import("system.zig").System;

export fn gameNew() *anyopaque {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const game = allocator.create(SnakeGame) catch @panic("failed to allocate SnakeGame");
    return @ptrCast(*anyopaque, game);
}

export fn gameInitialize(game_ptr: *anyopaque) ?*anyopaque {
    const game = @ptrCast(*SnakeGame, @alignCast(@typeInfo(*SnakeGame).Pointer.alignment, game_ptr));
    var system = System{};

    system.consoleLog("gameInitialize: 0");
    game.initialize(&system) catch @panic("failed to initialize the game (TODO)");
    system.consoleLog("gameInitialize: 1");
    return null; // no error
}

export fn gameHandleEvent(game: *anyopaque, event_bytes_ptr: *anyopaque, data_ptr: *anyopaque) ?*anyopaque {
    var system = System{};
    system.consoleLog("gameHandleEvent: 0");
    _ = game;
    _ = event_bytes_ptr;
    _ = data_ptr;
    return null;
    //unreachable;
}

export fn memoryAllocateBytes(size: usize) ?*anyopaque {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var bytes = allocator.alloc(u8, size) catch return null;
    return &bytes;
}

export fn memoryBytesOffset(bytes_ptr: *anyopaque) *u8 {
    const bytes = @ptrCast(*[]u8, @alignCast(@typeInfo(*[]u8).Pointer.alignment, bytes_ptr));
    return @ptrCast(*u8, bytes.ptr);
}

export fn memoryBytesLen(bytes_ptr: *anyopaque) usize {
    const bytes = @ptrCast(*[]u8, @alignCast(@typeInfo(*[]u8).Pointer.alignment, bytes_ptr));
    return bytes.len;
}

export fn memoryFreeBytes(bytes_ptr: *anyopaque) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bytes = @ptrCast(*[]u8, @alignCast(@typeInfo(*[]u8).Pointer.alignment, bytes_ptr));
    allocator.free(bytes.*);
}
