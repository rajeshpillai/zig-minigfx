# Architecture Documentation

## Overview

**minigfx** is a minimal, cross-platform graphics library for Zig inspired by raylib's simple API design. It uses a layered architecture with clear separation between the public API, rendering core, and platform-specific backends.

## Design Philosophy

1. **Simplicity** - Easy-to-use raylib-style API
2. **Modularity** - Clean separation of concerns
3. **Portability** - Platform abstraction for cross-platform support
4. **Software Rendering** - CPU-based for simplicity and portability
5. **Zero Dependencies** - Only system libraries required

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│                   Application                        │
│              (uses public API)                       │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│              Public API Layer                        │
│         (gfx/api.zig - raylib-style)                │
│  InitWindow, DrawRectangle, ClearBackground, etc.   │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│            Graphics Context Layer                    │
│              (gfx/context.zig)                       │
│    Manages surface, backend, input, lifecycle       │
└──────────┬─────────────────────────┬────────────────┘
           │                         │
┌──────────▼──────────┐   ┌─────────▼────────────────┐
│   Core Rendering    │   │   Platform Backend       │
│  (core/surface.zig) │   │  (platform/backend.zig)  │
│  Software framebuffer│   │  Abstract interface      │
└─────────────────────┘   └──────────┬───────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
         ┌──────────▼─────┐  ┌──────▼──────┐  ┌─────▼──────┐
         │  Linux (X11)   │  │   Windows   │  │   macOS    │
         │ backend_x11.zig│  │backend_win32│  │backend_cocoa│
         └────────────────┘  └─────────────┘  └────────────┘
```

---

## Module Breakdown

### 1. Public API (`src/gfx/api.zig`)

**Purpose:** Provides the raylib-style API that applications use.

**Key Components:**
- Global context pointer (`g_ctx: ?*Context`)
- Window management (`InitWindow`, `CloseWindow`, `WindowShouldClose`)
- Drawing functions (`BeginDrawing`, `EndDrawing`, `ClearBackground`, `DrawRectangle`)
- Input queries (`IsKeyPressed`)
- Screen queries (`GetScreenWidth`, `GetScreenHeight`)

**Design Pattern:** Global state (raylib-style) for simplicity.

**Memory Management:**
- Context is heap-allocated to ensure stable memory address
- Prevents pointer invalidation from struct moves
- `InitWindow` allocates, `CloseWindow` frees

### 2. Graphics Context (`src/gfx/context.zig`)

**Purpose:** Central coordinator that owns the surface and backend.

**Responsibilities:**
- Lifecycle management (init/deinit)
- Event polling and window state
- Resize handling
- Drawing operations delegation
- Input state tracking

**Key Design Decision:**
```zig
pub const Context = struct {
    allocator: std.mem.Allocator,
    surface: Surface,           // Software framebuffer
    backend: Backend,           // Platform abstraction
    backend_ctx: X11.X11Window, // Platform-specific context
    // ...
};
```

**Two-Phase Initialization:**
1. `Context.init()` - Creates surface and platform window
2. `initBackend()` - Initializes backend after Context is heap-allocated

This ensures the backend pointer remains valid (Context doesn't move after backend init).

### 3. Core Rendering (`src/core/surface.zig`)

**Purpose:** Software framebuffer for CPU-based rendering.

**Features:**
- ARGB pixel format (0xAARRGGBB)
- Bounds-checked pixel operations
- Color helpers (`rgb()`, `rgba()`)
- Common color constants

**API:**
```zig
pub const Surface = struct {
    width: usize,
    height: usize,
    pixels: []Color,
    
    pub fn init(allocator, width, height) !Surface
    pub fn deinit(self, allocator) void
    pub fn clear(self, color) void
    pub fn setPixelSigned(self, x, y, color) void
    pub fn fillRectSigned(self, x, y, w, h, color) void
};
```

### 4. Platform Backend Interface (`src/platform/backend.zig`)

**Purpose:** Abstract interface for platform-specific implementations.

**Interface Definition:**
```zig
pub const Backend = struct {
    ctx: *anyopaque,  // Opaque platform context
    
    poll: *const fn (*anyopaque) bool,
    present: *const fn (*anyopaque) void,
    resizeFramebuffer: *const fn (*anyopaque, []u32, usize, usize) void,
    getSize: *const fn (*anyopaque) Size,
    deinit: *const fn (*anyopaque) void,
};
```

**Design Pattern:** Function pointers for runtime polymorphism.

### 5. Platform Implementations

#### Linux/X11 (`src/platform/linux/`)

**Files:**
- `x11.zig` - Low-level X11 window management
- `backend_x11.zig` - Adapter implementing Backend interface

**X11Window Responsibilities:**
- Create X11 window and graphics context
- Handle X11 events (resize, close)
- Present framebuffer via XImage
- Manage X11 resources

**Critical Detail:**
```zig
// In deinit:
img.*.data = null;  // CRITICAL: Prevent X11 from freeing Zig memory
```

The pixel buffer is owned by Surface, not X11. Setting data to null prevents double-free.

#### Windows (`src/platform/windows/backend_win32.zig`)

**Status:** Stub - not implemented

**To Implement:**
- Create Win32 window
- Handle Win32 messages
- Present via BitBlt or similar
- Implement Backend interface

#### macOS (`src/platform/macos/backend_cocoa.zig`)

**Status:** Stub - not implemented

**To Implement:**
- Create NSWindow
- Handle Cocoa events
- Present via CGImage or Metal
- Implement Backend interface

---

## Adding a New Platform

### Step 1: Create Platform Window Module

Create `src/platform/<platform>/<platform>_window.zig`:

```zig
pub const PlatformWindow = struct {
    // Platform-specific fields
    native_window: *NativeWindowType,
    width: usize,
    height: usize,
    
    pub fn init(
        width: usize,
        height: usize,
        title: []const u8,
        pixels: []u32,
    ) !PlatformWindow {
        // 1. Create native window
        // 2. Set up rendering context
        // 3. Return initialized struct
    }
    
    pub fn deinit(self: *PlatformWindow) void {
        // Clean up platform resources
    }
    
    pub fn poll(self: *PlatformWindow) bool {
        // Poll events, return false if should close
    }
    
    pub fn present(self: *PlatformWindow) void {
        // Present pixels to screen
    }
    
    pub fn resizeFramebuffer(
        self: *PlatformWindow,
        pixels: []u32,
        w: usize,
        h: usize,
    ) void {
        // Handle framebuffer resize
    }
};
```

### Step 2: Create Backend Adapter

Create `src/platform/<platform>/backend_<platform>.zig`:

```zig
const Backend = @import("../backend.zig").Backend;
const Size = @import("../backend.zig").Size;
const PlatformWindow = @import("<platform>_window.zig").PlatformWindow;

inline fn win(ctx: *anyopaque) *PlatformWindow {
    return @ptrCast(@alignCast(ctx));
}

pub fn createBackend(window: *PlatformWindow) Backend {
    return .{
        .ctx = window,
        .poll = poll,
        .present = present,
        .resizeFramebuffer = resizeFramebuffer,
        .getSize = getSize,
        .deinit = deinit,
    };
}

fn poll(ctx: *anyopaque) bool {
    return win(ctx).poll();
}

fn present(ctx: *anyopaque) void {
    win(ctx).present();
}

fn resizeFramebuffer(
    ctx: *anyopaque,
    pixels: []u32,
    w: usize,
    h: usize,
) void {
    win(ctx).resizeFramebuffer(pixels, w, h);
}

fn getSize(ctx: *anyopaque) Size {
    const wptr = win(ctx);
    return .{ .w = wptr.width, .h = wptr.height };
}

fn deinit(ctx: *anyopaque) void {
    win(ctx).deinit();
}
```

### Step 3: Update build.zig

Add platform detection and module creation:

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    
    // Platform-specific modules
    const platform_window_mod = switch (target.result.os.tag) {
        .linux => b.createModule(.{
            .root_source_file = b.path("src/platform/linux/x11.zig"),
            .link_libc = true,
        }),
        .windows => b.createModule(.{
            .root_source_file = b.path("src/platform/windows/win32_window.zig"),
            .link_libc = true,
        }),
        .macos => b.createModule(.{
            .root_source_file = b.path("src/platform/macos/cocoa_window.zig"),
            .link_libc = true,
        }),
        else => @panic("Unsupported platform"),
    };
    
    const platform_backend_mod = switch (target.result.os.tag) {
        .linux => b.createModule(.{
            .root_source_file = b.path("src/platform/linux/backend_x11.zig"),
            .imports = &.{
                .{ .name = "platform-backend", .module = backend_interface_mod },
                .{ .name = "platform-window", .module = platform_window_mod },
            },
        }),
        // ... similar for other platforms
    };
    
    // Link platform-specific libraries
    switch (target.result.os.tag) {
        .linux => exe.linkSystemLibrary("X11"),
        .windows => {
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("user32");
        },
        .macos => {
            exe.linkFramework("Cocoa");
            exe.linkFramework("QuartzCore");
        },
        else => {},
    }
}
```

### Step 4: Update context.zig

Add compile-time platform selection:

```zig
// Platform imports
const builtin = @import("builtin");

const PlatformBackend = switch (builtin.os.tag) {
    .linux => @import("platform-linux-backend-x11"),
    .windows => @import("platform-windows-backend-win32"),
    .macos => @import("platform-macos-backend-cocoa"),
    else => @compileError("Unsupported platform"),
};

const PlatformWindow = switch (builtin.os.tag) {
    .linux => @import("platform-linux-x11").X11Window,
    .windows => @import("platform-windows-win32").Win32Window,
    .macos => @import("platform-macos-cocoa").CocoaWindow,
    else => @compileError("Unsupported platform"),
};

pub const Context = struct {
    // ...
    backend_ctx: PlatformWindow,
    
    pub fn init(...) !Context {
        var window = try PlatformWindow.init(...);
        // ...
    }
    
    pub fn initBackend(self: *Context) void {
        self.backend = PlatformBackend.createBackend(&self.backend_ctx);
    }
};
```

---

## Extension Points

### Adding New Drawing Primitives

1. Add function to `Surface`:
```zig
// In surface.zig
pub fn drawCircle(self: *Surface, cx: i32, cy: i32, radius: i32, color: Color) void {
    // Implement circle drawing algorithm
}
```

2. Add wrapper to `Context`:
```zig
// In context.zig
pub fn drawCircle(self: *Context, cx: i32, cy: i32, radius: i32, color: u32) void {
    self.surface.drawCircle(cx, cy, radius, color);
}
```

3. Expose in public API:
```zig
// In api.zig
pub fn DrawCircle(cx: i32, cy: i32, radius: i32, color: u32) void {
    g_ctx.?.drawCircle(cx, cy, radius, color);
}
```

### Adding Input Support

1. Extend `Context` input state:
```zig
pub const Context = struct {
    // ...
    mouse_x: i32 = 0,
    mouse_y: i32 = 0,
    mouse_buttons: [3]bool = .{false} ** 3,
};
```

2. Update platform backend to report input:
```zig
// Platform window should track input and expose via getters
pub fn getMousePosition(self: *PlatformWindow) struct { x: i32, y: i32 } {
    return .{ .x = self.mouse_x, .y = self.mouse_y };
}
```

3. Add public API functions:
```zig
pub fn GetMouseX() i32 {
    return g_ctx.?.mouse_x;
}
```

### Adding Texture Support

1. Create texture module:
```zig
// src/core/texture.zig
pub const Texture = struct {
    width: usize,
    height: usize,
    pixels: []Color,
    
    pub fn loadFromFile(allocator, path) !Texture { ... }
    pub fn deinit(self, allocator) void { ... }
};
```

2. Add blit function to Surface:
```zig
pub fn blitTexture(
    self: *Surface,
    texture: *const Texture,
    x: i32,
    y: i32,
) void {
    // Copy texture pixels to surface
}
```

---

## Memory Management

### Ownership Rules

1. **Surface pixels** - Owned by Surface, allocated/freed by Context
2. **Platform window** - Owned by Context, embedded in backend_ctx
3. **Backend** - Owned by Context, stores pointer to backend_ctx
4. **Context** - Owned by global g_ctx, heap-allocated

### Critical Invariant

**Context must not move after `initBackend()` is called.**

This is why Context is heap-allocated:
```zig
const ctx = allocator.create(Context) catch ...;
ctx.* = Context.init(...) catch ...;
ctx.initBackend();  // Backend stores &ctx.backend_ctx
g_ctx = ctx;        // Context never moves after this
```

If Context were stack-allocated in `InitWindow`, it would move when assigned to `g_ctx`, invalidating the backend pointer.

---

## Testing Strategy

### Unit Tests

Located in module files:
```zig
test "Surface initialization" { ... }
test "Color helpers" { ... }
```

Run with:
```bash
zig test src/core/surface.zig
```

### Integration Tests

Create `tests/` directory:
```zig
// tests/window_test.zig
test "Window creation and destruction" {
    const allocator = std.testing.allocator;
    const ctx = try allocator.create(Context);
    defer allocator.destroy(ctx);
    
    ctx.* = try Context.init(allocator, 100, 100, "Test");
    ctx.initBackend();
    defer ctx.deinit();
    
    try std.testing.expectEqual(@as(usize, 100), ctx.width());
}
```

---

## Performance Considerations

### Current Limitations

1. **Software rendering** - CPU-based, limited performance
2. **No batching** - Each draw call is immediate
3. **No dirty rectangles** - Entire framebuffer presented each frame

### Future Optimizations

1. **GPU backend** - Add Vulkan/Metal/DirectX backends
2. **Dirty rectangle tracking** - Only update changed regions
3. **Draw call batching** - Collect and batch similar operations
4. **Multi-threading** - Parallel rendering for large surfaces

---

## Troubleshooting

### Common Issues

**Issue:** Segfault or "general protection exception"
- **Cause:** Backend pointer invalidation
- **Solution:** Ensure Context is heap-allocated and doesn't move after `initBackend()`

**Issue:** "X connection broken"
- **Cause:** Normal - window was closed
- **Solution:** Not an error, expected behavior

**Issue:** Resize fails silently
- **Cause:** Out of memory during surface reallocation
- **Solution:** Check logs, error is logged but not fatal

---

## Future Directions

1. **GPU Rendering** - Add optional GPU backends
2. **More Platforms** - Implement Windows and macOS backends
3. **Advanced Features** - Textures, fonts, audio
4. **Performance** - Batching, dirty rectangles, multi-threading
5. **Build System** - Better platform detection and configuration

---

## References

- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [raylib](https://www.raylib.com/) - API inspiration
- [X11 Programming Manual](https://tronche.com/gui/x/xlib/)
- [Win32 API Documentation](https://docs.microsoft.com/en-us/windows/win32/)
- [Cocoa Documentation](https://developer.apple.com/documentation/appkit)
