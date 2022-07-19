const std = @import("std");
const Size = @import("assets.zig").Size;

pub const ActionId = u64;

pub const EventWithData = struct { event: Event, data: ?[]u8 };

pub const Event = union(enum) {
    terminating: void,
    timeout: TimeoutEvent,
    key_down: KeyDownEvent,
    key_up: KeyUpEvent,
    //mouse: MouseEvent,
    window_redraw_needed: WindowRedrawNeededEvent,
    state_saved: StateSavedEvent,
    state_loaded: StateLoadedEvent,
    state_deleted: StateDeletedEvent,
};

pub const TimeoutEvent = struct { timeout: struct { id: ActionId } };

pub const KeyDownEvent = struct { key: struct { down: struct { key: Key } } };

pub const KeyUpEvent = struct { key: struct { up: struct { key: Key } } };

pub const MouseEvent = struct {};

pub const WindowRedrawNeededEvent = struct { window: struct { redrawNeeded: struct { size: Size } } };

pub const StateSavedEvent = struct { state: struct { saved: struct { id: ActionId } } };

pub const StateLoadedEvent = struct { state: struct { loaded: struct { id: ActionId } } };

pub const StateDeletedEvent = struct { state: struct { deleted: struct { id: ActionId } } };

pub const Key = enum {
    @"return",
    left,
    right,
    up,
    down,
};

pub fn parseJson(json: []u8, options: std.json.ParseOptions) ?Event {
    if (std.mem.startsWith(u8, json, "\"terminating\"")) {
        return Event{ .terminating = void{} };
    }

    var stream = std.json.TokenStream.init(json);
    if (std.json.parse(TimeoutEvent, &stream, options) catch null) |event| {
        return Event{ .timeout = event };
    }

    stream = std.json.TokenStream.init(json);
    if (std.json.parse(KeyDownEvent, &stream, options) catch null) |event| {
        return Event{ .key_down = event };
    }

    stream = std.json.TokenStream.init(json);
    if (std.json.parse(KeyUpEvent, &stream, options) catch null) |event| {
        return Event{ .key_up = event };
    }

    stream = std.json.TokenStream.init(json);
    if (std.json.parse(WindowRedrawNeededEvent, &stream, options) catch null) |event| {
        return Event{ .window_redraw_needed = event };
    }

    stream = std.json.TokenStream.init(json);
    if (std.json.parse(StateSavedEvent, &stream, options) catch null) |event| {
        return Event{ .state_saved = event };
    }

    stream = std.json.TokenStream.init(json);
    if (std.json.parse(StateLoadedEvent, &stream, options) catch null) |event| {
        return Event{ .state_loaded = event };
    }

    stream = std.json.TokenStream.init(json);
    if (std.json.parse(StateDeletedEvent, &stream, options) catch null) |event| {
        return Event{ .state_deleted = event };
    }

    return null;
}
