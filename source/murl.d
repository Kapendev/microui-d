// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// Version: v0.0.1
// ---

module murl;

public import microui;

private extern(C) nothrow @nogc {
    enum MOUSE_BUTTON_LEFT   = 0;
    enum MOUSE_BUTTON_RIGHT  = 1;
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

int murl_temp_text_width_func(mu_Context* ctx, mu_Font font, const(char)[] str) {
    auto data = cast(Font*) font;
    return cast(int) MeasureTextEx(*data, str.ptr, data.baseSize, 1).x;
}

int murl_temp_text_height_func(mu_Context* ctx, mu_Font font) {
    auto data = cast(Font*) font;
    return cast(int) data.baseSize;
}

extern(C):

void murl_init_with_temp_funcs(mu_Context* ctx, mu_Font font = null) {
    mu_init_with_funcs(ctx, &murl_temp_text_width_func, &murl_temp_text_height_func, font);
}

void murl_handle_input(mu_Context* ctx) {
    enum scroll_speed = -30;

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
    mu_input_scroll(ctx, cast(int) scroll.x * scroll_speed, cast(int) scroll.y * scroll_speed);
    mu_input_mousedown(ctx, GetMouseX(), GetMouseY(), IsMouseButtonPressed(MOUSE_BUTTON_LEFT) ? MU_MOUSE_LEFT : MU_MOUSE_NONE);
    mu_input_mouseup(ctx, GetMouseX(), GetMouseY(), IsMouseButtonReleased(MOUSE_BUTTON_LEFT) ? MU_MOUSE_LEFT : MU_MOUSE_NONE);

    mu_input_keydown(ctx, IsKeyPressed(KEY_LEFT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_RIGHT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_LEFT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_RIGHT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_LEFT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_RIGHT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_KP_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    mu_input_keydown(ctx, IsKeyPressed(KEY_BACKSPACE) ? MU_KEY_BACKSPACE : MU_KEY_NONE);

    mu_input_keyup(ctx, IsKeyReleased(KEY_LEFT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_RIGHT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_LEFT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_RIGHT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_LEFT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_RIGHT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_KP_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    mu_input_keyup(ctx, IsKeyReleased(KEY_BACKSPACE) ? MU_KEY_BACKSPACE : MU_KEY_NONE);

    char[512] charBuffer = void;
    foreach (i; 0 .. charBuffer.length) {
        charBuffer[i] = cast(char) GetCharPressed();
        if (charBuffer[i] == '\0') break;
    }
    mu_input_text(ctx, charBuffer[]);
}

void murl_draw(mu_Context* ctx) {
    BeginScissorMode(0, 0, GetScreenWidth(), GetScreenHeight());
    mu_Command *cmd;
    while (mu_next_command(ctx, &cmd)) {
        switch (cmd.type) {
            case MU_COMMAND_TEXT:
                Font* font = cast(Font*) cmd.text.font;
                Vector2 text_position = Vector2(cmd.text.pos.x, cmd.text.pos.y);
                Color text_color = *(cast(Color*) (&cmd.text.color));
                DrawTextEx(*font, cmd.text.str.ptr, text_position, font.baseSize, 1, text_color);
                break;
            case MU_COMMAND_RECT:
                Rectangle rect = Rectangle(cmd.rect.rect.x, cmd.rect.rect.y, cmd.rect.rect.w, cmd.rect.rect.h);
                Color rect_color = *(cast(Color*) (&cmd.rect.color));
                DrawRectangleRec(rect, rect_color);
                break;
            case MU_COMMAND_ICON:
                Font* font = cast(Font*) ctx.style.font;
                const(char)[] icon = "?";
                switch (cmd.icon.id) {
                    case MU_ICON_CLOSE: icon = "x"; break;
                    case MU_ICON_CHECK: icon = "*"; break;
                    case MU_ICON_COLLAPSED: icon = "+"; break;
                    case MU_ICON_EXPANDED: icon = "-"; break;
                    default: break;
                }
                DrawTextEx(
                    *font,
                    icon.ptr,
                    Vector2(cmd.icon.rect.x + ctx.text_width(ctx, font, icon) + 1, cmd.icon.rect.y + (ctx.text_height(ctx, font) / 2) + 1),
                    font.baseSize,
                    1,
                    *(cast(Color*) &cmd.icon.color),
                );
                break;
            case MU_COMMAND_CLIP:
                EndScissorMode();
                BeginScissorMode(cmd.clip.rect.x, cmd.clip.rect.y, cmd.clip.rect.w,
                cmd.clip.rect.h);
                break;
            default:
                break;
        }
    }
    EndScissorMode();
}
