const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("minigfx-core", .{
        .root_source_file = b.path("src/core/surface.zig"),
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("minigfx-x11", .{
        .root_source_file = b.path("src/platform/linux/x11.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
}
