const std = @import("std");

const Surface = @import("minigfx-core").Surface;
const X11 = @import("minigfx-x11");

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    // Create software surface
    var surface = try Surface.init(allocator, 640, 480);
    defer surface.deinit(allocator);

    // Create X11 window (shares surface pixels)
    var window = try X11.X11Window.init(
        surface.width,
        surface.height,
        "minigfx demo",
        surface.pixels,
    );
    defer window.deinit();

    var x: i32 = 0;

    // Main loop
    while (window.poll()) {
        surface.clear(0xFF202020);
        surface.fillRectSigned(x, 180, 120, 80, 0xFFFF0000);

        window.present();

        x = @mod(x + 2, @as(i32, @intCast(surface.width)));

    }

}
