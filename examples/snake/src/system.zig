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
