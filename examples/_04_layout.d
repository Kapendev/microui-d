/// This example shows how to use the layout system.
/// More info on: https://github.com/rxi/microui/blob/master/doc/usage.md#layout-system
/// Parin: https://github.com/Kapendev/parin

import mupr;
import parin;

auto font = engineFont;

void ready() {
    auto scale = 2;
    readyUi(&font, scale);
    uiStyle.size.x = 200 * scale;
}

bool update(float dt) { with (UiOptFlag) {
    auto windowRect = UiRect(32, 32, uiStyle.size.x * 2, uiStyle.size.y * 18);
    beginUi();
    if (beginWindow("Toggles", windowRect, noClose | alignCenter)) {
        text("The layout system is row based.");
        button("Item");
        text("Rows contain items or columns.");

        uiRow(0, 30, -30 - uiStyle.spacing - uiStyle.border, -1);
        button("1");
        button("2");
        button("3");

        uiRow(0, 0);
        text("Call `uiRow(0, 0)` to reset things.");
        text("Negative values are relative.");

        uiRow(0, 0);
        button("Start");
        uiRow(0, uiStyle.size.x / 3, uiStyle.size.x / 3, uiStyle.size.x / 3);
        button("(0, 0)");
        beginUiColumn();
        uiRow(0, 0);
        button("(0, 1)");
        button("(1, 1)");
        button("(2, 1)");
        endUiColumn();
        button("(0, 2)");
        uiRow(0, 0);
        button("End");
        text("Columns use their own row sizes.");
        endWindow();
    }
    endUi();
    return false;
}}

mixin runGame!(ready, update, null);
