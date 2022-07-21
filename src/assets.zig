const spatial = @import("spatial.zig");
const wh = spatial.Size.wh;
const square = spatial.Size.square;
const xy = spatial.Position.xy;
const Sprite = @import("image.zig").Sprite;

pub const IMG_BACKGROUND = @embedFile("../assets/background.rawrgba");
pub const BACKGROUND = Sprite.create(IMG_BACKGROUND.*[0..], square(384), xy(0, 0), square(384));

pub const IMG_BUTTONS = @embedFile("../assets/buttons.rawrgba");
pub const PLAY_BUTTON_NORMAL: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(160, 0), wh(160, 33));
pub const PLAY_BUTTON_FOCUSED: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(320, 0), wh(160, 33));
pub const PLAY_BUTTON_PRESSED: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(0, 0), wh(160, 33));

pub const EXIT_BUTTON_NORMAL: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(160, 33), wh(160, 33));
pub const EXIT_BUTTON_FOCUSED: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(320, 33), wh(160, 33));
pub const EXIT_BUTTON_PRESSED: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(0, 33), wh(160, 33));

pub const RETRY_BUTTON_NORMAL: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(160, 66), wh(160, 33));
pub const RETRY_BUTTON_FOCUSED: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(320, 66), wh(160, 33));
pub const RETRY_BUTTON_PRESSED: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(0, 66), wh(160, 33));

pub const TITLE_BUTTON_NORMAL: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(160, 99), wh(160, 33));
pub const TITLE_BUTTON_FOCUSED: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(320, 99), wh(160, 33));
pub const TITLE_BUTTON_PRESSED: Sprite = Sprite.create(IMG_BUTTONS.*[0..], wh(480, 132), xy(0, 99), wh(160, 33));

pub const IMG_ITEMS = @embedFile("../assets/items.rawrgba");
pub const SNAKE_HEAD: Sprite = Sprite.create(IMG_ITEMS.*[0..], wh(96, 32), xy(0, 0), wh(32, 32));
pub const SNAKE_TAIL: Sprite = Sprite.create(IMG_ITEMS.*[0..], wh(96, 32), xy(32, 0), wh(32, 32));
pub const APPLE: Sprite = Sprite.create(IMG_ITEMS.*[0..], wh(96, 32), xy(64, 0), wh(32, 32));

pub const IMG_CHARS_LARGE = @embedFile("../assets/chars-large.rawrgba");
pub const STRING_SNAKE: Sprite = Sprite.create(IMG_CHARS_LARGE.*[0..], wh(256, 192), xy(0, 0), wh(256, 64));
pub const STRING_GAME: Sprite = Sprite.create(IMG_CHARS_LARGE.*[0..], wh(256, 192), xy(0, 64), wh(256, 64));
pub const STRING_OVER: Sprite = Sprite.create(IMG_CHARS_LARGE.*[0..], wh(256, 192), xy(0, 128), wh(256, 64));

pub const IMG_CHARS_SMALL = @embedFile("../assets/chars-small.rawrgba");
pub const STRING_HIGH_SCORE: Sprite = Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(0, 0), wh(112, 16));
pub const NUM_SMALL: [10]Sprite = .{
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(0, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(10, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(20, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(30, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(40, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(50, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(60, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(70, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(80, 16), wh(10, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(90, 16), wh(10, 16)),
};
pub const NUM_LARGE: [10]Sprite = .{
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(0, 32), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(16, 32), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(32, 32), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(48, 32), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(64, 32), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(0, 48), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(16, 48), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(32, 48), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(48, 48), wh(16, 16)),
    Sprite.create(IMG_CHARS_SMALL.*[0..], wh(112, 64), xy(64, 48), wh(16, 16)),
};
