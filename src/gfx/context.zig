const std = @import("std");

const Surface = @import("minigfx-core").Surface;
const X11 = @import("minigfx-x11");

pub const Context = struct {
    allocator: std.mem.Allocator,
    surface: Surface,
    window: X11.X11Window,

    pub fn init(
        allocator: std.mem.Allocator,
        win_width: usize,
        win_height: usize,
        title: []const u8,
    ) !Context {
        var surface = try Surface.init(allocator, win_width, win_height);
        errdefer surface.deinit(allocator);

        var window = try X11.X11Window.init(
            win_width,
            win_height,
            title,
            surface.pixels,
        );
        errdefer window.deinit();

        return .{
            .allocator = allocator,
            .surface = surface,
            .window = window,
        };
    }

    pub fn deinit(self: *Context) void {
        self.window.deinit();
        self.surface.deinit(self.allocator);
    }

    pub fn poll(self: *Context) bool {
        return self.window.poll();
    }

    pub fn beginFrame(self: *Context) void {
        _ = self;
    }

    pub fn endFrame(self: *Context) void {
        self.window.present();
    }

    // ---- Drawing helpers ----

    pub fn clear(self: *Context, color: u32) void {
        self.surface.clear(color);
    }

    pub fn fillRect(
        self: *Context,
        x: i32,
        y: i32,
        w: i32,
        h: i32,
        color: u32,
    ) void {
        self.surface.fillRectSigned(x, y, w, h, color);
    }

    pub fn width(self: *Context) usize {
        return self.surface.width;
    }
};
