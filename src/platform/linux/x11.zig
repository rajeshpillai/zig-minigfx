const std = @import("std");

const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
});

pub const X11Window = struct {
    display: *c.Display,
    window: c.Window,
    gc: c.GC,

    // Cached screen info (IMPORTANT: avoids macro calls later)
    screen: c_int,
    visual: *c.Visual,
    depth: c_uint,

    image: ?*c.XImage = null,

    width: usize,
    height: usize,

    // -------------------------------------------------
    // Init
    // -------------------------------------------------
    pub fn init(
        width: usize,
        height: usize,
        title: []const u8,
        pixels: []u32,
    ) !X11Window {
        const display = c.XOpenDisplay(null) orelse {
            return error.XOpenDisplayFailed;
        };

        const screen = c.DefaultScreen(display);
        const visual = c.DefaultVisual(display, screen);
        const depth: c_uint = @intCast(c.DefaultDepth(display, screen));

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

        _ = c.XSelectInput(
            display,
            window,
            c.ExposureMask |
                c.KeyPressMask |
                c.StructureNotifyMask,
        );

        _ = c.XMapWindow(display, window);

        const gc = c.XCreateGC(display, window, 0, null);

        var self = X11Window{
            .display = display,
            .window = window,
            .gc = gc,
            .screen = screen,
            .visual = visual,
            .depth = depth,
            .width = width,
            .height = height,
        };

        self.createImage(pixels, width, height);

        return self;
    }

    // -------------------------------------------------
    // Deinit
    // -------------------------------------------------
    pub fn deinit(self: *X11Window) void {
        if (self.image) |img| {
            img.*.data = null; // prevent freeing Zig memory
            if (img.*.f.destroy_image) |destroy_fn| {
                _ = destroy_fn(img);
            }
        }

        _ = c.XFreeGC(self.display, self.gc);
        _ = c.XDestroyWindow(self.display, self.window);
        _ = c.XCloseDisplay(self.display);
    }


    // -------------------------------------------------
    // Event polling
    // -------------------------------------------------
    pub fn poll(self: *X11Window) bool {
        var event: c.XEvent = undefined;

        while (c.XPending(self.display) != 0) {
            _ = c.XNextEvent(self.display, &event);

            switch (event.type) {
                c.DestroyNotify => return false,

                c.ConfigureNotify => {
                    const cfg = event.xconfigure;
                    self.width = @intCast(cfg.width);
                    self.height = @intCast(cfg.height);
                },

                else => {},
            }
        }

        return true;
    }

    // -------------------------------------------------
    // Present
    // -------------------------------------------------
    pub fn present(self: *X11Window) void {
        if (self.image == null) return;

        _ = c.XPutImage(
            self.display,
            self.window,
            self.gc,
            self.image.?,
            0,
            0,
            0,
            0,
            @intCast(self.width),
            @intCast(self.height),
        );

        _ = c.XFlush(self.display);
    }

    // -------------------------------------------------
    // Resize framebuffer (NO Xlib macros here!)
    // -------------------------------------------------
    pub fn resizeFramebuffer(
    self: *X11Window,
    pixels: []u32,
    w: usize,
    h: usize,
) void {
        if (self.image) |img| {
            img.*.data = null;
            if (img.*.f.destroy_image) |destroy_fn| {
                _ = destroy_fn(img);
            }
        }

        self.createImage(pixels, w, h);
        self.width = w;
        self.height = h;
    }

    fn createImage(
        self: *X11Window,
        pixels: []u32,
        w: usize,
        h: usize,
    ) void {
        self.image = c.XCreateImage(
            self.display,                         // Display*
            self.visual,                          // Visual*
            self.depth,                           // depth (unsigned int)
            c.ZPixmap,                            // format
            0,                                    // offset
            @ptrCast(pixels.ptr),                 // data
            @intCast(w),                          // width
            @intCast(h),                          // height
            32,                                   // bitmap_pad
            @intCast(w * 4),                      // bytes_per_line
        );
    }

};
