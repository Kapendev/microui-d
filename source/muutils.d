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

// TODO: Maybe also add a command promt.
// TODO: Have to think about this being somewhere two times :)
mu_ResFlags mu_menu_ex(mu_Context* ctx, const(const(char)[][]) items, mu_Rect rect, const(char)[]* option, mu_OptFlags options, const(char)[] label = "") {
    static char[512] textbox_buffer = '\0';

    auto result = MU_RES_NONE;
    if (mu_begin_window_ex(ctx, "mu_menu", rect, options | MU_OPT_NONAME)) {
        auto window_cnt = mu_get_current_container(ctx);
        if (label.length) {
            mu_layout_row(ctx, 0, ctx.text_width(ctx.style.font, label) + ctx.text_width(ctx.style.font, "  "), -1); // No idea why I have to add two spaces there.
            mu_label(ctx, label);
        } else {
            mu_layout_row(ctx, 0, -1);
        }

        size_t input_length;
        auto backup_color = ctx.style.colors[MU_COLOR_BUTTON];
        auto textbox_result = mu_textbox_exv(ctx, textbox_buffer, (options & MU_OPT_NOTITLE ? MU_OPT_DEFAULTFOCUS : MU_OPT_NONE), &input_length);
        auto input = textbox_buffer[0 .. input_length];
        auto pick = -1;
        auto first = -1;
        auto buttonCount = 0;
        mu_layout_row(ctx, -1, -1);

        mu_begin_panel(ctx, "mu_menu_panel");
        mu_layout_row(ctx, 0, -1);
        auto panel_cnt = mu_get_current_container(ctx);
        if (textbox_result & MU_RES_CHANGE) panel_cnt.scroll.y = 0;
        foreach (i, item; items) {
            auto can_show = input.length == 0 || (item.length < input.length ? false : item[0 .. input.length] == input);
            if (can_show) {
                buttonCount += 1;
                if (first < 0) first = cast(int) i;
                if (buttonCount % 2) {
                    ctx.style.colors[MU_COLOR_BUTTON] = backup_color;
                } else {
                    ctx.style.colors[MU_COLOR_BUTTON] = backup_color.shift(-12);
                }
                if (mu_button_ex(ctx, item, MU_ICON_NONE, MU_OPT_NONE)) pick = cast(int) i;
            }
        }
        ctx.style.colors[MU_COLOR_BUTTON] = backup_color;
        mu_end_panel(ctx);

        if (items.length && textbox_result & MU_RES_SUBMIT) pick = first;
        if (pick >= 0) {
            result = MU_RES_SUBMIT;
            textbox_buffer[0] = '\0';
            *option = items[pick];
            window_cnt.open = false;
            panel_cnt.scroll.y = 0;
        }
        mu_end_window(ctx);
    }
    return result;
}

mu_ResFlags mu_menu(mu_Context* ctx, const(const(char)[][]) items, mu_Rect rect, const(char)[]* option, const(char)[] label = "") {
    return mu_menu_ex(ctx, items, rect, option, MU_OPT_NOCLOSE | MU_OPT_NORESIZE | MU_OPT_NOTITLE, label);
}
