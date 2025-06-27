# 🔩 microui-D

A tiny, portable, immediate-mode UI library written in D.
Microui-D is a complete rewrite of [rxi's microui](https://github.com/rxi/microui) library.

## Major Features

* Around `1500 sloc` of D
* Works within a fixed memory region
* Works with any rendering system that can draw rectangles and text
* Easily extensible with custom controls
* Optional helper modules for popular frameworks ([raylib](source/murl.d), [parin](source/mupr.d))
* C interface for cross-language use
* WebAssembly support with BetterC

## Hello World Example Using Raylib

```d
import murl;   // Equivalent to `import microui`, with additional raylib helper functions.
import raylib; // Import the raylib bindings.

void main() {
    char[512] buffer = '\0';
    auto number = 0.0f;

    // Create the window and the UI context.
    InitWindow(800, 600, "raylib + microui");
    auto font = GetFontDefault();
    auto ctx = new mu_Context();
    murl_init_with_temp_funcs(ctx, &font);

    while (!WindowShouldClose) {
        // Update the UI.
        murl_handle_input(ctx);
        mu_begin(ctx);
        if (mu_begin_window(ctx, "The Window", mu_rect(40, 40, 300, 200))) {
            mu_button(ctx, "My Button");
            mu_slider(ctx, &number, 0, 100, 1, "Number: %g");
            mu_textbox(ctx, buffer.ptr, buffer.length);
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

## Documentation

TODO
