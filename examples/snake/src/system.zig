const std = @import("std");

extern fn systemConsoleLog(message: *const u8, message_len: usize) void;

pub fn consoleLog(message: []const u8) void {
    systemConsoleLog(@ptrCast(*const u8, message.ptr), message.len);
}
