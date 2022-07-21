const std = @import("std");
const Size = @import("assets.zig").Size;

extern fn systemVideoDraw(data: *const u8, data_len: usize, width: u32) void;

pub fn videoDraw(image_data: []const u8, image_size: Size) void {
    systemVideoDraw(@ptrCast(*const u8, image_data.ptr), image_data.len, image_size.width);
}

extern fn systemConsoleLog(message: *const u8, message_len: usize) void;

pub fn consoleLog(message: []const u8) void {
    systemConsoleLog(@ptrCast(*const u8, message.ptr), message.len);
}

pub fn consoleLogFmt(comptime fmt: []const u8, args: anytype) void {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    if (std.fmt.allocPrint(allocator, fmt, args) catch null) |message| {
        consoleLog(message);
    }
}

extern fn systemClockGameTime() f64;

pub fn clockGameTime() f64 {
    return systemClockGameTime();
}

extern fn systemClockUnixTime() f64;

pub fn clockUnixTime() f64 {
    return systemClockUnixTime();
}

extern fn systemClockSetTimeout(duration: f64) u64;

pub fn clockSetTimeout(duration: f64) u64 {
    return systemClockSetTimeout(duration);
}
