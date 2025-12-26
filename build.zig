const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Define a module for the core library
    _ = b.addModule("minigfx-core", .{
        .root_source_file = b.path("src/core/surface.zig"),
        .target = target,
        .optimize = optimize,
    });
}
