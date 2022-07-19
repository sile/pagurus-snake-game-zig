pub const IMG_BACKGROUND = @embedFile("../assets/background.rawrgba");

// TODO: move
pub const Size = struct { width: u32, height: u32 };
pub const Position = struct { x: i32, y: i32 };
pub const Region = struct { position: Position, size: Size };

// TODO: move
pub const Sprite = struct { image_data: []const u8, image_size: Size, sprite_region: Region };

pub fn createSprite(image_data: []const u8, image_size: Size, sprite_position: Position, sprite_size: Size) Sprite {
    return .{ .image_data = image_data, .image_size = image_size, .sprite_region = .{ .position = sprite_position, .size = sprite_size } };
}

pub fn xy(x: i32, y: i32) Position {
    return .{ .x = x, .y = y };
}

pub fn wh(width: u32, height: u32) Size {
    return .{ .width = width, .height = height };
}

pub fn square(size: u32) Size {
    return wh(size, size);
}

pub const BACKGROUND: Sprite = createSprite(IMG_BACKGROUND.*[0..], square(384), xy(0, 0), square(384));
