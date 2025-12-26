const std = @import("std");

const Surface = @import("minigfx-core").Surface;
const Backend = @import("platform-backend").Backend;

// Linux backend (only one wired for now)
const backend_x11 = @import("platform-linux-backend-x11");
const X11 = @import("minigfx-x11");

pub const Context = struct {
    allocator: std.mem.Allocator,

    surface: Surface,

    // Platform backend
    backend: Backend,

    // Backend-owned context (opaque to us, but stored so it lives long enough)
    backend_ctx: X11.X11Window,

    // Input state
    key_escape_pressed: bool = false,

    // -------------------------
    // Lifecycle
    // -------------------------

    /// Initialize a new graphics context.
    /// Creates a window and software rendering surface.
    /// Backend must be initialized separately via initBackend() after
    /// the Context is in its final memory location (heap-allocated).
    pub fn init(
        allocator: std.mem.Allocator,
        win_width: usize,
        win_height: usize,
        title: []const u8,
    ) !Context {
        // Allocate software surface
        var surface = try Surface.init(allocator, win_width, win_height);
        errdefer surface.deinit(allocator);

        // Create X11 window (Linux only for now)
        var window = try X11.X11Window.init(
            win_width,
            win_height,
            title,
            surface.pixels,
        );
        errdefer window.deinit();

        return Context{
            .allocator = allocator,
            .surface = surface,
            .backend = undefined,  // Will be initialized by initBackend()
            .backend_ctx = window,
        };
    }

    /// Initialize backend after Context is in its final location.
    /// MUST be called after Context is heap-allocated and will not be moved.
    /// The backend stores a pointer to backend_ctx, so Context must be stable.
    pub fn initBackend(self: *Context) void {
        self.backend = backend_x11.createBackend(&self.backend_ctx);
    }

    /// Clean up all resources.
    pub fn deinit(self: *Context) void {
        self.backend.deinit(self.backend.ctx);
        self.surface.deinit(self.allocator);
    }

    // -------------------------
    // Frame & event handling
    // -------------------------

    /// Poll events and handle window state.
    /// Returns false when the application should exit.
    pub fn poll(self: *Context) bool {
        const running = self.backend.poll(self.backend.ctx);

        // Resize handling
        const size = self.backend.getSize(self.backend.ctx);
        if (size.w != self.surface.width or size.h != self.surface.height) {
            self.handleResize(size.w, size.h) catch |err| {
                std.log.err("Failed to resize surface: {}", .{err});
                // Continue running but log the error
                // The old surface will still be used
            };
        }

        // Input handling (ESC is signaled by backend closing)
        if (!running) {
            self.key_escape_pressed = true;
        }

        return running;
    }

    /// Begin a new frame.
    /// Currently a placeholder for future frame timing and batching.
    pub fn beginFrame(self: *Context) void {
        _ = self;
        // Placeholder: frame timing, batching, etc.
    }

    /// End the current frame and present to screen.
    pub fn endFrame(self: *Context) void {
        self.backend.present(self.backend.ctx);
    }

    // -------------------------
    // Resize handling
    // -------------------------

    /// Handle window resize by recreating the surface.
    fn handleResize(self: *Context, w: usize, h: usize) !void {
        self.surface.deinit(self.allocator);
        self.surface = try Surface.init(self.allocator, w, h);

        self.backend.resizeFramebuffer(
            self.backend.ctx,
            self.surface.pixels,
            w,
            h,
        );
    }

    // -------------------------
    // Drawing helpers
    // -------------------------

    /// Clear the entire surface with the specified color.
    pub fn clear(self: *Context, color: u32) void {
        self.surface.clear(color);
    }

    /// Draw a filled rectangle with signed coordinates.
    /// Coordinates outside the surface bounds are clipped.
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

    // -------------------------
    // Input queries
    // -------------------------

    /// Check if the escape key was pressed.
    /// Returns true only once per press (consumes the event).
    pub fn isEscapePressed(self: *Context) bool {
        const pressed = self.key_escape_pressed;
        self.key_escape_pressed = false; // consume
        return pressed;
    }

    // -------------------------
    // Info
    // -------------------------

    /// Get the current surface width.
    pub fn width(self: *Context) usize {
        return self.surface.width;
    }

    /// Get the current surface height.
    pub fn height(self: *Context) usize {
        return self.surface.height;
    }
};
