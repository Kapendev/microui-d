/// This example shows how to use microui with Parin.
/// Parin: https://github.com/Kapendev/parin

import mupr; // Equivalent to `import microui`, with additional helper functions for Parin.
import parin;

char[512] buffer = '\0';
auto number = 0.0f;
auto font = engineFont;
auto ctx = mu_Context();

void ready() {
    mupr_init(&ctx, &font);
}

bool update(float dt) {
    mupr_begin(&ctx);
    if (mu_begin_window(&ctx, "The Window", mu_rect(40, 40, 300, 200))) {
        mu_button(&ctx, "My Button");
        mu_slider(&ctx, &number, 0, 100);
        mu_textboxv(&ctx, buffer);
        mu_end_window(&ctx);
    }
    mupr_end(&ctx);
    return false;
}

mixin runGame!(ready, update, null);
