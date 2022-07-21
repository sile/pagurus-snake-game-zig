pub const Size = struct {
    const Self = @This();

    width: u32,
    height: u32,

    pub fn equal(self: Self, other: Self) bool {
        return self.width == other.width and self.height == other.height;
    }

    pub fn toRegion(self: Self) Region {
        return .{ .position = Position.ORIGIN, .size = self };
    }

    pub fn aspectRatio(self: Self) f32 {
        return @intToFloat(f32, self.width) / @intToFloat(f32, self.height);
    }

    pub fn square(size: usize) Self {
        return .{ .width = size, .height = size };
    }
    pub fn wh(width: u32, height: u32) Self {
        return .{ .width = width, .height = height };
    }
};

pub const Position = struct {
    const Self = @This();

    x: i32,
    y: i32,

    pub const ORIGIN: Self = .{ .x = 0, .y = 0 };

    fn isLessThanOrEqualTo(self: Self, other: Self) bool {
        return self.x <= other.x and self.y <= other.y;
    }

    pub fn equal(self: Self, other: Self) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn xy(x: i32, y: i32) Self {
        return .{ .x = x, .y = y };
    }
};

pub const Region = struct {
    const Self = @This();

    position: Position,
    size: Size,

    pub fn startPosition(self: Self) Position {
        return self.position;
    }

    pub fn endPosition(self: Self) Position {
        return .{
            .x = self.position.x + @intCast(i32, self.size.width),
            .y = self.position.y + @intCast(i32, self.size.height),
        };
    }

    pub fn containsRegion(self: Self, other: Self) bool {
        return self.startPosition().isLessThanOrEqualTo(other.startPosition()) and
            other.endPosition().isLessThanOrEqualTo(self.endPosition());
    }

    pub fn containsPosition(self: Self, pos: Position) bool {
        return self.containsRegion(.{ .position = pos, .size = Size.wh(0, 0) });
    }
};
