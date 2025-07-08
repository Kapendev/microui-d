// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// Version: v0.0.4
// ---

// TODO: work on attributes maybe.

/// High-level wrapper around the low-level `microui` module.
/// Provides helper functions that use a global context and follow D naming conventions.
module microuid;

public import microui;

__gshared UiContext uiContext;

alias UiTextWidthFunc  = mu_TextWidthFunc;  /// Used for getting the width of the text.
alias UiTextHeightFunc = mu_TextHeightFunc; /// Used for getting the height of the text.
alias UiDrawFrameFunc  = mu_DrawFrameFunc;  /// Used for drawing a frame.

alias UiReal      = mu_Real;      /// The floating-point type of microui.
alias UiId        = mu_Id;        /// The control ID type of microui.
alias UiFont      = mu_Font;      /// The font type of microui.
alias UiTexture   = mu_Texture;   /// The texture type of microui.
alias UiSliceMode = mu_SliceMode; /// The slice repeat mode type of microui.

alias UiClipEnum    = mu_ClipEnum;    /// The type of `MU_CLIP_*` enums.
alias UiCommandEnum = mu_CommandEnum; /// The type of `MU_COMMAND_*` enums.
alias UiColorEnum   = mu_ColorEnum;   /// The type of `MU_COLOR_*` enums.
alias UiIconEnum    = mu_IconEnum;    /// The type of `MU_ICON_*` enums.
alias UiAtlasEnum   = mu_AtlasEnum;   /// The type of `MU_ATLAS*` enums.

alias UiResFlags   = mu_ResFlags;   /// The type of `MU_RES_*` enums.
alias UiOptFlags   = mu_OptFlags;   /// The type of `MU_OPT_*` enums.
alias UiMouseFlags = mu_MouseFlags; /// The type of `MU_MOUSE_*` enums.
alias UiKeyFlags   = mu_KeyFlags;   /// The type of `MU_KEY_*` enums.

alias UiColor      = mu_Color;      /// A RGBA color using ubytes.
alias UiRect       = mu_Rect;       /// A 2D rectangle using ints.
alias UiVec        = mu_Vec2;       /// A 2D vector using ints.
alias UiFVec       = mu_FVec2;      /// A 2D vector using floats.
alias UiMargin     = mu_Margin;     /// A set of 4 integer margins for left, top, right, and bottom.
alias UiSlicePart  = mu_SlicePart;  /// A part of a 9-slice with source and target rectangles for drawing.
alias UiSliceParts = mu_SliceParts; /// The parts of a 9-slice.

alias UiPoolItem    = mu_PoolItem;    /// A pool item.
alias UiBaseCommand = mu_BaseCommand; /// Base structure for all render commands, containing type and size metadata.
alias UiJumpCommand = mu_JumpCommand; /// Command to jump to another location in the command buffer.
alias UiClipCommand = mu_ClipCommand; /// Command to set a clipping rectangle.
alias UiRectCommand = mu_RectCommand; /// Command to draw a rectangle with a given color.
alias UiTextCommand = mu_TextCommand; /// Command to render text at a given position with a font and color. The text is a null-terminated string. Use `str.ptr` to access it.
alias UiIconCommand = mu_IconCommand; /// Command to draw an icon inside a rectangle with a given color.
alias UiCommand     = mu_Command;     /// A union of all possible render commands.

alias UiLayout    = mu_Layout;    /// Layout state used to position UI controls within a container.
alias UiContainer = mu_Container; /// A UI container holding commands.
alias UiStyle     = mu_Style;     /// UI style settings including font, sizes, spacing, and colors.
alias UiContext   = mu_Context;   /// The main UI context.

alias computeUiSliceParts = mu_compute_slice_parts;

@trusted:

nothrow @nogc
void readyUiCore(UiFont font = null) {
    mu_init(&uiContext, font);
}

nothrow @nogc
void readyUiCore(UiTextWidthFunc width, UiTextHeightFunc height, UiFont font = null) {
    mu_init_with_funcs(&uiContext, width, height, font);
}

void beginUiCore() {
    mu_begin(&uiContext);
}

void endUiCore() {
    mu_end(&uiContext);
}

void setUifocus(UiId id) {
    mu_set_focus(&uiContext, id);
}

UiId getUiId(const(void)* data, size_t size) {
    return mu_get_id(&uiContext, data, size);
}

UiId getUiId(const(char)[] str) {
    return mu_get_id_str(&uiContext, str);
}

void pushUiId(const(void)* data, size_t size) {
    mu_push_id(&uiContext, data, size);
}

void pushUiId(const(char)[] str) {
    mu_push_id_str(&uiContext, str);
}

void popUiId() {
    mu_pop_id(&uiContext);
}

void pushUiClipRect(UiRect rect) {
    mu_push_clip_rect(&uiContext, rect);
}

void popUiClipRect() {
    mu_pop_clip_rect(&uiContext);
}

UiRect getUiClipRect() {
    return mu_get_clip_rect(&uiContext);
}

UiClipEnum checkUiClipRect(UiRect rect) {
    return mu_check_clip(&uiContext, rect);
}

UiContainer* getCurrentUiContainer() {
    return mu_get_current_container(&uiContext);
}

UiContainer* getUiContainer(const(char)[] name) {
    return mu_get_container(&uiContext, name);
}

void bringUiContainerToFront(UiContainer* cnt) {
    mu_bring_to_front(&uiContext, cnt);
}

/*============================================================================
** pool
**============================================================================*/

int readyUiPool(UiPoolItem* items, size_t len, UiId id) {
    return mu_pool_init(&uiContext, items, len, id);
}

int getFromUiPool(UiPoolItem* items, size_t len, UiId id) {
    return mu_pool_get(&uiContext, items, len, id);
}

void updateUiPool(UiPoolItem* items, size_t idx) {
    mu_pool_update(&uiContext, items, idx);
}

/*============================================================================
** input handlers
**============================================================================*/

nothrow @nogc
void uiInputMouseMove(int x, int y) {
    mu_input_mousemove(&uiContext, x, y);
}

nothrow @nogc
void uiInputMouseDown(int x, int y, UiMouseFlags input) {
    mu_input_mousedown(&uiContext, x, y, input);
}

nothrow @nogc
void uiInputMouseUp(int x, int y, UiMouseFlags input) {
    mu_input_mouseup(&uiContext, x, y, input);
}

nothrow @nogc
void uiInputScroll(int x, int y) {
    mu_input_scroll(&uiContext, x, y);
}

nothrow @nogc
void uiInputKeyDown(UiKeyFlags input) {
    mu_input_keydown(&uiContext, input);
}

nothrow @nogc
void uiInputKeyUp(UiKeyFlags input) {
    mu_input_keyup(&uiContext, input);
}

nothrow @nogc
void uiInputText(const(char)[] text) {
    mu_input_text(&uiContext, text);
}

/*============================================================================
** commandlist
**============================================================================*/

UiCommand* pushUiCommand(UiCommandEnum type, size_t size) {
    return mu_push_command(&uiContext, type, size);
}

bool nextUiCommand(UiCommand** cmd) {
    return mu_next_command(&uiContext, cmd);
}

void setUiClipRect(UiRect rect) {
    mu_set_clip(&uiContext, rect);
}

void drawUiRect(UiRect rect, UiColor color, UiAtlasEnum id = MU_ATLAS_NONE) {
    mu_draw_rect(&uiContext, rect, color, id);
}

void drawUibox(UiRect rect, UiColor color) {
    mu_draw_box(&uiContext, rect, color);
}

void drawUiText(mu_Font font, const(char)[] str, UiVec point, UiColor color) {
    mu_draw_text(&uiContext, font, str, point, color);
}

void drawUiIcon(UiIconEnum id, UiRect rect, UiColor color) {
    mu_draw_icon(&uiContext, id, rect, color);
}

/*============================================================================
** layout
**============================================================================*/

void beginUiColumn() {
    mu_layout_begin_column(&uiContext);
}

void endUiColumn() {
    mu_layout_end_column(&uiContext);
}

void uiRow(int height, const(int)[] widths...) {
    mu_layout_row(&uiContext, height, widths);
}

void setLayoutWidth(int width) {
    mu_layout_width(&uiContext, width);
}

void setLayoutHeight(int height) {
    mu_layout_height(&uiContext, height);
}

void setNextLayout(UiRect rect, bool relative) {
    mu_layout_set_next(&uiContext, rect, relative);
}

UiRect nextLayout() {
    return mu_layout_next(&uiContext);
}

/*============================================================================
** controls
**============================================================================*/

void drawControlFrame(UiId id, UiRect rect, UiColorEnum colorId, UiOptFlags opt, UiAtlasEnum atlasId = MU_ATLAS_NONE) {
    mu_draw_control_frame(&uiContext, id, rect, colorId, opt, atlasId);
}

void drawControlText(const(char)[] text, UiRect rect, UiColorEnum colorId, UiOptFlags opt) {
    mu_draw_control_text(&uiContext, text, rect, colorId, opt);
}

bool isUiMouseOver(UiRect rect) {
    return mu_mouse_over(&uiContext, rect);
}

void updateControl(UiId id, UiRect rect, UiOptFlags opt) {
    mu_update_control(&uiContext, id, rect, opt);
}

void text(const(char)[] text) {
    mu_text(&uiContext, text);
}

void label(const(char)[] text) {
    mu_label(&uiContext, text);
}

UiResFlags button(const(char)[] label, UiIconEnum icon, UiOptFlags opt) {
    return mu_button_ex(&uiContext, label, icon, opt);
}

UiResFlags button(const(char)[] label) {
    return mu_button(&uiContext, label);
}

UiResFlags checkbox(const(char)[] label, ref bool state) {
    return mu_checkbox(&uiContext, label, &state);
}

UiResFlags textbox(char[] buffer, UiOptFlags opt, size_t* newlen = null) {
    return mu_textbox_ex(&uiContext, buffer, opt, newlen);
}

UiResFlags textbox(char[] buffer, size_t* newlen = null) {
    return mu_textbox(&uiContext, buffer, newlen);
}

UiResFlags slider(ref UiReal value, UiReal low, UiReal high, UiReal step, const(char)[] fmt, UiOptFlags opt) {
    return mu_slider_ex(&uiContext, &value, low, high, step, fmt, opt);
}

UiResFlags slider(ref UiReal value, UiReal low, UiReal high) {
    return mu_slider(&uiContext, &value, low, high);
}

UiResFlags number(ref UiReal value, UiReal step, const(char)[] fmt, UiOptFlags opt) {
    return mu_number_ex(&uiContext, &value, step, fmt, opt);
}

UiResFlags number(ref UiReal value, UiReal step) {
    return mu_number(&uiContext, &value, step);
}

UiResFlags header(const(char)[] label, UiOptFlags opt) {
    return mu_header_ex(&uiContext, label, opt);
}

UiResFlags header(const(char)[] label) {
    return mu_header(&uiContext, label);
}

UiResFlags beginTreeNode(const(char)[] label, UiOptFlags opt) {
    return mu_begin_treenode_ex(&uiContext, label, opt);
}

UiResFlags beginTreeNode(const(char)[] label) {
    return mu_begin_treenode(&uiContext, label);
}

void endTreeNode() {
    mu_end_treenode(&uiContext);
}

UiResFlags beginWindow(const(char)[] title, UiRect rect, UiOptFlags opt) {
    return mu_begin_window_ex(&uiContext, title, rect, opt);
}

UiResFlags beginWindow(const(char)[] title, UiRect rect) {
    return mu_begin_window(&uiContext, title, rect);
}

void endWindow() {
    mu_end_window(&uiContext);
}

void openPopup(const(char)[] name) {
    mu_open_popup(&uiContext, name);
}

UiResFlags beginPopup(const(char)[] name) {
    return mu_begin_popup(&uiContext, name);
}

void endPopup() {
    mu_end_popup(&uiContext);
}

void beginPanel(const(char)[] name, UiOptFlags opt) {
    mu_begin_panel_ex(&uiContext, name, opt);
}

void beginPanel(const(char)[] name) {
    mu_begin_panel(&uiContext, name);
}

void endPanel() {
    mu_end_panel(&uiContext);
}

void openDMenu() {
    mu_open_dmenu(&uiContext);
}

UiResFlags beginDMenu(ref const(char)[] selection, const(const(char)[])[] items, UiVec canvas, const(char)[] label = "", UiFVec scale = UiFVec(0.5f, 0.7f)) {
    return mu_begin_dmenu(&uiContext, &selection, items, canvas, label, scale);
}

void endDMenu() {
    mu_end_dmenu(&uiContext);
}
