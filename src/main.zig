const std = @import("std");
const system = @import("system.zig");
const Event = @import("event.zig").Event;
const SnakeGame = @import("game.zig").SnakeGame;

var GBA = std.heap.GeneralPurposeAllocator(.{}){};
pub const ALLOCATOR = GBA.allocator();

//
// WebAssembly API
//

export fn gameNew() *anyopaque {
    const game = ALLOCATOR.create(SnakeGame) catch @panic("failed to allocate SnakeGame");
    return game;
}

export fn gameInitialize(game_ptr: *anyopaque) ?*anyopaque {
    const game = @ptrCast(*SnakeGame, @alignCast(@typeInfo(*SnakeGame).Pointer.alignment, game_ptr));
    game.initialize() catch abort("failed to initialize the game");
    return null; // no error
}

export fn gameHandleEvent(game_ptr: *anyopaque, event_bytes_ptr: *anyopaque, data_ptr: ?*anyopaque) ?*anyopaque {
    const event_bytes = @ptrCast(*Bytes, @alignCast(@typeInfo(*Bytes).Pointer.alignment, event_bytes_ptr));
    defer memoryFreeBytes(event_bytes_ptr);

    const event = Event.parseJson(event_bytes.inner, .{ .ignore_unknown_fields = true }) orelse {
        system.consoleLogFmt("failed to parse event JSON (ignored): {s}", .{event_bytes.inner});
        return null;
    };

    const game = @ptrCast(*SnakeGame, @alignCast(@typeInfo(*SnakeGame).Pointer.alignment, game_ptr));
    var do_continue: bool = undefined;
    if (data_ptr) |ptr| {
        const data = @ptrCast(*Bytes, @alignCast(@typeInfo(*Bytes).Pointer.alignment, ptr));
        defer memoryFreeBytes(ptr);
        do_continue = game.handleEvent(.{ .event = event, .data = data.inner }) catch abort("failed to handle event");
    } else {
        do_continue = game.handleEvent(.{ .event = event, .data = null }) catch abort("failed to handle event");
    }

    if (do_continue) {
        return null;
    } else {
        var inner = ALLOCATOR.alloc(u8, "null".len) catch return null;
        var bytes = ALLOCATOR.create(Bytes) catch return null;
        bytes.inner = inner;
        std.mem.copy(u8, bytes.inner, "null");
        return bytes;
    }
}

export fn memoryAllocateBytes(size: usize) ?*anyopaque {
    var inner = ALLOCATOR.alloc(u8, size) catch return null;
    var bytes = ALLOCATOR.create(Bytes) catch return null;
    bytes.inner = inner;

    return bytes;
}

export fn memoryBytesOffset(bytes_ptr: *anyopaque) *u8 {
    const bytes = @ptrCast(*Bytes, @alignCast(@typeInfo(*Bytes).Pointer.alignment, bytes_ptr));
    return @ptrCast(*u8, bytes.inner.ptr);
}

export fn memoryBytesLen(bytes_ptr: *anyopaque) usize {
    const bytes = @ptrCast(*Bytes, @alignCast(@typeInfo(*Bytes).Pointer.alignment, bytes_ptr));
    return bytes.inner.len;
}

export fn memoryFreeBytes(bytes_ptr: *anyopaque) void {
    const bytes = @ptrCast(*Bytes, @alignCast(@typeInfo(*Bytes).Pointer.alignment, bytes_ptr));
    ALLOCATOR.free(bytes.inner);
    ALLOCATOR.destroy(bytes);
}

const Bytes = struct { inner: []u8 };

fn abort(message: []const u8) void {
    system.consoleLog(message);
    @panic(message);
}
