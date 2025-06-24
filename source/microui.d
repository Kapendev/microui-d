// ---
// Copyright 2025 Alexandros F. G. Kapretsos
// SPDX-License-Identifier: MIT
// Email: alexandroskapretsos@gmail.com
// Project: https://github.com/Kapendev/microui-d
// Version: v0.0.1
// ---

/*
** Copyright (c) 2024 rxi
**
** Permission is hereby granted, free of charge, to any person obtaining a copy
** of this software and associated documentation files (the "Software"), to
** deal in the Software without restriction, including without limitation the
** rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
** sell copies of the Software, and to permit persons to whom the Software is
** furnished to do so, subject to the following conditions:
**
** The above copyright notice and this permission notice shall be included in
** all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
** FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
** IN THE SOFTWARE.
*/

// TODO: Remove C strings from functions. The textinput is the only thing that needs to change I think.
// TODO: Try to fix the sprintf thingy.
// TODO: Add doc comments.
// TODO: Add maybe support for parin and raylib-d?
// TODO: Maybe think about flag types, but ehh...

module microui;

// External dependencies required by microui.
private extern(C) {
    alias STDLIB_QSORT_FUNC = int function(const(void)* a, const(void)* b);

    int sprintf(char* buffer, const(char)* format, ...);
    double strtod(const(char)* str, char** str_end);
    void qsort(void* ptr, size_t count, size_t size, STDLIB_QSORT_FUNC comp);
    void* memset(void* dest, int ch, size_t count);
    void* memcpy(void* dest, const(void)* src, size_t count);
    size_t strlen(const(char)* str);
}

private extern(C) __gshared mu_Rect mu_unclipped_rect = { 0, 0, 0x1000000, 0x1000000 };
private extern(C) __gshared mu_Style mu_default_style;

alias mu_Real = float;
alias mu_Id = uint;
alias mu_Font = void*;

private enum HASH_INITIAL = 2166136261; /* 32bit fnv-1a hash */
private enum RELATIVE = 1;
private enum ABSOLUTE = 2;

enum MU_D_VERSION           = "v0.0.1";
enum MU_VERSION             = "2.02";
enum MU_COMMANDLIST_SIZE    = 256 * 1024;
enum MU_ROOTLIST_SIZE       = 32;
enum MU_CONTAINERSTACK_SIZE = 32;
enum MU_CLIPSTACK_SIZE      = 32;
enum MU_IDSTACK_SIZE        = 32;
enum MU_LAYOUTSTACK_SIZE    = 16;
enum MU_CONTAINERPOOL_SIZE  = 48;
enum MU_TREENODEPOOL_SIZE   = 48;
enum MU_INPUTTEXT_SIZE      = 1024;
enum MU_STR_SIZE            = 1024;
enum MU_MAX_WIDTHS          = 16;
enum MU_REAL_FMT            = "%.3g";
enum MU_SLIDER_FMT          = "%.2f";
enum MU_MAX_FMT             = 127;

enum {
    MU_CLIP_PART = 1,
    MU_CLIP_ALL,
}

enum {
    MU_COMMAND_JUMP = 1,
    MU_COMMAND_CLIP,
    MU_COMMAND_RECT,
    MU_COMMAND_TEXT,
    MU_COMMAND_ICON,
    MU_COMMAND_MAX,
}

enum {
    MU_COLOR_TEXT,
    MU_COLOR_BORDER,
    MU_COLOR_WINDOWBG,
    MU_COLOR_TITLEBG,
    MU_COLOR_TITLETEXT,
    MU_COLOR_PANELBG,
    MU_COLOR_BUTTON,
    MU_COLOR_BUTTONHOVER,
    MU_COLOR_BUTTONFOCUS,
    MU_COLOR_BASE,
    MU_COLOR_BASEHOVER,
    MU_COLOR_BASEFOCUS,
    MU_COLOR_SCROLLBASE,
    MU_COLOR_SCROLLTHUMB,
    MU_COLOR_MAX,
}

enum {
    MU_ICON_CLOSE = 1,
    MU_ICON_CHECK,
    MU_ICON_COLLAPSED,
    MU_ICON_EXPANDED,
    MU_ICON_MAX,
}

enum {
    MU_RES_ACTIVE = (1 << 0),
    MU_RES_SUBMIT = (1 << 1),
    MU_RES_CHANGE = (1 << 2),
}

enum {
    MU_OPT_ALIGNCENTER = (1 << 0),
    MU_OPT_ALIGNRIGHT  = (1 << 1),
    MU_OPT_NOINTERACT  = (1 << 2),
    MU_OPT_NOFRAME     = (1 << 3),
    MU_OPT_NORESIZE    = (1 << 4),
    MU_OPT_NOSCROLL    = (1 << 5),
    MU_OPT_NOCLOSE     = (1 << 6),
    MU_OPT_NOTITLE     = (1 << 7),
    MU_OPT_HOLDFOCUS   = (1 << 8),
    MU_OPT_AUTOSIZE    = (1 << 9),
    MU_OPT_POPUP       = (1 << 10),
    MU_OPT_CLOSED      = (1 << 11),
    MU_OPT_EXPANDED    = (1 << 12),
}

enum {
    MU_MOUSE_LEFT   = (1 << 0),
    MU_MOUSE_RIGHT  = (1 << 1),
    MU_MOUSE_MIDDLE = (1 << 2),
}

enum {
    MU_KEY_SHIFT     = (1 << 0),
    MU_KEY_CTRL      = (1 << 1),
    MU_KEY_ALT       = (1 << 2),
    MU_KEY_BACKSPACE = (1 << 3),
    MU_KEY_RETURN    = (1 << 4),
}

struct mu_Array(T, size_t N) {
    align(T.alignof) ubyte[T.sizeof * N] data;

    enum length = N;

    @safe nothrow @nogc:

    @trusted
    this(const(T)[] items...) {
        auto datadata = this.items;
        foreach (i; 0 .. N) datadata[i] = cast(T) items[i];
    }

    pragma(inline, true)
    T[] opSlice(size_t dim)(size_t i, size_t j) {
        return items[i .. j];
    }

    pragma(inline, true)
    T[] opIndex() {
        return items[];
    }

    // D calls this function when the slice operator is used. Does something but I do not remember what lol.
    pragma(inline, true)
    T[] opIndex(T[] slice) {
        return slice;
    }

    // D will let you get the pointer of the array item if you return a ref value.
    pragma(inline, true)
    ref T opIndex(size_t i) {
        return items[i];
    }

    pragma(inline, true) @trusted
    void opIndexAssign(const(T) rhs, size_t i) {
        items[i] = cast(T) rhs;
    }

    pragma(inline, true) @trusted
    void opIndexOpAssign(const(char)[] op)(const(T) rhs, size_t i) {
        mixin("items[i]", op, "= cast(T) rhs;");
    }

    pragma(inline, true)
    size_t opDollar(size_t dim)() {
        return N;
    }

    pragma(inline, true) @trusted
    T[] items() {
        return (cast(T*) data.ptr)[0 .. N];
    }

    pragma(inline, true) @trusted
    T* ptr() {
        return cast(T*) data.ptr;
    }
}

struct mu_Stack(T, size_t N) {
    int idx;
    mu_Array!(T, N) data = void;

    alias data this;
}

struct mu_Vec2 { int x, y; }
struct mu_Rect { int x, y, w, h; }
struct mu_Color { ubyte r, g, b, a; }
struct mu_PoolItem { mu_Id id; int last_update; }

struct mu_BaseCommand { int type, size; }
struct mu_JumpCommand { mu_BaseCommand base; void* dst; }
struct mu_ClipCommand { mu_BaseCommand base; mu_Rect rect; }
struct mu_RectCommand { mu_BaseCommand base; mu_Rect rect; mu_Color color; }
struct mu_TextCommand { mu_BaseCommand base; mu_Font font; mu_Vec2 pos; mu_Color color; char[MU_STR_SIZE] str; }
struct mu_IconCommand { mu_BaseCommand base; mu_Rect rect; int id; mu_Color color; }

union mu_Command {
    int type;
    mu_BaseCommand base;
    mu_JumpCommand jump;
    mu_ClipCommand clip;
    mu_RectCommand rect;
    mu_TextCommand text;
    mu_IconCommand icon;
}

struct mu_Layout {
    mu_Rect body;
    mu_Rect next;
    mu_Vec2 position;
    mu_Vec2 size;
    mu_Vec2 max;
    mu_Array!(int, MU_MAX_WIDTHS) widths;
    int items;
    int item_index;
    int next_row;
    int next_type;
    int indent;
}

struct mu_Container {
    mu_Command* head;
    mu_Command* tail;
    mu_Rect rect;
    mu_Rect body;
    mu_Vec2 content_size;
    mu_Vec2 scroll;
    int zindex;
    int open;
}

struct mu_Style {
    mu_Font font;
    mu_Vec2 size;
    int padding;
    int spacing;
    int indent;
    int title_height;
    int scrollbar_size;
    int thumb_size;
    mu_Array!(mu_Color, MU_COLOR_MAX) colors;
}

struct mu_Context {
    /* callbacks */
    int function(mu_Font font, const(char)[] str) text_width;
    int function(mu_Font font) text_height;
    void function(mu_Context* ctx, mu_Rect rect, int colorid) draw_frame;
    /* core state */
    mu_Style _style;
    mu_Style* style;
    mu_Id hover;
    mu_Id focus;
    mu_Id last_id;
    mu_Rect last_rect;
    int last_zindex;
    int updated_focus;
    int frame;
    mu_Container* hover_root;
    mu_Container* next_hover_root;
    mu_Container* scroll_target;
    char[MU_MAX_FMT] number_edit_buf;
    mu_Id number_edit;
    /* stacks */
    mu_Stack!(char, MU_COMMANDLIST_SIZE) command_list;
    mu_Stack!(mu_Container*, MU_ROOTLIST_SIZE) root_list;
    mu_Stack!(mu_Container*, MU_CONTAINERSTACK_SIZE) container_stack;
    mu_Stack!(mu_Rect, MU_CLIPSTACK_SIZE) clip_stack;
    mu_Stack!(mu_Id, MU_IDSTACK_SIZE) id_stack;
    mu_Stack!(mu_Layout, MU_LAYOUTSTACK_SIZE) layout_stack;
    /* retained state pools */
    mu_Array!(mu_PoolItem, MU_CONTAINERPOOL_SIZE) container_pool;
    mu_Array!(mu_Container, MU_CONTAINERPOOL_SIZE) containers;
    mu_Array!(mu_PoolItem, MU_TREENODEPOOL_SIZE) treenode_pool;
    /* input state */
    mu_Vec2 mouse_pos;
    mu_Vec2 last_mouse_pos;
    mu_Vec2 mouse_delta;
    mu_Vec2 scroll_delta;
    int mouse_down;
    int mouse_pressed;
    int key_down;
    int key_pressed;
    char[MU_INPUTTEXT_SIZE] input_text;
}

private T mu_min(T)(T a, T b)        => ((a) < (b) ? (a) : (b));
private T mu_max(T)(T a, T b)        => ((a) > (b) ? (a) : (b));
private T mu_clamp(T)(T x, T a, T b) => mu_min(b, mu_max(a, x));
private void mu_expect(T)(T x)       => assert(x, "Fatal microui error.");

private void draw_frame(mu_Context* ctx, mu_Rect rect, int colorid) {
    mu_draw_rect(ctx, rect, ctx.style.colors[colorid]);
    if (colorid == MU_COLOR_SCROLLBASE || colorid == MU_COLOR_SCROLLTHUMB || colorid == MU_COLOR_TITLEBG) return;
    /* draw border */
    if (ctx.style.colors[MU_COLOR_BORDER].a) {
        mu_draw_box(ctx, mu_expand_rect(rect, 1), ctx.style.colors[MU_COLOR_BORDER]);
    }
}

private int compare_zindex(const(void)* a, const(void)* b) {
    return (*cast(mu_Container**) a).zindex - (*cast(mu_Container**) b).zindex;
}

private void hash(mu_Id* hash, const(void)* data, size_t size) {
    const(ubyte)* p = cast(const(ubyte)*) data;
    while (size--) {
        *hash = (*hash ^ *p++) * 16777619;
    }
}

private void push_layout(mu_Context* ctx, mu_Rect body, mu_Vec2 scroll) {
    mu_Layout layout;
    int width = 0;
    memset(&layout, 0, layout.sizeof);
    layout.body = mu_rect(body.x - scroll.x, body.y - scroll.y, body.w, body.h);
    layout.max = mu_vec2(-0x1000000, -0x1000000);
    mu_push(ctx.layout_stack, layout);
    mu_layout_row(ctx, 1, &width, 0);
}

private mu_Layout* get_layout(mu_Context* ctx) {
    return &ctx.layout_stack.items[ctx.layout_stack.idx - 1];
}

private void pop_container(mu_Context* ctx) {
    mu_Container* cnt = mu_get_current_container(ctx);
    mu_Layout* layout = get_layout(ctx);
    cnt.content_size.x = layout.max.x - layout.body.x;
    cnt.content_size.y = layout.max.y - layout.body.y;
    /* pop container, layout and id */
    mu_pop(ctx.container_stack);
    mu_pop(ctx.layout_stack);
    mu_pop_id(ctx);
}

private mu_Container* get_container(mu_Context* ctx, mu_Id id, int opt) {
    mu_Container* cnt;
    /* try to get existing container from pool */
    int idx = mu_pool_get(ctx, ctx.container_pool.ptr, MU_CONTAINERPOOL_SIZE, id);
    if (idx >= 0) {
        if (ctx.containers[idx].open || ~opt & MU_OPT_CLOSED) {
            mu_pool_update(ctx, ctx.container_pool.ptr, idx);
        }
        return &ctx.containers[idx];
    }
    if (opt & MU_OPT_CLOSED) { return null; }
    /* container not found in pool: init new container */
    idx = mu_pool_init(ctx, ctx.container_pool.ptr, MU_CONTAINERPOOL_SIZE, id);
    cnt = &ctx.containers[idx];
    memset(cnt, 0, (*cnt).sizeof);
    cnt.open = 1;
    mu_bring_to_front(ctx, cnt);
    return cnt;
}

private mu_Command* push_jump(mu_Context* ctx, mu_Command* dst) {
    mu_Command* cmd;
    cmd = mu_push_command(ctx, MU_COMMAND_JUMP, mu_JumpCommand.sizeof);
    cmd.jump.dst = dst;
    return cmd;
}

private int in_hover_root(mu_Context* ctx) {
    int i = ctx.container_stack.idx;
    while (i--) {
        if (ctx.container_stack.items[i] == ctx.hover_root) { return 1; }
        /* only root containers have their `head` field set; stop searching if we've
        ** reached the current root container */
        if (ctx.container_stack.items[i].head) { break; }
    }
    return 0;
}

private int number_textbox(mu_Context* ctx, mu_Real* value, mu_Rect r, mu_Id id) {
    if (ctx.mouse_pressed == MU_MOUSE_LEFT && ctx.key_down & MU_KEY_SHIFT && ctx.hover == id) {
        ctx.number_edit = id;
        sprintf(ctx.number_edit_buf.ptr, MU_REAL_FMT, *value);
    }
    if (ctx.number_edit == id) {
        int res = mu_textbox_raw(ctx, ctx.number_edit_buf.ptr, ctx.number_edit_buf.sizeof, id, r, 0);
        if (res & MU_RES_SUBMIT || ctx.focus != id) {
            *value = strtod(ctx.number_edit_buf.ptr, null);
            ctx.number_edit = 0;
        } else {
            return 1;
        }
    }
    return 0;
}

private int header(mu_Context* ctx, const(char)[] label, int istreenode, int opt) {
    mu_Rect r;
    int active, expanded;
    mu_Id id = mu_get_id(ctx, label.ptr, label.length);
    int idx = mu_pool_get(ctx, ctx.treenode_pool.ptr, MU_TREENODEPOOL_SIZE, id);
    int width = -1;
    mu_layout_row(ctx, 1, &width, 0);

    active = (idx >= 0);
    expanded = (opt & MU_OPT_EXPANDED) ? !active : active;
    r = mu_layout_next(ctx);
    mu_update_control(ctx, id, r, 0);

    /* handle click */
    active ^= (ctx.mouse_pressed == MU_MOUSE_LEFT && ctx.focus == id);
    /* update pool ref */
    if (idx >= 0) {
        if (active) { mu_pool_update(ctx, ctx.treenode_pool.ptr, idx); }
        else { memset(&ctx.treenode_pool[idx], 0, mu_PoolItem.sizeof); }
    } else if (active) {
        mu_pool_init(ctx, ctx.treenode_pool.ptr, MU_TREENODEPOOL_SIZE, id);
    }

    /* draw */
    if (istreenode) {
        if (ctx.hover == id) { ctx.draw_frame(ctx, r, MU_COLOR_BUTTONHOVER); }
    } else {
        mu_draw_control_frame(ctx, id, r, MU_COLOR_BUTTON, 0);
    }
    mu_draw_icon(ctx, expanded ? MU_ICON_EXPANDED : MU_ICON_COLLAPSED, mu_rect(r.x, r.y, r.h, r.h), ctx.style.colors[MU_COLOR_TEXT]);
    r.x += r.h - ctx.style.padding;
    r.w -= r.h - ctx.style.padding;
    mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, 0);
    return expanded ? MU_RES_ACTIVE : 0;
}

private void scrollbars(mu_Context* ctx, mu_Container* cnt, mu_Rect* body) {
    int sz = ctx.style.scrollbar_size;
    mu_Vec2 cs = cnt.content_size;
    cs.x += ctx.style.padding * 2;
    cs.y += ctx.style.padding * 2;
    mu_push_clip_rect(ctx, *body);
    /* resize body to make room for scrollbars */
    if (cs.y > cnt.body.h) { body.w -= sz; }
    if (cs.x > cnt.body.w) { body.h -= sz; }
    /* to create a horizontal or vertical scrollbar almost-identical code is
    ** used; only the references to `x|y` `w|h` need to be switched */
    scrollbar!("x", "y", "w", "h")(ctx, cnt, body, cs);
    scrollbar!("y", "x", "h", "w")(ctx, cnt, body, cs);
    mu_pop_clip_rect(ctx);
}

private void push_container_body(mu_Context* ctx, mu_Container* cnt, mu_Rect body, int opt) {
    if (~opt & MU_OPT_NOSCROLL) { scrollbars(ctx, cnt, &body); }
    push_layout(ctx, mu_expand_rect(body, -ctx.style.padding), cnt.scroll);
    cnt.body = body;
}

private void begin_root_container(mu_Context* ctx, mu_Container* cnt) {
    mu_push(ctx.container_stack, cnt);
    /* push container to roots list and push head command */
    mu_push(ctx.root_list, cnt);
    cnt.head = push_jump(ctx, null);
    /* set as hover root if the mouse is overlapping this container and it has a
    ** higher zindex than the current hover root */
    if (mu_rect_overlaps_vec2(cnt.rect, ctx.mouse_pos) && (!ctx.next_hover_root || cnt.zindex > ctx.next_hover_root.zindex)) {
        ctx.next_hover_root = cnt;
    }
    /* clipping is reset here in case a root-container is made within
    ** another root-containers's begin/end block; this prevents the inner
    ** root-container being clipped to the outer */
    mu_push(ctx.clip_stack, mu_unclipped_rect);
}

private void end_root_container(mu_Context* ctx) {
    /* push tail 'goto' jump command and set head 'skip' command. the final steps
    ** on initing these are done in mu_end() */
    mu_Container* cnt = mu_get_current_container(ctx);
    cnt.tail = push_jump(ctx, null);
    cnt.head.jump.dst = ctx.command_list.items.ptr + ctx.command_list.idx;
    /* pop base clip rect and container */
    mu_pop_clip_rect(ctx);
    pop_container(ctx);
}

void mu_push(T1, T2)(ref T1 stk, T2 val) {
    stk.items[stk.idx] = val;
    stk.idx += 1; /* incremented after incase `val` uses this value */
}

void mu_pop(T)(ref T stk) {
    mu_expect(stk.idx > 0);
    stk.idx -= 1;
}

extern(C):

mu_Vec2 mu_vec2(int x, int y) {
    return mu_Vec2(x, y);
}

mu_Rect mu_rect(int x, int y, int w, int h) {
    return mu_Rect(x, y, w, h);
}

mu_Color mu_color(ubyte r, ubyte g, ubyte b, ubyte a) {
    return mu_Color(r, g, b, a);
}

mu_Rect mu_expand_rect(mu_Rect rect, int n) {
    return mu_rect(rect.x - n, rect.y - n, rect.w + n * 2, rect.h + n * 2);
}

mu_Rect mu_intersect_rects(mu_Rect r1, mu_Rect r2) {
    int x1 = mu_max(r1.x, r2.x);
    int y1 = mu_max(r1.y, r2.y);
    int x2 = mu_min(r1.x + r1.w, r2.x + r2.w);
    int y2 = mu_min(r1.y + r1.h, r2.y + r2.h);
    if (x2 < x1) { x2 = x1; }
    if (y2 < y1) { y2 = y1; }
    return mu_rect(x1, y1, x2 - x1, y2 - y1);
}

bool mu_rect_overlaps_vec2(mu_Rect r, mu_Vec2 p) {
    return p.x >= r.x && p.x < r.x + r.w && p.y >= r.y && p.y < r.y + r.h;
}

void mu_init(mu_Context* ctx) {
    // NOTE(Kapendev): This is here because `mu_Array` can't be used at compile time.
    mu_default_style = mu_Style(
        /* font | size | padding | spacing | indent */
        null, mu_Vec2(68, 10), 5, 4, 24,
        /* title_height | scrollbar_size | thumb_size */
        24, 12, 8,
        mu_Array!(mu_Color, 14)(
            mu_Color(230, 230, 230, 255), /* MU_COLOR_TEXT */
            mu_Color(25,  25,  25,  255), /* MU_COLOR_BORDER */
            mu_Color(50,  50,  50,  255), /* MU_COLOR_WINDOWBG */
            mu_Color(25,  25,  25,  255), /* MU_COLOR_TITLEBG */
            mu_Color(240, 240, 240, 255), /* MU_COLOR_TITLETEXT */
            mu_Color(0,   0,   0,   0  ), /* MU_COLOR_PANELBG */
            mu_Color(75,  75,  75,  255), /* MU_COLOR_BUTTON */
            mu_Color(95,  95,  95,  255), /* MU_COLOR_BUTTONHOVER */
            mu_Color(115, 115, 115, 255), /* MU_COLOR_BUTTONFOCUS */
            mu_Color(30,  30,  30,  255), /* MU_COLOR_BASE */
            mu_Color(35,  35,  35,  255), /* MU_COLOR_BASEHOVER */
            mu_Color(40,  40,  40,  255), /* MU_COLOR_BASEFOCUS */
            mu_Color(43,  43,  43,  255), /* MU_COLOR_SCROLLBASE */
            mu_Color(30,  30,  30,  255), /* MU_COLOR_SCROLLTHUMB */
        ),
    );
    memset(ctx, 0, (*ctx).sizeof);
    ctx.draw_frame = &draw_frame;
    ctx._style = cast(mu_Style) mu_default_style;
    ctx.style = &ctx._style;
}

void mu_begin(mu_Context* ctx) {
    mu_expect(ctx.text_width && ctx.text_height);
    ctx.command_list.idx = 0;
    ctx.root_list.idx = 0;
    ctx.scroll_target = null;
    ctx.hover_root = ctx.next_hover_root;
    ctx.next_hover_root = null;
    ctx.mouse_delta.x = ctx.mouse_pos.x - ctx.last_mouse_pos.x;
    ctx.mouse_delta.y = ctx.mouse_pos.y - ctx.last_mouse_pos.y;
    ctx.frame += 1;
}

void mu_end(mu_Context *ctx) {
    int i, n;
    /* check stacks */
    mu_expect(ctx.container_stack.idx == 0);
    mu_expect(ctx.clip_stack.idx      == 0);
    mu_expect(ctx.id_stack.idx        == 0);
    mu_expect(ctx.layout_stack.idx    == 0);

    /* handle scroll input */
    if (ctx.scroll_target) {
        ctx.scroll_target.scroll.x += ctx.scroll_delta.x;
        ctx.scroll_target.scroll.y += ctx.scroll_delta.y;
    }

    /* unset focus if focus id was not touched this frame */
    if (!ctx.updated_focus) {
        ctx.focus = 0;
    }
    ctx.updated_focus = 0;

    /* bring hover root to front if mouse was pressed */
    if (ctx.mouse_pressed && ctx.next_hover_root && ctx.next_hover_root.zindex < ctx.last_zindex && ctx.next_hover_root.zindex >= 0) {
        mu_bring_to_front(ctx, ctx.next_hover_root);
    }

    /* reset input state */
    ctx.key_pressed = 0;
    ctx.input_text[0] = '\0';
    ctx.mouse_pressed = 0;
    ctx.scroll_delta = mu_vec2(0, 0);
    ctx.last_mouse_pos = ctx.mouse_pos;

    /* sort root containers by zindex */
    /* NOTE(Kapendev): Like, totally just slappin that `extern(C)` vibe on the function so it, like, *totes* vibes with qsort, ya know? */
    n = ctx.root_list.idx;
    qsort(ctx.root_list.items.ptr, n, (mu_Container*).sizeof, cast(STDLIB_QSORT_FUNC) &compare_zindex);

    /* set root container jump commands */
    for (i = 0; i < n; i += 1) {
        mu_Container* cnt = ctx.root_list.items[i];
        /* if this is the first container then make the first command jump to it.
        ** otherwise set the previous container's tail to jump to this one */
        if (i == 0) {
            mu_Command* cmd = cast(mu_Command*) ctx.command_list.items;
            cmd.jump.dst = cast(char*) cnt.head + mu_JumpCommand.sizeof;
        } else {
            mu_Container* prev = ctx.root_list.items[i - 1];
            prev.tail.jump.dst = cast(char*) cnt.head + mu_JumpCommand.sizeof;
        }
        /* make the last container's tail jump to the end of command list */
        if (i == n - 1) {
            cnt.tail.jump.dst = ctx.command_list.items.ptr + ctx.command_list.idx;
        }
    }
}

void mu_set_focus(mu_Context* ctx, mu_Id id) {
    ctx.focus = id;
    ctx.updated_focus = 1;
}

// NOTE(Kapendev): Not sure why this is a `void*`, but ehh. Who cares.
mu_Id mu_get_id(mu_Context* ctx, const(void)* data, size_t size) {
    int idx = ctx.id_stack.idx;
    mu_Id res = (idx > 0) ? ctx.id_stack.items[idx - 1] : HASH_INITIAL;
    hash(&res, data, size);
    ctx.last_id = res;
    return res;
}

void mu_push_id(mu_Context* ctx, const(void)* data, size_t size) {
    mu_push(ctx.id_stack, mu_get_id(ctx, data, size));
}

void mu_pop_id(mu_Context* ctx) {
    mu_pop(ctx.id_stack);
}

void mu_push_clip_rect(mu_Context* ctx, mu_Rect rect) {
    mu_Rect last = mu_get_clip_rect(ctx);
    mu_push(ctx.clip_stack, mu_intersect_rects(rect, last));
}

void mu_pop_clip_rect(mu_Context* ctx) {
    mu_pop(ctx.clip_stack);
}

mu_Rect mu_get_clip_rect(mu_Context* ctx) {
    mu_expect(ctx.clip_stack.idx > 0);
    return ctx.clip_stack.items[ctx.clip_stack.idx - 1];
}

int mu_check_clip(mu_Context* ctx, mu_Rect r) {
    mu_Rect cr = mu_get_clip_rect(ctx);
    if (r.x > cr.x + cr.w || r.x + r.w < cr.x || r.y > cr.y + cr.h || r.y + r.h < cr.y) { return MU_CLIP_ALL; }
    if (r.x >= cr.x && r.x + r.w <= cr.x + cr.w && r.y >= cr.y && r.y + r.h <= cr.y + cr.h) { return 0; }
    return MU_CLIP_PART;
}

mu_Container* mu_get_current_container(mu_Context* ctx) {
    mu_expect(ctx.container_stack.idx > 0);
    return ctx.container_stack.items[ctx.container_stack.idx - 1];
}

mu_Container* mu_get_container(mu_Context* ctx, const(char)[] name) {
    mu_Id id = mu_get_id(ctx, name.ptr, name.length);
    return get_container(ctx, id, 0);
}

void mu_bring_to_front(mu_Context* ctx, mu_Container* cnt) {
    cnt.zindex = ++ctx.last_zindex;
}

/*============================================================================
** pool
**============================================================================*/

int mu_pool_init(mu_Context* ctx, mu_PoolItem* items, int len, mu_Id id) {
    int i, n = -1, f = ctx.frame;
    for (i = 0; i < len; i += 1) {
        if (items[i].last_update < f) {
            f = items[i].last_update;
            n = i;
        }
    }
    mu_expect(n > -1);
    items[n].id = id;
    mu_pool_update(ctx, items, n);
    return n;
}

int mu_pool_get(mu_Context* ctx, mu_PoolItem* items, int len, mu_Id id) {
    int i;
    for (i = 0; i < len; i += 1) {
        if (items[i].id == id) { return i; }
    }
    return -1;
}

void mu_pool_update(mu_Context* ctx, mu_PoolItem* items, int idx) {
    items[idx].last_update = ctx.frame;
}

/*============================================================================
** input handlers
**============================================================================*/

void mu_input_mousemove(mu_Context* ctx, int x, int y) {
    ctx.mouse_pos = mu_vec2(x, y);
}

void mu_input_mousedown(mu_Context* ctx, int x, int y, int btn) {
    mu_input_mousemove(ctx, x, y);
    ctx.mouse_down |= btn;
    ctx.mouse_pressed |= btn;
}

void mu_input_mouseup(mu_Context* ctx, int x, int y, int btn) {
    mu_input_mousemove(ctx, x, y);
    ctx.mouse_down &= ~btn;
}

void mu_input_scroll(mu_Context* ctx, int x, int y) {
    ctx.scroll_delta.x += x;
    ctx.scroll_delta.y += y;
}

void mu_input_keydown(mu_Context* ctx, int key) {
    ctx.key_pressed |= key;
    ctx.key_down |= key;
}

void mu_input_keyup(mu_Context* ctx, int key) {
    ctx.key_down &= ~key;
}

void mu_input_text(mu_Context* ctx, const(char)[] text) {
    size_t len = strlen(ctx.input_text.ptr);
    size_t size = text.length;
    mu_expect(len + size <= ctx.input_text.sizeof);
    memcpy(ctx.input_text.ptr + len, text.ptr, size);
    // NOTE(Kapendev): Added this to make it work with slices.
    ctx.input_text[len + size] = '\0';
}

/*============================================================================
** commandlist
**============================================================================*/

mu_Command* mu_push_command(mu_Context* ctx, int type, size_t size) {
    mu_Command* cmd = cast(mu_Command*) (ctx.command_list.items.ptr + ctx.command_list.idx);
    mu_expect(ctx.command_list.idx + size < MU_COMMANDLIST_SIZE);
    cmd.base.type = type;
    cmd.base.size = cast(int) size; // NOTE(Kapendev): Maybe it's `int` because it's easier to guess the size in other languages. No idea.
    ctx.command_list.idx += size;
    return cmd;
}

int mu_next_command(mu_Context* ctx, mu_Command** cmd) {
    if (*cmd) {
        *cmd = cast(mu_Command*) ((cast(char*) *cmd) + (*cmd).base.size);
    } else {
        *cmd = cast(mu_Command*) ctx.command_list.items;
    }
    while (cast(char*) *cmd != ctx.command_list.items.ptr + ctx.command_list.idx) {
        if ((*cmd).type != MU_COMMAND_JUMP) { return 1; }
        *cmd = cast(mu_Command*) (*cmd).jump.dst;
    }
    return 0;
}

void mu_set_clip(mu_Context* ctx, mu_Rect rect) {
    mu_Command* cmd;
    cmd = mu_push_command(ctx, MU_COMMAND_CLIP, mu_ClipCommand.sizeof);
    cmd.clip.rect = rect;
}

void mu_draw_rect(mu_Context* ctx, mu_Rect rect, mu_Color color) {
    mu_Command* cmd;
    rect = mu_intersect_rects(rect, mu_get_clip_rect(ctx));
    if (rect.w > 0 && rect.h > 0) {
        cmd = mu_push_command(ctx, MU_COMMAND_RECT, mu_RectCommand.sizeof);
        cmd.rect.rect = rect;
        cmd.rect.color = color;
    }
}

void mu_draw_box(mu_Context* ctx, mu_Rect rect, mu_Color color) {
    mu_draw_rect(ctx, mu_rect(rect.x + 1, rect.y, rect.w - 2, 1), color);
    mu_draw_rect(ctx, mu_rect(rect.x + 1, rect.y + rect.h - 1, rect.w - 2, 1), color);
    mu_draw_rect(ctx, mu_rect(rect.x, rect.y, 1, rect.h), color);
    mu_draw_rect(ctx, mu_rect(rect.x + rect.w - 1, rect.y, 1, rect.h), color);
}

void mu_draw_text(mu_Context* ctx, mu_Font font, const(char)[] str, mu_Vec2 pos, mu_Color color) {
    mu_Command* cmd;
    mu_Rect rect = mu_rect(pos.x, pos.y, ctx.text_width(font, str), ctx.text_height(font));
    int clipped = mu_check_clip(ctx, rect);
    if (clipped == MU_CLIP_ALL ) { return; }
    if (clipped == MU_CLIP_PART) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
    /* add command */
    // if (len < 0) { len = strlen(str); }
    cmd = mu_push_command(ctx, MU_COMMAND_TEXT, cast(int) mu_TextCommand.sizeof + str.length); // NOTE(Kapendev): KINDA SUS LINE?
    memcpy(cmd.text.str.ptr, str.ptr, str.length);
    cmd.text.str[str.length] = '\0'; // NOTE(Kapendev): Microui uses static strings. Adjust the size in `mu_TextCommand` if necessary.
    cmd.text.pos = pos;
    cmd.text.color = color;
    cmd.text.font = font;
    /* reset clipping if it was set */
    if (clipped) { mu_set_clip(ctx, mu_unclipped_rect); }
}

void mu_draw_icon(mu_Context* ctx, int id, mu_Rect rect, mu_Color color) {
    mu_Command* cmd;
    /* do clip command if the rect isn't fully contained within the cliprect */
    int clipped = mu_check_clip(ctx, rect);
    if (clipped == MU_CLIP_ALL ) { return; }
    if (clipped == MU_CLIP_PART) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
    /* do icon command */
    cmd = mu_push_command(ctx, MU_COMMAND_ICON, mu_IconCommand.sizeof);
    cmd.icon.id = id;
    cmd.icon.rect = rect;
    cmd.icon.color = color;
    /* reset clipping if it was set */
    if (clipped) { mu_set_clip(ctx, mu_unclipped_rect); }
}

/*============================================================================
** layout
**============================================================================*/

void mu_layout_begin_column(mu_Context* ctx) {
    push_layout(ctx, mu_layout_next(ctx), mu_vec2(0, 0));
}

void mu_layout_end_column(mu_Context* ctx) {
    mu_Layout* a; mu_Layout* b;
    b = get_layout(ctx);
    mu_pop(ctx.layout_stack);
    /* inherit position/next_row/max from child layout if they are greater */
    a = get_layout(ctx);
    a.position.x = mu_max(a.position.x, b.position.x + b.body.x - a.body.x);
    a.next_row = mu_max(a.next_row, b.next_row + b.body.y - a.body.y);
    a.max.x = mu_max(a.max.x, b.max.x);
    a.max.y = mu_max(a.max.y, b.max.y);
}

// NOTE(Kapendev): `items` is the length of `widths`. Negative values are allowed in the array.
void mu_layout_row(mu_Context* ctx, int items, const(int)* widths, int height) {
    mu_Layout* layout = get_layout(ctx);
    if (items > 0 && widths) {
        mu_expect(items <= MU_MAX_WIDTHS);
        memcpy(layout.widths.ptr, widths, widths[0].sizeof * items);
    }
    layout.items = items;
    layout.position = mu_vec2(layout.indent, layout.next_row);
    layout.size.y = height;
    layout.item_index = 0;
}

void mu_layout_width(mu_Context* ctx, int width) {
    get_layout(ctx).size.x = width;
}

void mu_layout_height(mu_Context* ctx, int height) {
    get_layout(ctx).size.y = height;
}

void mu_layout_set_next(mu_Context* ctx, mu_Rect r, int relative) {
    mu_Layout* layout = get_layout(ctx);
    layout.next = r;
    layout.next_type = relative ? RELATIVE : ABSOLUTE;
}

mu_Rect mu_layout_next(mu_Context* ctx) {
    mu_Layout* layout = get_layout(ctx);
    mu_Style* style = ctx.style;
    mu_Rect res;

    if (layout.next_type) {
        /* handle rect set by `mu_layout_set_next` */
        int type = layout.next_type;
        layout.next_type = 0;
        res = layout.next;
        if (type == ABSOLUTE) { return (ctx.last_rect = res); }
    } else {
        /* handle next row */
        if (layout.item_index == layout.items) { mu_layout_row(ctx, layout.items, null, layout.size.y); }
        /* position */
        res.x = layout.position.x;
        res.y = layout.position.y;
        /* size */
        res.w = layout.items > 0 ? layout.widths[layout.item_index] : layout.size.x;
        res.h = layout.size.y;
        if (res.w == 0) { res.w = style.size.x + style.padding * 2; }
        if (res.h == 0) { res.h = style.size.y + style.padding * 2; }
        if (res.w <  0) { res.w += layout.body.w - res.x + 1; }
        if (res.h <  0) { res.h += layout.body.h - res.y + 1; }
        layout.item_index++;
    }

    /* update position */
    layout.position.x += res.w + style.spacing;
    layout.next_row = mu_max(layout.next_row, res.y + res.h + style.spacing);
    /* apply body offset */
    res.x += layout.body.x;
    res.y += layout.body.y;
    /* update max position */
    layout.max.x = mu_max(layout.max.x, res.x + res.w);
    layout.max.y = mu_max(layout.max.y, res.y + res.h);
    return (ctx.last_rect = res);
}

/*============================================================================
** controls
**============================================================================*/

void mu_draw_control_frame(mu_Context* ctx, mu_Id id, mu_Rect rect, int colorid, int opt) {
    if (opt & MU_OPT_NOFRAME) { return; }
    colorid += (ctx.focus == id) ? 2 : (ctx.hover == id) ? 1 : 0;
    ctx.draw_frame(ctx, rect, colorid);
}

void mu_draw_control_text(mu_Context* ctx, const(char)[] str, mu_Rect rect, int colorid, int opt) {
    mu_Vec2 pos;
    mu_Font font = ctx.style.font;
    // NOTE(Kapendev): Original was `ctx.text_width(font, str, -1)`. WTF IS LENGTH -1? Now the `int` type makes sense. It's used to call `strlen` for you.
    int tw = ctx.text_width(font, str);
    mu_push_clip_rect(ctx, rect);
    pos.y = rect.y + (rect.h - ctx.text_height(font)) / 2;
    if (opt & MU_OPT_ALIGNCENTER) {
        pos.x = rect.x + (rect.w - tw) / 2;
    } else if (opt & MU_OPT_ALIGNRIGHT) {
        pos.x = rect.x + rect.w - tw - ctx.style.padding;
    } else {
        pos.x = rect.x + ctx.style.padding;
    }
    mu_draw_text(ctx, font, str, pos, ctx.style.colors[colorid]);
    mu_pop_clip_rect(ctx);
}

int mu_mouse_over(mu_Context* ctx, mu_Rect rect) {
    return mu_rect_overlaps_vec2(rect, ctx.mouse_pos) && mu_rect_overlaps_vec2(mu_get_clip_rect(ctx), ctx.mouse_pos) && in_hover_root(ctx);
}

void mu_update_control(mu_Context* ctx, mu_Id id, mu_Rect rect, int opt) {
    int mouseover = mu_mouse_over(ctx, rect);
    if (ctx.focus == id) { ctx.updated_focus = 1; }
    if (opt & MU_OPT_NOINTERACT) { return; }
    if (mouseover && !ctx.mouse_down) { ctx.hover = id; }
    if (ctx.focus == id) {
        if (ctx.mouse_pressed && !mouseover) { mu_set_focus(ctx, 0); }
        if (!ctx.mouse_down && ~opt & MU_OPT_HOLDFOCUS) { mu_set_focus(ctx, 0); }
    }
    if (ctx.hover == id) {
        if (ctx.mouse_pressed) {
            mu_set_focus(ctx, id);
        } else if (!mouseover) {
            ctx.hover = 0;
        }
    }
}

// NOTE(Kapendev): Might need checking. I replaced lines without thinking too much about it. Original code had bugs too btw.
void mu_text(mu_Context* ctx, const(char)[] text) {
    mu_Font font = ctx.style.font;
    mu_Color color = ctx.style.colors[MU_COLOR_TEXT];
    mu_layout_begin_column(ctx);
    int temp_mu_layout_row_value = -1;
    mu_layout_row(ctx, 1, &temp_mu_layout_row_value, ctx.text_height(font));

    if (text.length != 0) {
        const(char)* p = text.ptr;
        const(char)* start = p;
        const(char)* end = p;
        do {
            mu_Rect r = mu_layout_next(ctx);
            int w = 0;
            start = p;
            end = p;
            do {
                const(char)* word = p;
                while (p < text.ptr + text.length && *p != ' ' && *p != '\n') { p += 1; }
                w += ctx.text_width(font, word[0 .. p - word]); // NOTE(Kapendev): Original was `text_width(font, word, cast(int) (p - word)`.
                if (w > r.w && end != start) { break; }
                w += ctx.text_width(font, p[0 .. 1]);           // NOTE(Kapendev): Original was `text_width(font, p, 1)`.
                end = p++;
            } while(end < text.ptr + text.length && *end != '\n');
            mu_draw_text(ctx, font, start[0 .. end - start], mu_vec2(r.x, r.y), color); // NOTE(Kapendev): Original was `mu_draw_text(ctx, font, start, cast(int) (end - start), mu_vec2(r.x, r.y), color)`.
            p = end + 1;
        } while(end < text.ptr + text.length);
    }
    mu_layout_end_column(ctx);
}

void mu_label(mu_Context* ctx, const(char)[] text) {
    mu_draw_control_text(ctx, text, mu_layout_next(ctx), MU_COLOR_TEXT, 0);
}

int mu_button_ex(mu_Context* ctx, const(char)[] label, int icon, int opt) {
    int res = 0;
    // NOTE: Original was `label ?` and new one is `label.ptr ?`. They work the same.
    mu_Id id = label.ptr ? mu_get_id(ctx, label.ptr, label.length) : mu_get_id(ctx, &icon, icon.sizeof);
    mu_Rect r = mu_layout_next(ctx);
    mu_update_control(ctx, id, r, opt);
    /* handle click */
    if (ctx.mouse_pressed == MU_MOUSE_LEFT && ctx.focus == id) { res |= MU_RES_SUBMIT; }
    /* draw */
    mu_draw_control_frame(ctx, id, r, MU_COLOR_BUTTON, opt);
    if (label.ptr) { mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, opt); }
    if (icon) { mu_draw_icon(ctx, icon, r, ctx.style.colors[MU_COLOR_TEXT]); }
    return res;
}

int mu_button(mu_Context* ctx, const(char)[] label) {
    return mu_button_ex(ctx, label, 0, 0);
}

// TODO(Kapendev): Maybe add a type like `mu_StateFlags`.
int mu_checkbox(mu_Context* ctx, const(char)[] label, int* state) {
    int res = 0;
    mu_Id id = mu_get_id(ctx, &state, state.sizeof);
    mu_Rect r = mu_layout_next(ctx);
    mu_Rect box = mu_rect(r.x, r.y, r.h, r.h);
    mu_update_control(ctx, id, r, 0);
    /* handle click */
    if (ctx.mouse_pressed == MU_MOUSE_LEFT && ctx.focus == id) {
        res |= MU_RES_CHANGE;
        *state = !*state;
    }
    /* draw */
    mu_draw_control_frame(ctx, id, box, MU_COLOR_BASE, 0);
    if (*state) {
        mu_draw_icon(ctx, MU_ICON_CHECK, box, ctx.style.colors[MU_COLOR_TEXT]);
    }
    r = mu_rect(r.x + box.w, r.y, r.w - box.w, r.h);
    mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, 0);
    return res;
}

// TODO(Kapendev): Try to change this to a slice too. No idea what `bufsz` is.
int mu_textbox_raw(mu_Context* ctx, char* buf, int bufsz, mu_Id id, mu_Rect r, int opt) {
    int res = 0;
    mu_update_control(ctx, id, r, opt | MU_OPT_HOLDFOCUS);

    if (ctx.focus == id) {
        /* handle text input */
        size_t len = strlen(buf);
        size_t n = mu_min(bufsz - len - 1, strlen(ctx.input_text.ptr));
        if (n > 0) {
            memcpy(buf + len, ctx.input_text.ptr, n);
            len += n;
            buf[len] = '\0';
            res |= MU_RES_CHANGE;
        }
        /* handle backspace */
        if (ctx.key_pressed & MU_KEY_BACKSPACE && len > 0) {
            /* skip utf-8 continuation bytes */
            while ((buf[--len] & 0xc0) == 0x80 && len > 0) {}
            buf[len] = '\0';
            res |= MU_RES_CHANGE;
        }
        /* handle return */
        if (ctx.key_pressed & MU_KEY_RETURN) {
            mu_set_focus(ctx, 0);
            res |= MU_RES_SUBMIT;
        }
    }

    /* draw */
    size_t buflen = strlen(buf); // NOTE(Kapendev): Added this just to make the code work. This is needed because buf has a new size now.
    mu_draw_control_frame(ctx, id, r, MU_COLOR_BASE, opt);
    if (ctx.focus == id) {
        mu_Color color = ctx.style.colors[MU_COLOR_TEXT];
        mu_Font font = ctx.style.font;
        int textw = ctx.text_width(font, buf[0 .. buflen]); // NOTE(Kapendev): Original was `ctx.text_width(font, buf, -1)`.
        int texth = ctx.text_height(font);
        int ofx = r.w - ctx.style.padding - textw - 1;
        int textx = r.x + mu_min(ofx, ctx.style.padding);
        int texty = r.y + (r.h - texth) / 2;
        mu_push_clip_rect(ctx, r);
        mu_draw_text(ctx, font, buf[0 .. buflen], mu_vec2(textx, texty), color); // NOTE(Kapendev): Original has the same -1 value as the above.
        mu_draw_rect(ctx, mu_rect(textx + textw, texty, 1, texth), color);
        mu_pop_clip_rect(ctx);
    } else {
        mu_draw_control_text(ctx, buf[0 .. buflen], r, MU_COLOR_TEXT, opt);
    }
    return res;
}

int mu_textbox_ex(mu_Context* ctx, char* buf, int bufsz, int opt) {
    mu_Id id = mu_get_id(ctx, &buf, buf.sizeof);
    mu_Rect r = mu_layout_next(ctx);
    return mu_textbox_raw(ctx, buf, bufsz, id, r, opt);
}

int mu_textbox(mu_Context* ctx, char* buf, int bufsz) {
    return mu_textbox_ex(ctx, buf, bufsz, 0);
}

int mu_slider_ex(mu_Context* ctx, mu_Real* value, mu_Real low, mu_Real high, mu_Real step, const(char)[] fmt, int opt) {
    char[MU_MAX_FMT + 1] buf;
    mu_Rect thumb;
    int x; int w; int res;
    mu_Real last = *value, v = last;
    mu_Id id = mu_get_id(ctx, &value, value.sizeof);
    mu_Rect base = mu_layout_next(ctx);

    /* handle text input mode */
    if (number_textbox(ctx, &v, base, id)) { return res; }
    /* handle normal mode */
    mu_update_control(ctx, id, base, opt);
    /* handle input */
    if (ctx.focus == id && (ctx.mouse_down | ctx.mouse_pressed) == MU_MOUSE_LEFT) {
        v = low + (ctx.mouse_pos.x - base.x) * (high - low) / base.w;
        if (step) { v = (cast(long) ((v + step / 2) / step)) * step; }
    }
    /* clamp and store value, update res */
    *value = v = mu_clamp(v, low, high);
    if (last != v) { res |= MU_RES_CHANGE; }

    /* draw base */
    mu_draw_control_frame(ctx, id, base, MU_COLOR_BASE, opt);
    /* draw thumb */
    w = ctx.style.thumb_size;
    x = cast(int) ((v - low) * (base.w - w) / (high - low));
    thumb = mu_rect(base.x + x, base.y, w, base.h);
    mu_draw_control_frame(ctx, id, thumb, MU_COLOR_BUTTON, opt);
    /* draw text  */
    // TODO(Kapendev): See how we can remove this stuff with `sprintf`. This is now unsafe if the format string is not null terminated.
    // NOTE(Kapendev): This original was not checking sprintf. Bro...
    int buflen = sprintf(buf.ptr, fmt.ptr, v);
    if (buflen < 0) buflen = 0;
    mu_draw_control_text(ctx, buf[0 .. buflen], base, MU_COLOR_TEXT, opt);
    return res;
}

int mu_slider(mu_Context* ctx, mu_Real* value, mu_Real low, mu_Real high, mu_Real step, const(char)[] fmt) {
    return mu_slider_ex(ctx, value, low, high, step, fmt, 0);
}

int mu_number_ex(mu_Context* ctx, mu_Real* value, mu_Real step, const(char)[] fmt, int opt) {
    char[MU_MAX_FMT + 1] buf;
    int res = 0;
    mu_Id id = mu_get_id(ctx, &value, value.sizeof);
    mu_Rect base = mu_layout_next(ctx);
    mu_Real last = *value;

    /* handle text input mode */
    if (number_textbox(ctx, value, base, id)) { return res; }
    /* handle normal mode */
    mu_update_control(ctx, id, base, opt);
    /* handle input */
    if (ctx.focus == id && ctx.mouse_down == MU_MOUSE_LEFT) { *value += ctx.mouse_delta.x * step; }
    /* set flag if value changed */
    if (*value != last) { res |= MU_RES_CHANGE; }

    /* draw base */
    mu_draw_control_frame(ctx, id, base, MU_COLOR_BASE, opt);
    /* draw text  */
    // TODO(Kapendev): See how we can remove this stuff with `sprintf`. This is now unsafe if the format string is not null terminated.
    // NOTE(Kapendev): This original was not checking sprintf. Bro...
    int buflen = sprintf(buf.ptr, fmt.ptr, *value);
    if (buflen < 0) buflen = 0;
    mu_draw_control_text(ctx, buf[0 .. buflen], base, MU_COLOR_TEXT, opt);
    return res;
}

int mu_number(mu_Context* ctx, mu_Real* value, mu_Real step, const(char)[] fmt) {
    return mu_number_ex(ctx, value, step, fmt, 0);
}

int mu_header_ex(mu_Context* ctx, const(char)[] label, int opt) {
    return header(ctx, label, 0, opt);
}

int mu_header(mu_Context* ctx, const(char)[] label) {
    return mu_header_ex(ctx, label, 0);
}

int mu_begin_treenode_ex(mu_Context* ctx, const(char)[] label, int opt) {
    int res = header(ctx, label, 1, opt);
    if (res & MU_RES_ACTIVE) {
        get_layout(ctx).indent += ctx.style.indent;
        mu_push(ctx.id_stack, ctx.last_id);
    }
    return res;
}

int mu_begin_treenode(mu_Context* ctx, const(char)[] label) {
    return mu_begin_treenode_ex(ctx, label, 0);
}

void mu_end_treenode(mu_Context* ctx) {
    get_layout(ctx).indent -= ctx.style.indent;
    mu_pop_id(ctx);
}

void scrollbar(const(char)[] x, const(char)[] y, const(char)[] w, const(char)[] h)(mu_Context* ctx, mu_Container* cnt, mu_Rect* b, mu_Vec2 cs) {
    /* only add scrollbar if content size is larger than body */
    int maxscroll = cs.y - b.h;
    if (maxscroll > 0 && b.h > 0) {
        mu_Rect base; mu_Rect thumb;
        mu_Id id = mu_get_id(ctx, ("!scrollbar" ~ y).ptr, 11); // NOTE(Kapendev): In C it was something like `#y`.
        /* get sizing/positioning */
        base = *b;
        base.x = b.x + b.w;
        base.w = ctx.style.scrollbar_size;
        /* handle input */
        mu_update_control(ctx, id, base, 0);
        if (ctx.focus == id && ctx.mouse_down == MU_MOUSE_LEFT) { cnt.scroll.y += ctx.mouse_delta.y * cs.y / base.h; }
        /* clamp scroll to limits */
        cnt.scroll.y = mu_clamp(cnt.scroll.y, 0, maxscroll);
        /* draw base and thumb */
        ctx.draw_frame(ctx, base, MU_COLOR_SCROLLBASE);
        thumb = base;
        thumb.h = mu_max(ctx.style.thumb_size, base.h * b.h / cs.y);
        thumb.y += cnt.scroll.y * (base.h - thumb.h) / maxscroll;
        ctx.draw_frame(ctx, thumb, MU_COLOR_SCROLLTHUMB);
        /* set this as the scroll_target (will get scrolled on mousewheel) */
        /* if the mouse is over it */
        if (mu_mouse_over(ctx, *b)) { ctx.scroll_target = cnt; }
    } else {
        cnt.scroll.y = 0;
    }
}

int mu_begin_window_ex(mu_Context* ctx, const(char)[] title, mu_Rect rect, int opt) {
    mu_Rect body;
    mu_Id id = mu_get_id(ctx, title.ptr, title.length);
    mu_Container* cnt = get_container(ctx, id, opt);
    if (!cnt || !cnt.open) { return 0; }
    mu_push(ctx.id_stack, id);

    if (cnt.rect.w == 0) { cnt.rect = rect; }
    begin_root_container(ctx, cnt);
    rect = body = cnt.rect;

    /* draw frame */
    if (~opt & MU_OPT_NOFRAME) {
        ctx.draw_frame(ctx, rect, MU_COLOR_WINDOWBG);
    }

    /* do title bar */
    if (~opt & MU_OPT_NOTITLE) {
        mu_Rect tr = rect;
        tr.h = ctx.style.title_height;
        ctx.draw_frame(ctx, tr, MU_COLOR_TITLEBG);
        /* do title text */
        if (~opt & MU_OPT_NOTITLE) {
            mu_Id id2 = mu_get_id(ctx, "!title".ptr, 6); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
            mu_update_control(ctx, id2, tr, opt);
            mu_draw_control_text(ctx, title, tr, MU_COLOR_TITLETEXT, opt);
            if (id2 == ctx.focus && ctx.mouse_down == MU_MOUSE_LEFT) {
                cnt.rect.x += ctx.mouse_delta.x;
                cnt.rect.y += ctx.mouse_delta.y;
            }
            body.y += tr.h;
            body.h -= tr.h;
        }
        /* do `close` button */
        if (~opt & MU_OPT_NOCLOSE) {
            mu_Id id2 = mu_get_id(ctx, "!close".ptr, 6); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
            mu_Rect r = mu_rect(tr.x + tr.w - tr.h, tr.y, tr.h, tr.h);
            tr.w -= r.w;
            mu_draw_icon(ctx, MU_ICON_CLOSE, r, ctx.style.colors[MU_COLOR_TITLETEXT]);
            mu_update_control(ctx, id2, r, opt);
            if (ctx.mouse_pressed == MU_MOUSE_LEFT && id2 == ctx.focus) { cnt.open = 0; }
        }
    }

    push_container_body(ctx, cnt, body, opt);

    /* do `resize` handle */
    if (~opt & MU_OPT_NORESIZE) {
        int sz = ctx.style.title_height;
        mu_Id id2 = mu_get_id(ctx, "!resize".ptr, 7); // NOTE(Kapendev): Had to change `id` to `id2` because of shadowing.
        mu_Rect r = mu_rect(rect.x + rect.w - sz, rect.y + rect.h - sz, sz, sz);
        mu_update_control(ctx, id2, r, opt);
        if (id2 == ctx.focus && ctx.mouse_down == MU_MOUSE_LEFT) {
            cnt.rect.w = mu_max(96, cnt.rect.w + ctx.mouse_delta.x);
            cnt.rect.h = mu_max(64, cnt.rect.h + ctx.mouse_delta.y);
        }
    }
    /* resize to content size */
    if (opt & MU_OPT_AUTOSIZE) {
        mu_Rect r = get_layout(ctx).body;
        cnt.rect.w = cnt.content_size.x + (cnt.rect.w - r.w);
        cnt.rect.h = cnt.content_size.y + (cnt.rect.h - r.h);
    }
    /* close if this is a popup window and elsewhere was clicked */
    if (opt & MU_OPT_POPUP && ctx.mouse_pressed && ctx.hover_root != cnt) { cnt.open = 0; }
    mu_push_clip_rect(ctx, cnt.body);
    return MU_RES_ACTIVE;
}

int mu_begin_window(mu_Context* ctx, const(char)[] title, mu_Rect rect) {
    return mu_begin_window_ex(ctx, title, rect, 0);
}

void mu_end_window(mu_Context* ctx) {
    mu_pop_clip_rect(ctx);
    end_root_container(ctx);
}

void mu_open_popup(mu_Context* ctx, const(char)[] name) {
    mu_Container* cnt = mu_get_container(ctx, name);
    /* set as hover root so popup isn't closed in begin_window_ex() */
    ctx.hover_root = ctx.next_hover_root = cnt;
    /* position at mouse cursor, open and bring-to-front */
    cnt.rect = mu_rect(ctx.mouse_pos.x, ctx.mouse_pos.y, 1, 1);
    cnt.open = 1;
    mu_bring_to_front(ctx, cnt);
}

int mu_begin_popup(mu_Context* ctx, const(char)[] name) {
    int opt = MU_OPT_POPUP | MU_OPT_AUTOSIZE | MU_OPT_NORESIZE | MU_OPT_NOSCROLL | MU_OPT_NOTITLE | MU_OPT_CLOSED;
    return mu_begin_window_ex(ctx, name, mu_rect(0, 0, 0, 0), opt);
}

void mu_end_popup(mu_Context* ctx) {
    mu_end_window(ctx);
}

void mu_begin_panel_ex(mu_Context* ctx, const(char)[] name, int opt) {
    mu_Container* cnt;
    mu_push_id(ctx, name.ptr, name.length);
    cnt = get_container(ctx, ctx.last_id, opt);
    cnt.rect = mu_layout_next(ctx);
    if (~opt & MU_OPT_NOFRAME) { ctx.draw_frame(ctx, cnt.rect, MU_COLOR_PANELBG); }
    mu_push(ctx.container_stack, cnt);
    push_container_body(ctx, cnt, cnt.rect, opt);
    mu_push_clip_rect(ctx, cnt.body);
}

void mu_begin_panel(mu_Context* ctx, const(char)[] name) {
    mu_begin_panel_ex(ctx, name, 0);
}

void mu_end_panel(mu_Context* ctx) {
    mu_pop_clip_rect(ctx);
    pop_container(ctx);
}
