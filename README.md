# xxhash-wasm

[![Build Status][travis-badge]][travis]
[![npm][npm-badge]][npm-link]

A WebAssembly implementation of [xxHash][xxhash].

## Usage

The WebAssembly is contained in the JavaScript bundle, so you don't need to
manually fetch it and create a new WebAssembly instance.

```javascript
import Xxhash from "xxhash-wasm";

// Creates the WebAssembly instance.
const xxhash = new Xxhash();

const input = "The string that is being hashed";
// 32-bit version
xxhash.h32(input).then(h32 => console.log(h32)); // ee563564
// 64-bit version
xxhash.h64(input).then(h64 => console.log(h64)); // 502b0c5fc4a5704c
```

## API

`const xxhash = new Xxhash()`

Create a WebAssembly instance.

`xxhash.h32(input: string, [seed: u32]): Promise<string>`

Generate a 32-bit hash of `input`. The optional `seed` is a `u32` and any number
greater than the maximum (`0xffffffff`) is wrapped, which means that
`0xffffffff + 1 = 0`.

The returned promise resolves with the string of the hash
in hexadecimal.

`xxhash.h64(input: string, [seedHigh: u32, seedLow: u32]): Promise<string>`

Generate a 64-bit hash of `input`. Because JavaScript doesn't support `u64` the
seed is split into two `u32`, where `seedHigh` represents the first 32-bits of
the `u64` and `seedLow` the remaining 32-bits. For example:

```javascript
// Hex
seed64:   ffffffff22222222
seedhigh: ffffffff
seedLow:          22222222

// Binary
seed64:   1111111111111111111111111111111100100010001000100010001000100010
seedhigh: 11111111111111111111111111111111
seedLow:                                  00100010001000100010001000100010
```

Each individual part of the seed is a `u32` and they are also wrapped
individually for numbers greater than the maximum.

The returned promise resolves with the string of the hash in hexadecimal.

[npm-badge]: https://img.shields.io/npm/v/xxhash-wasm.svg?style=flat-square
[npm-link]: https://www.npmjs.com/package/xxhash-wasm
[travis]: https://travis-ci.org/jungomi/xxhash-wasm
[travis-badge]: https://img.shields.io/travis/jungomi/xxhash-wasm/master.svg?style=flat-square
[xxhash]: https://github.com/Cyan4973/xxHash
