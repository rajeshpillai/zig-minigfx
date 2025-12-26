const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
});

pub const Key = enum {
    escape,
};

pub const X11Window = struct {
    display: *c.Display,
    window: c.Window,
    gc: c.GC,
    image: *c.XImage,
    width: usize,
    height: usize,
    running: bool = true,
    last_key: ?Key = null,

    pub fn init(
        width: usize,
        height: usize,
        title: []const u8,
        pixels: []u32,
    ) !X11Window {
        const display = c.XOpenDisplay(null) orelse
            return error.XOpenDisplayFailed;

        const screen = c.DefaultScreen(display);
        const root = c.RootWindow(display, screen);

        const window = c.XCreateSimpleWindow(
            display,
            root,
            0,
            0,
            @intCast(width),
            @intCast(height),
            1,
            c.BlackPixel(display, screen),
            c.WhitePixel(display, screen),
        );

        _ = c.XStoreName(display, window, title.ptr);
        _ = c.XSelectInput(display, window, c.ExposureMask | c.KeyPressMask);
        _ = c.XMapWindow(display, window);

        const gc = c.XCreateGC(display, window, 0, null);

        const image = c.XCreateImage(
            display,
            c.DefaultVisual(display, screen),
            24,
            c.ZPixmap,
            0,
            @ptrCast(pixels.ptr),
            @intCast(width),
            @intCast(height),
            32,
            0,
        );

        return .{
            .display = display,
            .window = window,
            .gc = gc,
            .image = image,
            .width = width,
            .height = height,
        };
    }

    /// Returns false when the app should exit
    pub fn poll(self: *X11Window) bool {
        self.last_key = null;

        while (c.XPending(self.display) > 0) {
            var event: c.XEvent = undefined;
            _ = c.XNextEvent(self.display, &event);

            switch (event.type) {
                c.KeyPress => {
                    const keycode = event.xkey.keycode;

                    // X11 ESC is usually keycode 9
                    if (keycode == 9) {
                        self.last_key = .escape;
                        self.running = false;
                    }
                },
                c.ClientMessage => {
                    self.running = false;
                },
                else => {},
            }
        }
        return self.running;
    }

    pub fn present(self: *X11Window) void {
        _ = c.XPutImage(
            self.display,
            self.window,
            self.gc,
            self.image,
            0,
            0,
            0,
            0,
            @intCast(self.width),
            @intCast(self.height),
        );
        _ = c.XFlush(self.display);
    }

    pub fn deinit(self: *X11Window) void {
        _ = c.XDestroyWindow(self.display, self.window);
        _ = c.XCloseDisplay(self.display);
    }
};
