# xxhash-wasm

[![Build Status][travis-badge]][travis]
[![npm][npm-badge]][npm-link]

A WebAssembly implementation of [xxHash][xxhash].

## Installation


### From npm

```sh
npm install --save xxhash-wasm
```

Or with Yarn:

```sh
yarn add xxhash-wasm
```

### From [Unpkg][unpkg]

#### ES Modules

```html
<script type="module">
  import xxhash from "https://unpkg.com/xxhash-wasm/esm/xxhash-wasm.js";
</script>
```

#### UMD build

```html
<script src="https://unpkg.com/xxhash-wasm/umd/xxhash-wasm.js"></script>
```

The global `xxhash` will be available.

## Usage

The WebAssembly is contained in the JavaScript bundle, so you don't need to
manually fetch it and create a new WebAssembly instance.

```javascript
import xxhash from "xxhash-wasm";

// Creates the WebAssembly instance.
xxhash().then(hasher => {
  const input = "The string that is being hashed";
  // 32-bit version
  hasher.h32(input); // ee563564
  // 64-bit version
  hasher.h64(input); // 502b0c5fc4a5704c
});
```

Or with `async`/`await` and destructuring:

```javascript
// Creates the WebAssembly instance.
const { h32, h64 } = await xxhash();

const input = "The string that is being hashed";
// 32-bit version
h32(input); // ee563564
// 64-bit version
h64(input); // 502b0c5fc4a5704c
```

### Node

This was initially meant for the browser, but Node 8 also added support for
WebAssembly, so it can be run in Node as well. The implementation uses
the browser API [`TextEncoder`][textencoder-mdn], which is has been added
recently to Node as [`util.TextEncoder`][textencoder-node], but it is not
a global. To compensate for that, a CommonJS bundle is created which
automatically imports `util.TextEncoder`.

*Note: You will see a warning that it's experimental, but it should work just
fine.*

The `main` field in `package.json` points to the CommonJS bundle, so you can
require it as usual.

```javascript
const xxhash = require("xxhash-wasm");

// Or explicitly use the cjs bundle
const xxhash = require("xxhash-wasm/cjs/xxhash-wasm");
```

If you want to bundle your application for Node with a module bundler that uses
the `module` field in `package.json`, such as webpack or Rollup, you will need
to explicitly import `xxhash-wasm/cjs/xxhash-wasm` otherwise the browser version
is used.

## API

`const { h32, h64 } = await xxhash()`

Create a WebAssembly instance.

`h32(input: string, [seed: u32]): string`

Generate a 32-bit hash of `input`. The optional `seed` is a `u32` and any number
greater than the maximum (`0xffffffff`) is wrapped, which means that
`0xffffffff + 1 = 0`.

Returns a string of the hash in hexadecimal.

`h64(input: string, [seedHigh: u32, seedLow: u32]): string`

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

Returns a string of the hash in hexadecimal.

[npm-badge]: https://img.shields.io/npm/v/xxhash-wasm.svg?style=flat-square
[npm-link]: https://www.npmjs.com/package/xxhash-wasm
[textencoder-mdn]: https://developer.mozilla.org/en-US/docs/Web/API/TextEncoder/TextEncoder
[textencoder-node]: https://nodejs.org/api/util.html#util_class_util_textencoder
[travis]: https://travis-ci.org/jungomi/xxhash-wasm
[travis-badge]: https://img.shields.io/travis/jungomi/xxhash-wasm/master.svg?style=flat-square
[unpkg]: https://unpkg.com/
[xxhash]: https://github.com/Cyan4973/xxHash
