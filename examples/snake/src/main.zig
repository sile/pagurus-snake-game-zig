const std = @import("std");
const assets = @import("assets.zig");
const SnakeGame = @import("game.zig").SnakeGame;
const System = @import("system.zig").System;

var GBA = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = GBA.allocator();

export fn gameNew() *anyopaque {
    //const allocator = GBA.allocator();
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

const WindowEvent = struct { redrawNeeded: struct { size: struct { width: u32, height: u32 } } };

const Event = struct { window: WindowEvent };

export fn gameHandleEvent(game: *anyopaque, event_bytes_ptr: *anyopaque, data_ptr: ?*anyopaque) ?*anyopaque {
    var system = System{};
    system.consoleLog("gameHandleEvent: 0");

    const event_bytes = @ptrCast(*Bytes, @alignCast(@typeInfo(*Bytes).Pointer.alignment, event_bytes_ptr));
    system.consoleLog(event_bytes.inner);

    var stream = std.json.TokenStream.init(event_bytes.inner);
    _ = std.json.parse(Event, &stream, .{}) catch {
        system.consoleLog("failed to parse JSON");
        @panic("failed to parse Event JSON (TODO");
    };
    system.consoleLog("gameHandleEvent: 1");

    _ = game;
    _ = data_ptr;
    return null;
    //unreachable;
}

// TODO: move
const Bytes = struct { inner: []u8 };

export fn memoryAllocateBytes(size: usize) ?*anyopaque {
    var system = System{};
    system.consoleLog("memoryAllocateBytes");

    var inner = allocator.alloc(u8, size) catch return null;
    var bytes = allocator.create(Bytes) catch return null;
    bytes.inner = inner;

    return bytes;
}

export fn memoryBytesOffset(bytes_ptr: *anyopaque) *u8 {
    // const bytes = @ptrCast(*[]u8, @alignCast(@typeInfo(*[]u8).Pointer.alignment, bytes_ptr));
    // return @ptrCast(*u8, bytes.ptr);
    const bytes = @ptrCast(*Bytes, @alignCast(@typeInfo(*Bytes).Pointer.alignment, bytes_ptr));
    return @ptrCast(*u8, bytes.inner.ptr);
}

export fn memoryBytesLen(bytes_ptr: *anyopaque) usize {
    const bytes = @ptrCast(*[]u8, @alignCast(@typeInfo(*[]u8).Pointer.alignment, bytes_ptr));
    return bytes.len;
}

export fn memoryFreeBytes(bytes_ptr: *anyopaque) void {
    var system = System{};
    system.consoleLog("memoryFreeBytes");

    //    const allocator = GBA.allocator();
    const bytes = @ptrCast(*[]u8, @alignCast(@typeInfo(*[]u8).Pointer.alignment, bytes_ptr));
    allocator.free(bytes.*);
}
