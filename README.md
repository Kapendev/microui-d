# 🔩 microui-d

A tiny and portable immediate-mode UI library written in D.
Microui-d is a complete rewrite of [rxi's microui](https://github.com/rxi/microui).
It's 90% the same library, but with bug fixes, texture support, and other D-specific improvements.

## Major Features

* Around `2000 sloc` of D
* Easily extensible
* Simple layout system
* Works within a fixed memory region
* Works with any rendering system that can draw rectangles and text
* Optional helper modules for other libraries ([raylib](https://github.com/raysan5/raylib), [Parin](https://github.com/Kapendev/parin))
* C interface for cross-language use
* BetterC support

## Hello World Example

```d
import murl; // Equivalent to `import microuid`, with additional helper functions for raylib.
import raylib;

void main() {
    // Create the window and UI context.
    InitWindow(800, 600, "raylib + microui");
    auto font = GetFontDefault();
    readyUi(&font);

    while (!WindowShouldClose) {
        BeginDrawing();
        ClearBackground(Color(100, 100, 100, 255));
        // Update and draw the UI.
        beginUi();
        if (beginWindow("The Window", UiRect(40, 40, 300, 200))) {
            button("My Button");
            endWindow();
        }
        endUi();
        EndDrawing();
    }
}
```

## Modules

* `microui`: Immediate-mode UI library
* `microuid`: Wrapper around `microui`
* `murl`: Raylib helper utilities
* `mupr`: Parin helper utilities

## Documentation

Start with the [examples](./examples/) folder for a quick overview.
For more details, check out the [usage instructions](https://github.com/rxi/microui/blob/master/doc/usage.md) by rxi.
