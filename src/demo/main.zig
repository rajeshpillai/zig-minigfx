const gfx = @import("minigfx-gfx");

pub fn main() void {
    gfx.InitWindow(640, 480, "minigfx raylib-style demo");
    defer gfx.CloseWindow();

    var x: i32 = 0;
    const w: i32 = @as(i32, @intCast(gfx.GetScreenWidth()));

    while (!gfx.WindowShouldClose()) {
        gfx.BeginDrawing();

        gfx.ClearBackground(0xFF202020);
        gfx.DrawRectangle(x, 180, 120, 80, 0xFFFF0000);

        gfx.EndDrawing();

        x = @mod(x + 2, w);
    }
}
