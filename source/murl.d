// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// Version: v0.0.4
// ---

// TODO: work on attributes maybe.

/// Equivalent to `import microui`, with additional helper functions for raylib.
module murl;

public import microui;

private extern(C) nothrow @nogc {
    enum MOUSE_BUTTON_LEFT   = 0;
    enum MOUSE_BUTTON_RIGHT  = 1;
    enum MOUSE_BUTTON_MIDDLE = 2;
    enum KEY_ENTER           = 257;
    enum KEY_TAB             = 258;
    enum KEY_BACKSPACE       = 259;
    enum KEY_INSERT          = 260;
    enum KEY_DELETE          = 261;
    enum KEY_LEFT_SHIFT      = 340;
    enum KEY_LEFT_CONTROL    = 341;
    enum KEY_LEFT_ALT        = 342;
    enum KEY_LEFT_SUPER      = 343;
    enum KEY_RIGHT_SHIFT     = 344;
    enum KEY_RIGHT_CONTROL   = 345;
    enum KEY_RIGHT_ALT       = 346;
    enum KEY_KP_ENTER        = 335;
    enum KEY_RIGHT           = 262;
    enum KEY_LEFT            = 263;
    enum KEY_DOWN            = 264;
    enum KEY_UP              = 265;
    enum KEY_HOME            = 268;
    enum KEY_END             = 269;
    enum KEY_PAGE_UP         = 266;
    enum KEY_PAGE_DOWN       = 267;

    struct Color { ubyte r, g, b, a; }
    struct Vector2 { float x, y; }
    struct Vector3 { float x, y, z; }
    struct Vector4 { float x, y, z, w; }
    struct Rectangle { float x, y, width, height; }
    struct GlyphInfo {}

    struct Texture {
        uint id;
        int width;
        int height;
        int mipmaps;
        int format;
    }

    struct Font {
        int baseSize;
        int glyphCount;
        int glyphPadding;
        Texture texture;
        Rectangle* recs;
        GlyphInfo* glyphs;
    }

    void* memcpy(void* dest, const(void)* src, size_t count);
    Vector2 MeasureTextEx(Font font, const(char)* text, float fontSize, float spacing);
    Font GetFontDefault();
    Vector2 GetMouseWheelMoveV();
    int GetMouseX();
    int GetMouseY();
    bool IsMouseButtonPressed(int button);
    bool IsMouseButtonReleased(int button);
    bool IsKeyPressed(int button);
    bool IsKeyReleased(int button);
    int GetCharPressed();
    int GetScreenWidth();
    int GetScreenHeight();
    void BeginScissorMode(int x, int y, int width, int height);
    void EndScissorMode();
    void DrawTextEx(Font font, const(char)* text, Vector2 position, float fontSize, float spacing, Color tint);
    void DrawRectangleRec(Rectangle rec, Color color);
}

@trusted:

// Temporary text measurement function for prototyping.
nothrow @nogc
private int murl_temp_text_width_func(mu_Font font, const(char)[] str) {
    auto data = cast(Font*) font;
    return cast(int) MeasureTextEx(*data, str.ptr, data.baseSize, 1).x;
}
// Temporary text measurement function for prototyping.
nothrow @nogc
private int murl_temp_text_height_func(mu_Font font) {
    auto data = cast(Font*) font;
    return data.baseSize;
}

extern(C) @trusted:

/// Initializes the microui context and sets temporary text size functions. Value `font` should be a `Font*`.
nothrow @nogc
void murl_init(mu_Context* ctx, mu_Font font = null) {
    mu_init_with_funcs(ctx, &murl_temp_text_width_func, &murl_temp_text_height_func, font ? font : ctx.style.font);
    auto data = cast(Font*) ctx.style.font;
    if (data) {
        ctx.style.size = mu_vec2(data.baseSize * 6, data.baseSize);
        ctx.style.title_height = data.baseSize + 11;
        if (data.baseSize <= 16) {
        } else if (data.baseSize <= 64) {
            ctx.style.control_border_size = 2;
            ctx.style.spacing += 4;
            ctx.style.padding += 4;
            ctx.style.scrollbar_size += 4;
            ctx.style.scrollbar_speed += 4;
            ctx.style.thumb_size += 4;
        } else {
            ctx.style.control_border_size = 3;
            ctx.style.spacing += 8;
            ctx.style.padding += 8;
            ctx.style.scrollbar_size += 8;
            ctx.style.scrollbar_speed += 8;
            ctx.style.thumb_size += 8;
        }
    }
}

/// Initializes the microui context and sets custom text size functions. Value `font` should be a `Font*`.
nothrow @nogc
void murl_init_with_funcs(mu_Context* ctx, mu_TextWidthFunc width, mu_TextHeightFunc height, mu_Font font = null) {
    murl_init(ctx, font);
    ctx.text_width = width;
    ctx.text_height = height;
}

/// Handles input events and updates the microui context accordingly.
nothrow @nogc
void murl_handle_input(mu_Context* ctx) {
    auto scroll = Vector2();
    version (WebAssembly) {
        scroll = -GetMouseWheelMoveV();
        scroll.x *= -1;
        scroll.y *= -1;
    } version (OSX) {
        scroll = GetMouseWheelMoveV();
        scroll.x *= -1;
        scroll.y *= -1;
    } else {
        scroll = GetMouseWheelMoveV();
    }
    mu_input_scroll(ctx, cast(int) (scroll.x * -ctx.style.scrollbar_speed), cast(int) (scroll.y * -ctx.style.scrollbar_speed));
    mu_input_mousedown(ctx, GetMouseX(), GetMouseY(), IsMouseButtonPressed(MOUSE_BUTTON_LEFT) ? MU_MOUSE_LEFT : MU_MOUSE_NONE);
    mu_input_mouseup(ctx, GetMouseX(), GetMouseY(), IsMouseButtonReleased(MOUSE_BUTTON_LEFT) ? MU_MOUSE_LEFT : MU_MOUSE_NONE);

    mu_input_keydown(ctx, IsKeyPressed(KEY_LEFT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_RIGHT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_LEFT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_RIGHT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_LEFT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_RIGHT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_BACKSPACE) ? MU_KEY_BACKSPACE : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_KP_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_TAB) ? MU_KEY_TAB : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_LEFT) ? MU_KEY_LEFT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_RIGHT) ? MU_KEY_RIGHT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_UP) ? MU_KEY_UP : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_DOWN) ? MU_KEY_DOWN : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_HOME) ? MU_KEY_HOME : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_END) ? MU_KEY_END : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_PAGE_UP) ? MU_KEY_PAGEUP : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_PAGE_DOWN) ? MU_KEY_PAGEDOWN : MU_KEY_NONE);

    mu_input_keyup(ctx, IsKeyReleased(KEY_LEFT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_RIGHT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_LEFT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_RIGHT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_LEFT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_RIGHT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_BACKSPACE) ? MU_KEY_BACKSPACE : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_KP_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_TAB) ? MU_KEY_TAB : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_LEFT) ? MU_KEY_LEFT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_RIGHT) ? MU_KEY_RIGHT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_UP) ? MU_KEY_UP : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_DOWN) ? MU_KEY_DOWN : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_HOME) ? MU_KEY_HOME : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_END) ? MU_KEY_END : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_PAGE_UP) ? MU_KEY_PAGEUP : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_PAGE_DOWN) ? MU_KEY_PAGEDOWN : MU_KEY_NONE);

    char[128] charBuffer = void;
    size_t charBufferLength = 0;
    foreach (i; 0 .. charBuffer.length) {
        charBuffer[i] = cast(char) GetCharPressed();
        if (charBuffer[i] == '\0') { charBufferLength = i; break; }
    }
    if (charBufferLength) mu_input_text(ctx, charBuffer[0 .. charBufferLength]);
}

/// Draws the microui context to the screen.
void murl_draw(mu_Context* ctx) {
    auto style_font = cast(Font*) ctx.style.font;
    BeginScissorMode(0, 0, GetScreenWidth(), GetScreenHeight());
    mu_Command *cmd;
    while (mu_next_command(ctx, &cmd)) {
        switch (cmd.type) {
            case MU_COMMAND_TEXT:
                auto text_font = cast(Font*) cmd.text.font;
                DrawTextEx(
                    *text_font,
                    cmd.text.str.ptr,
                    Vector2(cmd.text.pos.x, cmd.text.pos.y),
                    text_font.baseSize,
                    1,
                    *(cast(Color*) (&cmd.text.color)),
                );
                break;
            case MU_COMMAND_RECT:
                DrawRectangleRec(
                    Rectangle(cmd.rect.rect.x, cmd.rect.rect.y, cmd.rect.rect.w, cmd.rect.rect.h),
                    *(cast(Color*) (&cmd.rect.color)),
                );
                break;
            case MU_COMMAND_ICON:
                const(char)[] icon = "?";
                switch (cmd.icon.id) {
                    case MU_ICON_CLOSE: icon = "x"; break;
                    case MU_ICON_CHECK: icon = "*"; break;
                    case MU_ICON_COLLAPSED: icon = "+"; break;
                    case MU_ICON_EXPANDED: icon = "-"; break;
                    default: break;
                }
                auto ic_width = ctx.text_width(style_font, icon);
                auto ic_height = ctx.text_height(style_font);
                auto ic_rect = cmd.icon.rect;
                auto ic_diff = mu_vec2(ic_rect.w - ic_width, ic_rect.h - ic_height);
                if (ic_diff.x < 0) ic_diff.x *= -1;
                if (ic_diff.y < 0) ic_diff.y *= -1;
                DrawTextEx(
                    *style_font,
                    icon.ptr,
                    Vector2(ic_rect.x + ic_diff.x / 2, ic_rect.y + ic_diff.y / 2),
                    style_font.baseSize,
                    1,
                    *(cast(Color*) &cmd.icon.color),
                );
                break;
            case MU_COMMAND_CLIP:
                EndScissorMode();
                BeginScissorMode(cmd.clip.rect.x, cmd.clip.rect.y, cmd.clip.rect.w, cmd.clip.rect.h);
                break;
            default:
                break;
        }
    }
    EndScissorMode();
}

/// Begins input handling and UI processing.
void murl_begin(mu_Context* ctx) {
    murl_handle_input(ctx);
    mu_begin(ctx);
}

/// Ends UI processing and performs drawing.
void murl_end(mu_Context* ctx) {
    mu_end(ctx);
    murl_draw(ctx);
}
