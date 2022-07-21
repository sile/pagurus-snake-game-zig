pagurus-snake-game-zig
======================

Zig port of an example game for [Pagurus] game engine.

This example only depends on the Zig standard library.

Demo site:
- https://sile.github.io/pagurus-snake-game-zig/
- Operation:
  - Move: up / down / left / right keys
  - Enter: enter key

Differences from the original example:
- Doesn't play sounds
- Doesn't handle mouse events

https://user-images.githubusercontent.com/181413/180329784-c10ae3b3-cc00-4c1e-8e34-d477929e7399.mp4

[Pagurus]: https://github.com/sile/pagurus

Zig Version
-----------

v0.9.1

Build
-----

```console
$ zig build
$ ls zig-out/lib/snake.wasm
```

The game built to a WebAssembly file) can run on Web browsers, Android devices, terminals and
other SLD2 supported platforms by using runtimes provided by [Pagurus].
