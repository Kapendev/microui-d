// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// Version: v0.0.3
// ---

/// Helper controls and utilities for microui.
module muutils;

import microui;

extern(C) @trusted:

mu_ResFlags mu_dmenu(mu_Context* ctx, const(const(char)[][]) items, mu_Rect rect, const(char)[]* option, const(char)[] label = "") {
    static char[512] buffer = '\0';
    static previous_open = false;

    auto res = MU_RES_NONE;
    auto cnt = mu_get_container(ctx, "dmenu");
    if (cnt == null) return MU_RES_NONE;

    if (!previous_open && cnt.open) cnt.scroll.y = 0; // TODO: Opened could be a thing maybe.
    if (mu_begin_window_ex(ctx, "dmenu", rect, MU_OPT_NOTITLE | MU_OPT_NOCLOSE | MU_OPT_NORESIZE)) {
        size_t textbox_length;
        if (label.length) {
            // No idea why I have to add two spaces there.
            mu_layout_row(ctx, 0, ctx.text_width(ctx.style.font, label) + ctx.text_width(ctx.style.font, "  "), -1);
            mu_label(ctx, label);
        } else {
            mu_layout_row(ctx, 0, -1);
        }
        auto textbox_res = mu_textbox_exv(ctx, buffer, MU_OPT_DEFAULTFOCUS, &textbox_length);
        if (textbox_res & MU_RES_CHANGE) cnt.scroll.y = 0;
        auto input = buffer[0 .. textbox_length];
        auto pick = -1;
        auto first = -1;
        mu_layout_row(ctx, 0, -1);
        foreach (i, item; items) {
            auto item_starts_with_input = item.length < input.length ? false : item[0 .. input.length] == input;
            if (item_starts_with_input || input.length == 0) {
                if (first < 0) first = cast(int) i;
                if (mu_button_ex(ctx, item, MU_ICON_NONE, MU_OPT_NONE)) pick = cast(int) i;
            }
        }
        if (items.length && textbox_res & MU_RES_SUBMIT) pick = first;
        if (pick >= 0) {
            *option = items[pick];
            cnt.open = false;
            res = MU_RES_SUBMIT;
            buffer[0] = '\0';
        }
        mu_end_window(ctx);
    }
    previous_open = cnt.open;
    return res;
}
