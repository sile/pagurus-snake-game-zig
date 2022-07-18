const std = @import("std");

extern fn systemConsoleLog(message: *const u8, message_len: usize) void;

pub const System = struct {
    pub fn consoleLog(self: System, message: []const u8) void {
        _ = self;
        systemConsoleLog(@ptrCast(*const u8, message.ptr), message.len);
    }
};
