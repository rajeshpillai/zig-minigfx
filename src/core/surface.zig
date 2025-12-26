const std = @import("std");

/// Color represented as 32-bit ARGB value: 0xAARRGGBB
pub const Color = u32;

/// Common color constants
pub const Colors = struct {
    pub const RED: Color = 0xFFFF0000;
    pub const GREEN: Color = 0xFF00FF00;
    pub const BLUE: Color = 0xFF0000FF;
    pub const BLACK: Color = 0xFF000000;
    pub const WHITE: Color = 0xFFFFFFFF;
    pub const YELLOW: Color = 0xFFFFFF00;
    pub const CYAN: Color = 0xFF00FFFF;
    pub const MAGENTA: Color = 0xFFFF00FF;
    pub const GRAY: Color = 0xFF808080;
    pub const DARK_GRAY: Color = 0xFF404040;
    pub const LIGHT_GRAY: Color = 0xFFC0C0C0;
};

/// Create a color from RGBA components (0-255).
/// Returns a 32-bit ARGB color value.
pub fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
    return (@as(u32, a) << 24) | (@as(u32, r) << 16) | (@as(u32, g) << 8) | b;
}

/// Create a color from RGB components (0-255) with full opacity.
/// Returns a 32-bit ARGB color value with alpha = 255.
pub fn rgb(r: u8, g: u8, b: u8) Color {
    return rgba(r, g, b, 255);
}

/// Software framebuffer for CPU-based rendering.
/// Stores pixels in ARGB format (0xAARRGGBB).
pub const Surface = struct {
    width: usize,
    height: usize,
    pixels: []Color,

    /// Initialize a new surface with the specified dimensions.
    /// Allocates memory for width * height pixels.
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

    /// Free the surface's pixel buffer.
    pub fn deinit(self: *Surface, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }

    /// Fill the entire surface with a single color.
    pub fn clear(self: *Surface, color: Color) void {
        @memset(self.pixels, color);
    }

    /// Set a single pixel at the specified coordinates.
    /// Coordinates are signed and clipped to surface bounds.
    /// Negative coordinates or coordinates outside bounds are ignored.
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

    /// Draw a filled rectangle with signed coordinates.
    /// Coordinates and dimensions are clipped to surface bounds.
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

// -------------------------
// Tests
// -------------------------

test "Surface initialization" {
    const allocator = std.testing.allocator;
    var surface = try Surface.init(allocator, 100, 100);
    defer surface.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 100), surface.width);
    try std.testing.expectEqual(@as(usize, 100), surface.height);
    try std.testing.expectEqual(@as(usize, 10000), surface.pixels.len);
}

test "Surface clear" {
    const allocator = std.testing.allocator;
    var surface = try Surface.init(allocator, 10, 10);
    defer surface.deinit(allocator);

    surface.clear(Colors.RED);
    for (surface.pixels) |pixel| {
        try std.testing.expectEqual(Colors.RED, pixel);
    }
}

test "Color helpers" {
    try std.testing.expectEqual(@as(u32, 0xFFFF0000), rgba(255, 0, 0, 255));
    try std.testing.expectEqual(@as(u32, 0xFF00FF00), rgb(0, 255, 0));
    try std.testing.expectEqual(@as(u32, 0x80FF0000), rgba(255, 0, 0, 128));
}

test "Surface pixel operations" {
    const allocator = std.testing.allocator;
    var surface = try Surface.init(allocator, 10, 10);
    defer surface.deinit(allocator);

    surface.clear(Colors.BLACK);
    surface.setPixelSigned(5, 5, Colors.WHITE);
    
    try std.testing.expectEqual(Colors.WHITE, surface.pixels[5 * 10 + 5]);
    
    // Test bounds clipping
    surface.setPixelSigned(-1, 5, Colors.RED); // Should be ignored
    surface.setPixelSigned(5, -1, Colors.RED); // Should be ignored
    surface.setPixelSigned(100, 5, Colors.RED); // Should be ignored
    surface.setPixelSigned(5, 100, Colors.RED); // Should be ignored
}
