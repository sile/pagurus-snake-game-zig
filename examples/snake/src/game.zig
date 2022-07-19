const system = @import("system.zig");
const EventWithData = @import("event.zig").EventWithData;
const assets = @import("assets.zig");
const Canvas = assets.Canvas;
const Size = assets.Size;
const Position = assets.Position;
const LogicalWindow = assets.LogicalWindow;
const ALLOCATOR = @import("main.zig").ALLOCATOR;

pub const SnakeGame = struct {
    logical_window: LogicalWindow,

    pub fn initialize(self: *SnakeGame) !void {
        const canvas_size = Size.square(384);
        self.logical_window = LogicalWindow.new(canvas_size);
    }

    pub fn handleEvent(self: *SnakeGame, event_with_data: EventWithData) !bool {
        const event = self.logical_window.handleEvent(event_with_data.event);
        switch (event) {
            .terminating => {
                return false;
            },
            .window_redraw_needed => {
                self.drawVideoFrame() catch @panic("TODO");
            },
            else => {},
        }
        return true;
    }

    fn drawVideoFrame(self: SnakeGame) !void {
        var canvas = try Canvas.new(ALLOCATOR, self.logical_window.logical_window_size);
        defer canvas.deinit(ALLOCATOR);

        canvas.fillRgb(.{ .r = 0, .g = 0, .b = 0 });
        var canvas_view = try canvas.view(self.logical_window.canvas_region);
        canvas_view.drawSprite(Position.ORIGIN, assets.BACKGROUND);

        system.videoDraw(canvas.image_data, canvas.image_size);
    }
};
