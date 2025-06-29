// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// Version: v0.0.1
// ---

// TODO: work on attributes maybe.

/// Equivalent to `import microui`, with additional helper functions for Parin.
module mupr;

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

    size_t strlen(const(char)* str);
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

    // Parin part...

    alias IStr = const(char)[];
    alias Sz = size_t;

    struct GenIndex {
        Sz value;
        Sz generation;
    }

    alias Rect = Rectangle;
    alias Vec2 = Vector2;
    alias Rgba = Color;
    alias Hook = ubyte;
    alias Flip = ubyte;
    alias Alignment = ubyte;

    enum Mouse : ushort {
        none = 0,
        left = MOUSE_BUTTON_LEFT + 1,
        right = MOUSE_BUTTON_RIGHT + 1,
        middle = MOUSE_BUTTON_MIDDLE + 1,
    }

    struct DrawOptions {
        Vec2 origin    = Vec2(0.0f, 0.0f);
        Vec2 scale     = Vec2(1.0f, 1.0f);
        float rotation = 0.0f;
        Rgba color     = Rgba(255, 255, 255, 255);
        Hook hook      = 0;
        Flip flip      = 0;
    }

    struct TextOptions {
        float visibilityRatio  = 1.0f;
        int alignmentWidth     = 0;
        ushort visibilityCount = 0;
        Alignment alignment    = 0;
        bool isRightToLeft     = false;
    }

    struct PFont {
        Font data;
        int runeSpacing;
        int lineSpacing;
    }

    struct PFontId {
        GenIndex data;
    }


    ref PFont getFont(PFontId id);
    int windowWidth();
    int windowHeight();
    Vec2 mouse();
    float deltaWheel();
    bool isPressedMouse(Mouse key);
    bool isReleasedMouse(Mouse key);
    Vec2 measureTextSizeX(PFont font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
    Vec2 measureTextSize(PFontId font, IStr text, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
    void drawTextX(PFont font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
    void drawText(PFontId font, IStr text, Vec2 position, DrawOptions options = DrawOptions(), TextOptions extra = TextOptions());
    void drawRect(Rect area, Rgba color = Rgba(255, 255, 255, 255));
}

@trusted:

// Temporary text measurement function for prototyping.
private int mupr_temp_text_width_func(mu_Font font, const(char)[] str) {
    auto da = cast(PFontId*) font;
    return cast(int) measureTextSize(*da, str).x;
}
// Temporary text measurement function for prototyping.
private int mupr_temp_text_height_func(mu_Font font) {
    auto da = cast(PFontId*) font;
    auto data = cast(Font*) &getFont(*da);
    return data.baseSize;
}

extern(C) @trusted:

/// Initializes the microui context and sets temporary text size functions. Value `font` should be a `FontId*`.
void mupr_init(mu_Context* ctx, mu_Font font = null) {
    mu_init_with_funcs(ctx, &mupr_temp_text_width_func, &mupr_temp_text_height_func, font ? font : ctx.style.font);
    auto da = cast(PFontId*) ctx.style.font;
    if (da) {
        auto data = cast(Font*) &getFont(*da);
        ctx.style.size = mu_vec2(data.baseSize * 6, data.baseSize);
        ctx.style.title_height = data.baseSize + 11;
        if (data.baseSize <= 16) {
            ctx.style.control_border_size = 1;
        } else if (data.baseSize <= 64) {
            ctx.style.control_border_size = 2;
            ctx.style.spacing += 4;
            ctx.style.padding += 4;
        } else {
            ctx.style.control_border_size = 3;
            ctx.style.spacing += 8;
            ctx.style.padding += 8;
        }
    }
}

/// Initializes the microui context and sets custom text size functions. Value `font` should be a `FontId*`.
void mupr_init_with_funcs(mu_Context* ctx, mu_TextWidthFunc width, mu_TextHeightFunc height, mu_Font font = null) {
    mupr_init(ctx, font);
    ctx.text_width = width;
    ctx.text_height = height;
}

/// Handles input events and updates the microui context accordingly.
void mupr_handle_input(mu_Context* ctx) {
    enum scroll_speed = -30;

    mu_input_scroll(ctx, 0, cast(int) deltaWheel * scroll_speed);
    mu_input_mousedown(ctx, cast(int) mouse.x, cast(int) mouse.y, isPressedMouse(Mouse.left) ? MU_MOUSE_LEFT : MU_MOUSE_NONE);
    mu_input_mouseup(ctx, cast(int) mouse.x, cast(int) mouse.y, isReleasedMouse(Mouse.left) ? MU_MOUSE_LEFT : MU_MOUSE_NONE);

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

/// Draws the microui context to the screen.
void mupr_draw(mu_Context* ctx) {
    auto style_font = cast(PFontId*) ctx.style.font;
    BeginScissorMode(0, 0, windowWidth, windowHeight);
    mu_Command *cmd;
    while (mu_next_command(ctx, &cmd)) {
        switch (cmd.type) {
            case MU_COMMAND_TEXT:
                auto text_font = cast(PFontId*) cmd.text.font;
                auto text_options = DrawOptions();
                text_options.color = *(cast(Rgba*) (&cmd.text.color));
                drawText(
                    *text_font,
                    cmd.text.str.ptr[0 .. strlen(cmd.text.str.ptr)],
                    Vec2(cmd.text.pos.x, cmd.text.pos.y),
                    text_options,
                );
                break;
            case MU_COMMAND_RECT:
                drawRect(
                    Rect(cmd.rect.rect.x, cmd.rect.rect.y, cmd.rect.rect.w, cmd.rect.rect.h),
                    *(cast(Rgba*) (&cmd.rect.color)),
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
                auto ic_options = DrawOptions();
                ic_options.color = *(cast(Rgba*) (&cmd.icon.color));

                if (ic_diff.x < 0) ic_diff.x *= -1;
                if (ic_diff.y < 0) ic_diff.y *= -1;
                drawText(
                    *style_font,
                    icon,
                    Vec2(ic_rect.x + ic_diff.x / 2, ic_rect.y + ic_diff.y / 2),
                    ic_options,
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
