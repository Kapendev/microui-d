# 🔩 microui-D

A tiny and portable immediate-mode UI library written in D.
Microui-D is a complete rewrite of [rxi's microui](https://github.com/rxi/microui).
It's 85% the same library, adapted with D-specific improvements where appropriate.

## Major Features

* Around `1800 sloc` of D
* Easily extensible
* Simple layout system
* Works within a fixed memory region
* Works with any rendering system that can draw rectangles and text
* Optional helper modules for other libraries ([raylib](https://github.com/raysan5/raylib), [Parin](https://github.com/Kapendev/parin))
* C interface for cross-language use
* BetterC support

## Hello World Example

```d
import murl; // Equivalent to `import microui`, with additional helper functions for raylib.
import raylib;

void main() {
    // Create the window and the UI context.
    InitWindow(800, 600, "raylib + microui");
    auto font = GetFontDefault();
    auto ctx = new mu_Context();
    murl_init(ctx, &font);

    while (!WindowShouldClose) {
        // Update the UI.
        murl_handle_input(ctx);
        mu_begin(ctx);
        if (mu_begin_window(ctx, "The Window", mu_rect(40, 40, 300, 200))) {
            mu_button(ctx, "My Button");
            mu_end_window(ctx);
        }
        mu_end(ctx);
        // Draw the UI.
        BeginDrawing();
        ClearBackground(Color(100, 100, 100, 255));
        murl_draw(ctx);
        EndDrawing();
    }
}
```

## Modules

* `microui`: Immediate-mode UI library
* `muutils`: Common utility functions
* `murl`: Raylib helper utilities
* `mupr`: Parin helper utilities

## Documentation

Start with the [examples](./examples/) folder for a quick overview.
For more details, check out the [usage instructions](https://github.com/rxi/microui/blob/master/doc/usage.md) by rxi.
