/// This example shows how to use microui with raylib.
/// It assumes you are using: https://github.com/schveiguy/raylib-d.

import murl; // Equivalent to `import microui`, with additional helper functions for raylib.
import raylib;

void main() {
    char[512] buffer = '\0';
    auto number = 0.0f;

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
            mu_slider(ctx, &number, 0, 100);
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
