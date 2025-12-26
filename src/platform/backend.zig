/// Platform backend interface/contract for window and rendering

pub const Size = struct {
    w: usize,
    h: usize,
};

pub const Backend = struct {
    ctx: *anyopaque,

    poll: *const fn (*anyopaque) bool,
    present: *const fn (*anyopaque) void,

    resizeFramebuffer: *const fn (
        ctx: *anyopaque,
        pixels: []u32,
        w: usize,
        h: usize,
    ) void,

    getSize: *const fn (*anyopaque) Size,
    deinit: *const fn (*anyopaque) void,
};
