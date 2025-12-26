const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    // -------------------------------------------------
    // Core renderer
    // -------------------------------------------------
    const core_mod = b.createModule(.{
        .root_source_file = b.path("src/core/surface.zig"),
    });

    // -------------------------------------------------
    // X11 low-level window
    // -------------------------------------------------
    const x11_mod = b.createModule(.{
        .root_source_file = b.path("src/platform/linux/x11.zig"),
        .link_libc = true,
    });

    // -------------------------------------------------
    // Platform backend interface
    // -------------------------------------------------
    const platform_backend_mod = b.createModule(.{
        .root_source_file = b.path("src/platform/backend.zig"),
    });

    // -------------------------------------------------
    // Linux backend adapter (X11 → Backend)
    // -------------------------------------------------
    const platform_linux_backend_x11_mod = b.createModule(.{
        .root_source_file = b.path("src/platform/linux/backend_x11.zig"),
        .imports = &.{
            .{ .name = "platform-backend", .module = platform_backend_mod },
            .{ .name = "minigfx-x11", .module = x11_mod },
        },
    });

    // -------------------------------------------------
    // GFX module (PUBLIC API + Context)
    // -------------------------------------------------
    const gfx_mod = b.createModule(.{
        .root_source_file = b.path("src/gfx/api.zig"),
        .imports = &.{
            .{ .name = "minigfx-core", .module = core_mod },
            .{ .name = "minigfx-x11", .module = x11_mod },
            .{ .name = "platform-backend", .module = platform_backend_mod },
            .{ .name = "platform-linux-backend-x11", .module = platform_linux_backend_x11_mod },
        },
    });

    // -------------------------------------------------
    // Executable root
    // -------------------------------------------------
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
