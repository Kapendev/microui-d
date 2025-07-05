// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// Version: v0.0.4
// ---

/// Helper controls and utilities for microui.
module muutils;

import microui;

extern(C) @trusted:

// TODO: Maybe also add a command promt?

mu_ResFlags mu_dmenu_ex(mu_Context* ctx, char[] textbox_buffer, const(char)[]* selection, const(const(char)[])[] items, mu_Rect rect, mu_OptFlags opt, const(char)[] label = "") {
    auto result = MU_RES_NONE;
    auto ptr = textbox_buffer.ptr;
    mu_push_id(ctx, &ptr, ptr.sizeof);
    if (mu_begin_window_ex(ctx, "!dmenu", rect, opt | MU_OPT_NONAME)) {
        result |= MU_RES_ACTIVE;
        auto window_cnt = mu_get_current_container(ctx);
        if (opt & MU_OPT_NOTITLE) {
            window_cnt.rect.x = rect.x;
            window_cnt.rect.y = rect.y;
            window_cnt.rect.w = rect.w;
            window_cnt.rect.h = rect.h;
        }
        if (label.length) {
            mu_layout_row(ctx, 0, ctx.text_width(ctx.style.font, label) + ctx.text_width(ctx.style.font, "  "), -1);
            mu_label(ctx, label);
        } else {
            mu_layout_row(ctx, 0, -1);
        }

        size_t input_length;
        auto backup_color = ctx.style.colors[MU_COLOR_BUTTON];
        auto textbox_result = mu_textbox_ex(ctx, textbox_buffer, opt & MU_OPT_NOTITLE ? MU_OPT_DEFAULTFOCUS : MU_OPT_NONE, &input_length);
        auto input = textbox_buffer[0 .. input_length];
        auto pick = -1;
        auto first = -1;
        auto buttonCount = 0;
        mu_layout_row(ctx, -1, -1);

        mu_begin_panel(ctx, "!dmenupanel");
        mu_layout_row(ctx, 0, -1);
        auto panel_cnt = mu_get_current_container(ctx);
        if (textbox_result & MU_RES_CHANGE) panel_cnt.scroll.y = 0;
        foreach (i, item; items) {
            auto starts_with_input = input.length == 0 || (item.length < input.length ? false : item[0 .. input.length] == input);
            // Draw the item.
            if (!starts_with_input) continue;
            buttonCount += 1;
            if (buttonCount % 2) {
                ctx.style.colors[MU_COLOR_BUTTON] = backup_color;
            } else {
                ctx.style.colors[MU_COLOR_BUTTON] = backup_color.shift(MU_COMMON_COLOR_SHIFT);
            }
            if (mu_button_ex(ctx, item, MU_ICON_NONE, MU_OPT_NONE)) pick = cast(int) i;
            // Do autocomplete.
            if (buttonCount > 1) continue;
            first = cast(int) i;
            auto autocomplete_length = item.length;
            if (ctx.key_pressed & MU_KEY_TAB) {
                foreach (j, c; item) {
                    textbox_buffer[j] = c;
                    if (j > input.length && mu_is_autocomplete_sep(c)) {
                        autocomplete_length = j;
                        break;
                    }
                }
                textbox_buffer[autocomplete_length] = '\0';
            }
        }
        ctx.style.colors[MU_COLOR_BUTTON] = backup_color;
        mu_end_panel(ctx);

        if (items.length && textbox_result & MU_RES_SUBMIT) pick = first;
        if (pick >= 0) {
            result |= MU_RES_SUBMIT;
            textbox_buffer[0] = '\0';
            panel_cnt.scroll.y = 0;
            window_cnt.open = false;
            *selection = items[pick];
        }
        mu_end_window(ctx);
    }
    mu_pop_id(ctx);
    return result;
}

mu_ResFlags mu_dmenu(mu_Context* ctx, char[] textbox_buffer, const(char)[]* selection, const(const(char)[])[] items, mu_Vec2 canvas_size, const(char)[] label = "") {
    auto size = mu_vec2(cast(int) (canvas_size.x * 0.4f), cast(int) (canvas_size.y * 0.6f));
    auto rect = mu_rect(canvas_size.x / 2 - size.x / 2, canvas_size.y / 2 - size.y / 2,  size.x, size.y);
    return mu_dmenu_ex(ctx, textbox_buffer, selection, items, rect, MU_OPT_NOCLOSE | MU_OPT_NORESIZE | MU_OPT_NOTITLE, label);
}

void mu_dmenu_reopen(mu_Context* ctx, char[] textbox_buffer) {
    auto ptr = textbox_buffer.ptr;
    mu_push_id(ctx, &ptr, ptr.sizeof);
    auto cnt = mu_get_container(ctx, "!dmenu");
    if (cnt) cnt.open = true;
    mu_pop_id(ctx);
}
