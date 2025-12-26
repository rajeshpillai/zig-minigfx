const Backend = @import("platform-backend").Backend;
const Size = @import("platform-backend").Size;

const X11 = @import("minigfx-x11");

inline fn win(ctx: *anyopaque) *X11.X11Window {
    return @as(*X11.X11Window, @ptrCast(@alignCast(ctx)));
}

pub fn createBackend(window: *X11.X11Window) Backend {
    return .{
        .ctx = window,
        .poll = poll,
        .present = present,
        .resizeFramebuffer = resizeFramebuffer,
        .getSize = getSize,
        .deinit = deinit,
    };
}

fn poll(ctx: *anyopaque) bool {
    return win(ctx).poll();
}

fn present(ctx: *anyopaque) void {
    win(ctx).present();
}

fn resizeFramebuffer(
    ctx: *anyopaque,
    pixels: []u32,
    w: usize,
    h: usize,
) void {
    win(ctx).resizeFramebuffer(pixels, w, h);
}

fn getSize(ctx: *anyopaque) Size {
    const wptr = win(ctx);
    return .{ .w = wptr.width, .h = wptr.height };
}

fn deinit(ctx: *anyopaque) void {
    win(ctx).deinit();
}
