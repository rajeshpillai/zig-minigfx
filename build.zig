const std = @import("std");

pub fn build(b: *std.Build) void {
    // Explicit target (required for root module)
    const target = b.standardTargetOptions(.{});

    // Core module (library, no target required)
    const core_mod = b.createModule(.{
        .root_source_file = b.path("src/core/surface.zig"),
    });

    // X11 backend module (library)
    const x11_mod = b.createModule(.{
        .root_source_file = b.path("src/platform/linux/x11.zig"),
        .link_libc = true,
    });

    // Root module for executable (MUST have target)
    const exe_root = b.createModule(.{
        .root_source_file = b.path("src/demo/main.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "minigfx-core", .module = core_mod },
            .{ .name = "minigfx-x11", .module = x11_mod },
        },
    });

    // Executable
    const exe = b.addExecutable(.{
        .name = "minigfx-demo",
        .root_module = exe_root,
    });

    exe.linkSystemLibrary("X11");

    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    b.step("run", "Run the demo").dependOn(&run.step);
}
