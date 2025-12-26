const std = @import("std");

pub const Color = u32;

/// Software framebuffer
pub const Surface = struct {
    width: usize,
    height: usize,
    pixels: []Color,

    pub fn init(
        allocator: std.mem.Allocator,
        width: usize,
        height: usize,
    ) !Surface {
        return .{
            .width = width,
            .height = height,
            .pixels = try allocator.alloc(Color, width * height),
        };
    }

    pub fn deinit(self: *Surface, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }

    pub fn clear(self: *Surface, color: Color) void {
        std.mem.set(Color, self.pixels, color);
    }

    pub fn setPixelSigned(
        self: *Surface,
        x: i32,
        y: i32,
        color: Color,
    ) void {
        if (x < 0 or y < 0) return;

        const ux: usize = @intCast(x);
        const uy: usize = @intCast(y);

        if (ux >= self.width or uy >= self.height) return;
        self.pixels[uy * self.width + ux] = color;
    }

    pub fn fillRectSigned(
        self: *Surface,
        x: i32,
        y: i32,
        w: i32,
        h: i32,
        color: Color,
    ) void {
        var yy: i32 = y;
        while (yy < y + h) : (yy += 1) {
            var xx: i32 = x;
            while (xx < x + w) : (xx += 1) {
                self.setPixelSigned(xx, yy, color);
            }
        }
    }
};
