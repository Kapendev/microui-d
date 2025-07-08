// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// Version: v0.0.4
// ---

// TODO: work on attributes maybe.

/// Equivalent to `import microuid`, with additional helper functions for raylib.
module murl;

public import microuid;

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
    void DrawTexturePro(Texture texture, Rectangle source, Rectangle dest, Vector2 origin, float rotation, Color tint);
}

@trusted:

// Temporary text measurement function for prototyping.
nothrow @nogc
private int murlTempTextWidthFunc(mu_Font font, const(char)[] str) {
    auto data = cast(Font*) font;
    return cast(int) MeasureTextEx(*data, str.ptr, data.baseSize, 1).x;
}
// Temporary text measurement function for prototyping.
nothrow @nogc
private int murlTempTextHeightFunc(mu_Font font) {
    auto data = cast(Font*) font;
    return data.baseSize;
}

/// Initializes the microui context and sets temporary text size functions. Value `font` should be a `Font*`.
nothrow @nogc
void readyUi(mu_Font font = null) {
    readyUiCore(&murlTempTextWidthFunc, &murlTempTextHeightFunc, font ? font : uiContext.style.font);
    auto data = cast(Font*) uiContext.style.font;
    if (data) {
        uiContext.style.size = UiVec(data.baseSize * 6, data.baseSize);
        uiContext.style.titleHeight = data.baseSize + 5;
        if (data.baseSize <= 16) {
            uiContext.style.scrollbarKeySpeed = 1;
        } else if (data.baseSize <= 64) {
            uiContext.style.border = 2;
            uiContext.style.spacing += 4;
            uiContext.style.padding += 4;
            uiContext.style.scrollbarSize += 4;
            uiContext.style.scrollbarSpeed += 4;
            uiContext.style.thumbSize += 4;
        } else {
            uiContext.style.border = 3;
            uiContext.style.spacing += 8;
            uiContext.style.padding += 8;
            uiContext.style.scrollbarSize += 8;
            uiContext.style.scrollbarSpeed += 8;
            uiContext.style.thumbSize += 8;
        }
    }
}

/// Initializes the microui context and sets custom text size functions. Value `font` should be a `Font*`.
nothrow @nogc
void readyUi(UiTextWidthFunc width, UiTextHeightFunc height, UiFont font = null) {
    readyUi(font);
    uiContext.textWidth = width;
    uiContext.textHeight = height;
}

/// Handles input events and updates the microui context accordingly.
nothrow @nogc
void handleUiInput() {
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
    uiInputScroll(cast(int) scroll.x, cast(int) scroll.y);
    uiInputMouseDown(GetMouseX(), GetMouseY(), IsMouseButtonPressed(MOUSE_BUTTON_LEFT) ? MU_MOUSE_LEFT : MU_MOUSE_NONE);
    uiInputMouseUp(GetMouseX(), GetMouseY(), IsMouseButtonReleased(MOUSE_BUTTON_LEFT) ? MU_MOUSE_LEFT : MU_MOUSE_NONE);

    uiInputKeyDown(IsKeyPressed(KEY_LEFT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_RIGHT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_LEFT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_RIGHT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_LEFT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_RIGHT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_BACKSPACE) ? MU_KEY_BACKSPACE : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_KP_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_TAB) ? MU_KEY_TAB : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_LEFT) ? MU_KEY_LEFT : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_RIGHT) ? MU_KEY_RIGHT : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_UP) ? MU_KEY_UP : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_DOWN) ? MU_KEY_DOWN : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_HOME) ? MU_KEY_HOME : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_END) ? MU_KEY_END : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_PAGE_UP) ? MU_KEY_PAGEUP : MU_KEY_NONE);
    uiInputKeyDown(IsKeyPressed(KEY_PAGE_DOWN) ? MU_KEY_PAGEDOWN : MU_KEY_NONE);

    uiInputKeyUp(IsKeyReleased(KEY_LEFT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_RIGHT_SHIFT) ? MU_KEY_SHIFT : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_LEFT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_RIGHT_CONTROL) ? MU_KEY_CTRL : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_LEFT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_RIGHT_ALT) ? MU_KEY_ALT : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_BACKSPACE) ? MU_KEY_BACKSPACE : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_KP_ENTER) ? MU_KEY_RETURN : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_TAB) ? MU_KEY_TAB : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_LEFT) ? MU_KEY_LEFT : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_RIGHT) ? MU_KEY_RIGHT : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_UP) ? MU_KEY_UP : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_DOWN) ? MU_KEY_DOWN : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_HOME) ? MU_KEY_HOME : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_END) ? MU_KEY_END : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_PAGE_UP) ? MU_KEY_PAGEUP : MU_KEY_NONE);
    uiInputKeyUp(IsKeyReleased(KEY_PAGE_DOWN) ? MU_KEY_PAGEDOWN : MU_KEY_NONE);

    char[128] charBuffer = void;
    size_t charBufferLength = 0;
    foreach (i; 0 .. charBuffer.length) {
        charBuffer[i] = cast(char) GetCharPressed();
        if (charBuffer[i] == '\0') { charBufferLength = i; break; }
    }
    if (charBufferLength) uiInputText(charBuffer[0 .. charBufferLength]);
}

/// Draws the microui context to the screen.
void drawUi() {
    auto style_font = cast(Font*) uiContext.style.font;
    auto style_texture = cast(Texture*) uiContext.style.texture;
    BeginScissorMode(0, 0, GetScreenWidth(), GetScreenHeight());
    UiCommand *cmd;
    while (nextUiCommand(&cmd)) {
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
                auto atlas_rect = uiContext.style.atlasRects[cmd.rect.id];
                if (style_texture && atlas_rect.hasSize) {
                    auto slice_margin = uiContext.style.sliceMargins[cmd.rect.id];
                    auto slice_mode = uiContext.style.sliceModes[cmd.rect.id];
                    foreach (i, ref part; computeUiSliceParts(atlas_rect, cmd.rect.rect, slice_margin)) {
                        if (slice_mode && part.canTile) {
                            foreach (y; 0 .. part.tileCount.y) {
                                foreach (x; 0 .. part.tileCount.x) {
                                    auto source_w = (x != part.tileCount.x - 1) ? part.source.w : mu_max(0, part.target.w - x * part.source.w);
                                    auto source_h = (y != part.tileCount.y - 1) ? part.source.h : mu_max(0, part.target.h - y * part.source.h);
                                    DrawTexturePro(
                                        *style_texture,
                                        Rectangle(part.source.x, part.source.y, source_w, source_h),
                                        Rectangle(part.target.x + x * part.source.w, part.target.y + y * part.source.h, source_w, source_h),
                                        Vector2(0.0f, 0.0f),
                                        0.0f,
                                        *(cast(Color*) (&cmd.rect.color)),
                                    );
                                }
                            }
                        } else {
                            DrawTexturePro(
                                *style_texture,
                                Rectangle(part.source.x, part.source.y, part.source.w, part.source.h),
                                Rectangle(part.target.x, part.target.y, part.source.w, part.source.h),
                                Vector2(0.0f, 0.0f),
                                0.0f,
                                *(cast(Color*) (&cmd.rect.color)),
                            );
                        }
                    }
                } else {
                    DrawRectangleRec(
                        Rectangle(cmd.rect.rect.x, cmd.rect.rect.y, cmd.rect.rect.w, cmd.rect.rect.h),
                        *(cast(Color*) (&cmd.rect.color)),
                    );
                }
                break;
            case MU_COMMAND_ICON:
                auto icon_atlas_rect = uiContext.style.iconAtlasRects[cmd.icon.id];
                auto icon_diff = UiVec(cmd.icon.rect.w - icon_atlas_rect.w, cmd.icon.rect.h - icon_atlas_rect.h);
                if (style_texture && icon_atlas_rect.hasSize) {
                    DrawTexturePro(
                        *style_texture,
                        Rectangle(icon_atlas_rect.x, icon_atlas_rect.y, icon_atlas_rect.w, icon_atlas_rect.h),
                        Rectangle(cmd.icon.rect.x + icon_diff.x / 2, cmd.icon.rect.y + icon_diff.y / 2, icon_atlas_rect.w, icon_atlas_rect.h),
                        Vector2(0.0f, 0.0f),
                        0.0f,
                        *(cast(Color*) (&cmd.rect.color)),
                    );
                } else {
                    const(char)[] icon = "?";
                    switch (cmd.icon.id) {
                        case MU_ICON_CLOSE: icon = "x"; break;
                        case MU_ICON_CHECK: icon = "*"; break;
                        case MU_ICON_COLLAPSED: icon = "+"; break;
                        case MU_ICON_EXPANDED: icon = "-"; break;
                        default: break;
                    }
                    auto icon_width = uiContext.textWidth(style_font, icon);
                    auto icon_height = uiContext.textHeight(style_font);
                    icon_diff = UiVec(cmd.icon.rect.w - icon_width, cmd.icon.rect.h - icon_height);
                    DrawTextEx(
                        *style_font,
                        icon.ptr,
                        Vector2(cmd.icon.rect.x + icon_diff.x / 2, cmd.icon.rect.y + icon_diff.y / 2),
                        style_font.baseSize,
                        1,
                        *(cast(Color*) &cmd.icon.color),
                    );
                }
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
void beginUi() {
    handleUiInput();
    beginUiCore();
}

/// Ends UI processing and performs drawing.
void endUi() {
    endUiCore();
    drawUi();
}
