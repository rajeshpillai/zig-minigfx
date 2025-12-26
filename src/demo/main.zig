const std = @import("std");
const Context = @import("minigfx-gfx").Context;

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    var ctx = try Context.init(
        allocator,
        640,
        480,
        "minigfx demo",
    );
    defer ctx.deinit();

    var x: i32 = 0;
    const w_i32: i32 = @as(i32, @intCast(ctx.width()));

    while (ctx.poll()) {
        ctx.beginFrame();

        ctx.clear(0xFF202020);
        ctx.fillRect(x, 180, 120, 80, 0xFFFF0000);

        ctx.endFrame();

        x = @mod(x + 2, w_i32);
    }
}
