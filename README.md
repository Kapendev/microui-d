# 🔩 microui-D

A tiny, portable, immediate-mode UI library written in D.
Microui-D is a complete rewrite of [rxi's microui](https://github.com/rxi/microui) library.

## Major Features

* Around `1500 sloc` of D
* Works within a fixed memory region
* Works with any rendering system that can draw rectangles and text
* Easily extensible with custom controls
* WebAssembly support with BetterC
* C interface for cross-language use

## Hello World Example

```d
mu_begin(ctx);
if (mu_begin_window(ctx, "My Window", mu_rect(8, 8, 260, 160))) {
    if (mu_button(ctx, "My Button")) writeln("Hello world!");
    mu_end_window(ctx);
}
mu_end(ctx);
```

## Documentation

TODO
