/// This example shows how to use microui with raylib.
/// It assumes you are using: https://github.com/schveiguy/raylib-d

import raylib;
import murl; // Equivalent to `import microuid`, with additional helper functions for raylib.

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
