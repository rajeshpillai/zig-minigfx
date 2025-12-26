const std = @import("std");
const Context = @import("context.zig").Context;

/// Internal global context (raylib-style)
var g_ctx: ?Context = null;

pub const KeyboardKey = enum {
    KEY_ESCAPE,
};

/// Initialize window and graphics context
pub fn InitWindow(
    width: usize,
    height: usize,
    title: []const u8,
) void {
    if (g_ctx != null) {
        @panic("InitWindow called twice");
    }

    const allocator = std.heap.c_allocator;

    g_ctx = Context.init(
        allocator,
        width,
        height,
        title,
    ) catch |err| {
        std.debug.panic("InitWindow failed: {}", .{err});
    };
}

pub fn IsKeyPressed(key: KeyboardKey) bool {
    return switch(key) {
        .KEY_ESCAPE => g_ctx.?.isEscapePressed(),
    };
}

/// Close window and release resources
pub fn CloseWindow() void {
    if (g_ctx) |*ctx| {
        ctx.deinit();
        g_ctx = null;
    }
}

/// Returns true when app should exit
pub fn WindowShouldClose() bool {
    return g_ctx == null or !g_ctx.?.poll();
}

/// Begin drawing frame
pub fn BeginDrawing() void {
    // placeholder for future frame state
}

/// End drawing frame (present)
pub fn EndDrawing() void {
    g_ctx.?.endFrame();
}

/// Clear screen
pub fn ClearBackground(color: u32) void {
    g_ctx.?.clear(color);
}

/// Draw filled rectangle
pub fn DrawRectangle(
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    color: u32,
) void {
    g_ctx.?.fillRect(x, y, w, h, color);
}

/// Get screen width
pub fn GetScreenWidth() usize {
    return g_ctx.?.width();
}

pub fn GetScreenHeight() usize {
    return g_ctx.?.height();
}
