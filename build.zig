const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    // Core module
    const core_mod = b.createModule(.{
        .root_source_file = b.path("src/core/surface.zig"),
    });

    // X11 backend module
    const x11_mod = b.createModule(.{
        .root_source_file = b.path("src/platform/linux/x11.zig"),
        .link_libc = true,
    });

    // GFX module (Context lives here)
    const gfx_mod = b.createModule(.{
        .root_source_file = b.path("src/gfx/api.zig"),
        .imports = &.{
            .{ .name = "minigfx-core", .module = core_mod },
            .{ .name = "minigfx-x11", .module = x11_mod },
        },
    });

    // Root module for executable (MUST have target)
    const exe_root = b.createModule(.{
        .root_source_file = b.path("src/demo/main.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "minigfx-gfx", .module = gfx_mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = "minigfx-demo",
        .root_module = exe_root,
    });

    exe.linkSystemLibrary("X11");

    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    b.step("run", "Run the demo").dependOn(&run.step);
}
