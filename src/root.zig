//! minigfx - Minimal cross-platform graphics library for Zig
//! Inspired by raylib's simple API design.

const std = @import(\"std\");

// Re-export main modules for library users
pub const gfx = @import(\"gfx/api.zig\");
pub const Surface = @import(\"core/surface.zig\").Surface;
pub const Color = @import(\"core/surface.zig\").Color;
pub const Colors = @import(\"core/surface.zig\").Colors;
pub const rgba = @import(\"core/surface.zig\").rgba;
pub const rgb = @import(\"core/surface.zig\").rgb;

// Run all tests
test {
    std.testing.refAllDecls(@This());
}
