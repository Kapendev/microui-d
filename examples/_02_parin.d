/// This example shows how to use microui with Parin.
/// Parin: https://github.com/Kapendev/parin

import mupr; // Equivalent to `import microuid`, with additional helper functions for Parin.
import parin;

char[512] buffer = '\0';
auto number = 0.0f;
auto font = engineFont;

void ready() {
    // Create the UI context.
    readyUi(&font);
}

bool update(float dt) {
    // Update and draw the UI.
    beginUi();
    if (beginWindow("The Window", UiRect(40, 40, 300, 200))) {
        button("My Button");
        slider(number, 0, 100);
        textbox(buffer);
        endWindow();
    }
    endUi();
    return false;
}

mixin runGame!(ready, update, null);
