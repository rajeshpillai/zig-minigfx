# minigfx

A minimal, cross-platform graphics library for Zig, inspired by [raylib](https://www.raylib.com/)'s simple API design.

## Overview

**minigfx** provides a raylib-like API for creating simple 2D graphics applications in Zig. It features:

- 🎯 **Simple API** - Familiar raylib-style functions (`InitWindow`, `BeginDrawing`, `DrawRectangle`, etc.)
- 🏗️ **Modular Architecture** - Clean separation between platform backends and rendering core
- 🖥️ **Cross-Platform Ready** - Template structure for Windows, macOS, and Linux support
- 🎨 **Software Rendering** - CPU-based framebuffer rendering for simplicity and portability
- 🔧 **Zero Dependencies** - Only requires system libraries (X11 on Linux)

## Current Status

- ✅ **Linux (X11)** - Fully implemented and working
- 🚧 **Windows (Win32)** - Template ready, not implemented
- 🚧 **macOS (Cocoa)** - Template ready, not implemented

## Quick Start

### Prerequisites

- Zig v0.16.0-dev or later
- Linux: X11 development libraries (`libx11-dev` on Ubuntu/Debian)

### Build and Run

```bash
# Clone the repository
git clone <repository-url>
cd minigfx

# Build and run the demo
zig build run
```

### Example Code

```zig
const gfx = @import("minigfx-gfx");

pub fn main() void {
    gfx.InitWindow(640, 480, "minigfx demo");
    defer gfx.CloseWindow();

    var x: i32 = 0;
    const w: i32 = @intCast(gfx.GetScreenWidth());

    while (!gfx.WindowShouldClose()) {
        gfx.BeginDrawing();

        gfx.ClearBackground(0xFF202020);
        gfx.DrawRectangle(x, 180, 120, 80, 0xFFFF0000);

        gfx.EndDrawing();

        if (gfx.IsKeyPressed(.KEY_ESCAPE)) {
            break;
        }

        x = @mod(x + 2, w);
    }
}
```

## API Reference

### Window Management

```zig
InitWindow(width: usize, height: usize, title: []const u8) void
CloseWindow() void
WindowShouldClose() bool
GetScreenWidth() usize
GetScreenHeight() usize
```

### Drawing Functions

```zig
BeginDrawing() void
EndDrawing() void
ClearBackground(color: u32) void
DrawRectangle(x: i32, y: i32, w: i32, h: i32, color: u32) void
```

### Input

```zig
IsKeyPressed(key: KeyboardKey) bool

// Available keys:
pub const KeyboardKey = enum {
    KEY_ESCAPE,
};
```

### Color Format

Colors are 32-bit ARGB values: `0xAARRGGBB`

Examples:
- `0xFFFF0000` - Red
- `0xFF00FF00` - Green
- `0xFF0000FF` - Blue
- `0xFF202020` - Dark gray

## Architecture

```
minigfx/
├── src/
│   ├── core/
│   │   └── surface.zig          # Software framebuffer
│   ├── gfx/
│   │   ├── api.zig              # Public raylib-style API
│   │   └── context.zig          # Graphics context management
│   ├── platform/
│   │   ├── backend.zig          # Platform backend interface
│   │   ├── linux/
│   │   │   ├── x11.zig          # X11 window implementation
│   │   │   └── backend_x11.zig  # X11 backend adapter
│   │   ├── windows/
│   │   │   └── backend_win32.zig # Win32 backend (stub)
│   │   └── macos/
│   │       └── backend_cocoa.zig # Cocoa backend (stub)
│   └── demo/
│       └── main.zig             # Demo application
└── build.zig
```

### Design Principles

1. **Platform Abstraction** - The `Backend` interface (`src/platform/backend.zig`) defines a common contract for all platforms
2. **Software Rendering** - The `Surface` struct provides a simple CPU-based framebuffer
3. **Global Context** - Follows raylib's pattern with a global graphics context for simplicity
4. **Modular Build** - Each component is a separate Zig module for clean dependencies

### Module Structure

```
┌─────────────────┐
│   demo/main     │  ← Your application
└────────┬────────┘
         │
    ┌────▼────┐
    │ gfx/api │  ← Public API (raylib-style)
    └────┬────┘
         │
    ┌────▼────────┐
    │ gfx/context │  ← Graphics context
    └──┬──────┬───┘
       │      │
   ┌───▼──┐ ┌▼────────────┐
   │ core │ │ platform/*  │  ← Platform backends
   └──────┘ └─────────────┘
```

## Adding Platform Support

To add support for a new platform:

1. **Implement the window layer** (e.g., `src/platform/myplatform/window.zig`)
   - Create window
   - Handle events
   - Present framebuffer

2. **Create backend adapter** (e.g., `src/platform/myplatform/backend_myplatform.zig`)
   - Implement the `Backend` interface
   - Adapt platform-specific window to backend contract

3. **Update build.zig**
   - Add platform detection
   - Create modules for new platform
   - Link platform-specific libraries

4. **Update context.zig**
   - Add conditional compilation for new platform
   - Initialize appropriate backend

## Known Issues

- **X11 Connection Error**: If you see "X connection to :0 broken", ensure you have a running X server and `DISPLAY` is set correctly
- **Platform Support**: Only Linux/X11 is currently implemented

## Contributing

Contributions are welcome! Priority areas:

- [ ] Windows (Win32) backend implementation
- [ ] macOS (Cocoa) backend implementation
- [ ] Additional drawing primitives (circles, lines, text)
- [ ] Image loading and texture support
- [ ] Input handling (mouse, keyboard events)

## License

[Specify your license here]

## Acknowledgments

- Inspired by [raylib](https://www.raylib.com/) by Ramon Santamaria
- Built with [Zig](https://ziglang.org/)
