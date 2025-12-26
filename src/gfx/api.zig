const std = @import("std");
const Context = @import("context.zig").Context;

/// Internal global context (raylib-style)
/// Heap-allocated to ensure stable memory address for backend pointers
var g_ctx: ?*Context = null;

pub const KeyboardKey = enum {
    KEY_ESCAPE,
};

/// Initialize window and graphics context.
/// Creates a window with the specified dimensions and title.
/// Must be called before any other graphics functions.
/// Call `CloseWindow()` when done to clean up resources.
///
/// Example:
/// ```zig
/// gfx.InitWindow(800, 600, "My Game");
/// defer gfx.CloseWindow();
/// ```
pub fn InitWindow(
    width: usize,
    height: usize,
    title: []const u8,
) void {
    if (g_ctx != null) {
        @panic("InitWindow called twice");
    }

    const allocator = std.heap.c_allocator;

    // Heap-allocate Context to ensure stable memory address
    const ctx = allocator.create(Context) catch |err| {
        std.debug.panic("Failed to allocate Context: {}", .{err});
    };
    errdefer allocator.destroy(ctx);

    ctx.* = Context.init(
        allocator,
        width,
        height,
        title,
    ) catch |err| {
        allocator.destroy(ctx);
        std.debug.panic("InitWindow failed: {}", .{err});
    };

    // Initialize backend now that Context is at its final memory location
    ctx.initBackend();

    g_ctx = ctx;
}

/// Check if a keyboard key was pressed.
/// Returns true only once per key press (not held).
pub fn IsKeyPressed(key: KeyboardKey) bool {
    return switch(key) {
        .KEY_ESCAPE => g_ctx.?.isEscapePressed(),
    };
}

/// Close window and release all resources.
/// Should be called when the application exits.
/// Safe to call multiple times.
pub fn CloseWindow() void {
    if (g_ctx) |ctx| {
        const allocator = ctx.allocator;
        ctx.deinit();
        allocator.destroy(ctx);
        g_ctx = null;
    }
}

/// Check if the window should close.
/// Returns true when the user closes the window or an error occurs.
pub fn WindowShouldClose() bool {
    return g_ctx == null or !g_ctx.?.poll();
}

/// Begin drawing frame.
/// Call this before any drawing operations.
pub fn BeginDrawing() void {
    if (g_ctx) |ctx| {
        ctx.beginFrame();
    }
}

/// End drawing frame and present to screen.
/// Call this after all drawing operations are complete.
pub fn EndDrawing() void {
    g_ctx.?.endFrame();
}

/// Clear the entire screen with the specified color.
/// Color format: 0xAARRGGBB (alpha, red, green, blue)
pub fn ClearBackground(color: u32) void {
    g_ctx.?.clear(color);
}

/// Draw a filled rectangle.
/// Coordinates can be negative and will be clipped to screen bounds.
pub fn DrawRectangle(
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    color: u32,
) void {
    g_ctx.?.fillRect(x, y, w, h, color);
}

/// Get the current screen width in pixels.
pub fn GetScreenWidth() usize {
    return g_ctx.?.width();
}

/// Get the current screen height in pixels.
pub fn GetScreenHeight() usize {
    return g_ctx.?.height();
}
