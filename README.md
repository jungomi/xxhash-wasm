# xxhash-wasm

[![Node.js][actions-nodejs-badge]][actions-nodejs-link]
[![npm][npm-badge]][npm-link]

A WebAssembly implementation of [xxHash][xxhash], a fast non-cryptographic hash
algorithm. It can be called seamlessly from JavaScript. You can use it like any
other JavaScript library but still get the benefits of WebAssembly, no special
setup needed.

## Table of Contents

<!-- vim-markdown-toc GFM -->

* [Installation](#installation)
  * [From npm](#from-npm)
  * [From Unpkg](#from-unpkg)
    * [ES Modules](#es-modules)
    * [UMD build](#umd-build)
* [Usage](#usage)
  * [Streaming](#streaming)
  * [Node](#node)
  * [Performance](#performance)
  * [Engine Requirements](#engine-requirements)
* [API](#api)
* [Comparison to xxhashjs](#comparison-to-xxhashjs)
  * [Benchmarks](#benchmarks)
  * [Bundle size](#bundle-size)

<!-- vim-markdown-toc -->

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
const { h32, h64, h32Raw, h64Raw } = await xxhash();

const input = "The string that is being hashed";
// 32-bit version
h32(input); // ee563564
// 64-bit version
h64(input); // 502b0c5fc4a5704c
```

### Streaming

`xxhash-wasm` supports a `crypto`-like streaming api, useful for avoiding memory consumption when hashing large amounts of data:

```javascript
const { create32, create64 } = await xxhash();

// 32-bit version
create32()
  .update("some data")
  .update(Uint8Array.from([1, 2, 3]))
  .digest(); // 955607085

// 64-bit version
create64()
  .update("some data")
  .update(Uint8Array.from([1, 2, 3]))
  .digest(); // 883044157688673477n
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

### Performance

For performance sensitive applications, `xxhash-wasm` provides the `h**String` and `h**Raw` APIs, which return raw numeric hash results rather than zero-padded hex strings. The overhead of the string conversion can be as much as 20% of overall runtime when hashing small byte-size inputs, and the string result is often inconsequential (if one is simply going to compare the results). When necessary, getting a zero-padded hex string from the provided `number` or `BigInt` results is easily achieved via `result.toString(16).padStart(16, "0")`.

The `h**`, `h**String`, and streaming APIs make use of `TextEncoder.encodeInto` to directly encode strings as a stream of UTF-8 bytes into the webassembly memory buffer, meaning that for string-hashing purposes, these APIs will be significantly faster than converting the string to bytes externally and using the `Raw` API. That said, for large strings it may be beneficial to consider the streaming API or another approach to encoding, as `encodeInto` is forced to allocate 3-times the string length to account for the chance the input string contains high-byte-count code units.

### Engine Requirements

In an effort to make this library as performant as possible it makes use of several recent additions to browsers, Node, and the Webassembly specification. Notably, this includes:

1. `BigInt` support in WebAssembly
2. Bulk memory operations in WebAssembly
3. `TextEncoder.encodeInto`

Taking all of these requirements into account, `xxhash-wasm` should be compatible with:
* Chrome >= 85
* Firefox >= 79
* Safari >= 15.0
* Node >= 15.0

If support for an older engine is required, `xxhash-wasm` 0.4.2 is available with more limited engine requirements, with 3-4x slower hashing performance.

## API

`const { h32, h64 } = await xxhash()`

Create a WebAssembly instance.

`h32(input: string, [seed: u32]): string`

Generate a 32-bit hash of the UTF-8 encoded bytes of `input`. The optional
`seed` is a `u32` and any number greater than the maximum (`0xffffffff`) is
wrapped, which means that `0xffffffff + 1 = 0`.

Returns a string of the hash in hexadecimal, zero padded.

`h32String(input: string, [seed: u32]): number`

Same as `h32`, but returning a `number`. This avoids the overhead of the string formatting of the result.

`h32Raw(input: Uint8Array, [seed: u32]): number`

Same as `h32` but with a `Uint8Array` as input instead of a `string` and returns the
hash as a `number`.

`create32([seed: number]): Hash<number>`

Create a 32-bit hash for streaming applications. See `Hash<T>` below.

`h64(input: string, [seed: BigInt]): string`

Generate a 64-bit hash of the UTF-8 encoded bytes of `input`. The optional
`seed` is a `u64` provided as a BigInt.

Returns a zero-padded string of the hash in hexadecimal.

`h64String(input: string, [seed: BigInt]): BigInt`

Same as `h64`, but returning a `BigInt`. This avoids the overhead of the string formatting of the result.

`h64Raw(input: Uint8Array, [seed: BigInt]): BigInt`

Same as `h64` but with a `Uint8Array` as input, returning an unformatted `BigInt` 
hash value.

`create64([seed: BigInt]): Hash<BigInt>`

Create a 64-bit hash for streaming applications. See `Hash<T>` below.

`type Hash<T> {
  update(input: string | Uint8Array): Hash<T>;
  digest(): T
}`

The streaming API mirrors Node's built-in `crypto.createHash`, providing
`update` and `digest` methods to add data to the hash and compute the final hash
value, respectively.

## Comparison to [xxhashjs][xxhashjs]

[`xxhashjs`][xxhashjs] is implemented in pure JavaScript and because JavaScript
is lacking support for 64-bit integers, it uses a workaround with
[`cuint`][cuint]. Not only is that a big performance hit, but it also increases
the bundle size by quite a bit when it's used in the browser.

This library (`xxhash-wasm`) has the big advantage that WebAssembly supports
`u64` and also some instructions (e.g. `rotl`), which would otherwise have
to be emulated. However, The downside is that you have to initialise
a WebAssembly instance, which takes a little over 2ms in Node and about 1ms in
the browser. But once the instance is created, it can be used without any
further overhead. For the benchmarks below, the instantiation is done before the
benchmark and therefore it's excluded from the results, since it wouldn't make
sense to always create a new WebAssembly instance.

### Benchmarks

Benchmarks are using [Benchmark.js][benchmarkjs] with random strings of
different lengths. *Higher is better*

| String length             | xxhashjs 32-bit    | xxhashjs 64-bit    | xxhash-wasm 32-bit      | xxhash-wasm 64-bit      |
| ------------------------: | ------------------ | ------------------ | ----------------------- | ----------------------- |
| 1 byte                    | 513,517 ops/sec    | 11,896 ops/sec     | 2,122,322 ops/sec       | ***3,556,437 ops/sec*** |
| 10 bytes                  | 552,133 ops/sec    | 12,953 ops/sec     | 2,075,154 ops/sec       | ***3,196,204 ops/sec*** |
| 100 bytes                 | 425,277 ops/sec    | 10,838 ops/sec     | 1,867,002 ops/sec       | ***3,169,921 ops/sec*** |
| 1,000 bytes               | 102,165 ops/sec    | 6,697 ops/sec      | 1,468,336 ops/sec       | ***2,393,906 ops/sec*** |
| 10,000 bytes              | 13,010 ops/sec     | 1,452 ops/sec      | 446,415 ops/sec         | ***787,430 ops/sec***   |
| 100,000 bytes             | 477 ops/sec        | 146 ops/sec        | 58,339 ops/sec          | ***91,895 ops/sec***    |
| 1,000,000 bytes           | 36.40 ops/sec      | 12.93 ops/sec      | 5,443 ops/sec           | ***8,379 ops/sec***     |
| 10,000,000 bytes          | 3.12 ops/sec       | 1.19 ops/sec       | 307 ops/sec             | ***417 ops/sec***       |
| 100,000,000 bytes         | 0.31 ops/sec       | 0.13 ops/sec       | 28.70 ops/sec           | ***35.63 ops/sec***     |

`xxhash-wasm` outperforms `xxhashjs` significantly, the 32-bit is up to 98 times
faster (generally increases as the size of the input grows), and the 64-bit is 
up to 350 times faster (generally increases as the size of the input grows).

The 64-bit version is the faster algorithm, and retains a performance advantage
over all lengths over xxhashjs and the 32-bit algorithm.

`xxhash-wasm` also significantly outperforms Node's built-in hash algorithms,
making it suitable for use in a wide variety of situations. Benchmarks from
an x64 MacBook Pro running Node 17.3:

| String length             | Node `crypto` md5  | Node `crypto` sha1 |  xxhash-wasm 64-bit     |
| ------------------------: | ------------------ | ------------------ | ----------------------- |
| 1 byte                    | 342,924 ops/sec    | 352,825 ops/sec    | ***3,556,437 ops/sec*** |
| 10 bytes                  | 356,596 ops/sec    | 352,209 ops/sec    | ***3,196,204 ops/sec*** |
| 100 bytes                 | 354,898 ops/sec    | 355,024 ops/sec    | ***3,169,921 ops/sec*** |
| 1,000 bytes               | 249,242 ops/sec    | 271,383 ops/sec    | ***2,393,906 ops/sec*** |
| 10,000 bytes              | 62,896 ops/sec     | 80,986 ops/sec     | ***787,430 ops/sec***   |
| 100,000 bytes             | 7,316 ops/sec      | 10,198 ops/sec     | ***91,895 ops/sec***    |
| 1,000,000 bytes           | 698 ops/sec        | 966 ops/sec        | ***8,379 ops/sec***     |
| 10,000,000 bytes          | 58.98 ops/sec      | 79.78 ops/sec      | ***417 ops/sec***       | 
| 100,000,000 bytes         | 6.30 ops/sec       | 8.20 ops/sec       | ***35.63 ops/sec***     |

If suitable for your use case, the `Raw` API offers significant throughput
improvements over the string-hashing API, particularly for smaller inputs:

| String length             | xxhash-wasm 64-bit Raw  |  xxhash-wasm 64-bit |
| ------------------------: | ----------------------- | ------------------- |
| 1 byte                    | ***9,342,811 ops/sec*** | 3,556,437 ops/sec   |
| 10 bytes                  | ***9,668,989 ops/sec*** | 3,196,204 ops/sec   |
| 100 bytes                 | ***8,775,845 ops/sec*** | 3,169,921 ops/sec   |
| 1,000 bytes               | ***5,541,403 ops/sec*** | 2,393,906 ops/sec   |
| 10,000 bytes              | ***1,079,866 ops/sec*** | 787,430 ops/sec     |
| 100,000 bytes             | ***113,350 ops/sec***   | 91,895 ops/sec      |
| 1,000,000 bytes           | ***9,779 ops/sec***     | 8,379 ops/sec       |
| 10,000,000 bytes          | ***563 ops/sec***       | 417 ops/sec         | 
| 100,000,000 bytes         | ***43.77 ops/sec***     | 35.63 ops/sec       |

### Bundle size

Both libraries can be used in the browser and they provide a UMD bundle. The
bundles are self-contained, that means they can be included and used without
having to add any other dependencies. The table shows the bundle size of the
minified versions. *Lower is better*.

|                | xxhashjs   | xxhash-wasm   |
| -------------- | ---------- | ------------- |
| Bundle size    | 41.5kB     | ***11.4kB***  |
| Gzipped Size   | 10.3kB     | ***2.3kB***   |

[actions-nodejs-badge]: https://github.com/jungomi/xxhash-wasm/actions/workflows/nodejs.yml/badge.svg
[actions-nodejs-link]: https://github.com/jungomi/xxhash-wasm/actions/workflows/nodejs.yml
[benchmarkjs]: https://benchmarkjs.com/
[cuint]: https://github.com/pierrec/js-cuint
[npm-badge]: https://img.shields.io/npm/v/xxhash-wasm.svg?style=flat-square
[npm-link]: https://www.npmjs.com/package/xxhash-wasm
[textencoder-mdn]: https://developer.mozilla.org/en-US/docs/Web/API/TextEncoder/TextEncoder
[textencoder-node]: https://nodejs.org/api/util.html#util_class_util_textencoder
[travis]: https://travis-ci.org/jungomi/xxhash-wasm
[travis-badge]: https://img.shields.io/travis/jungomi/xxhash-wasm/master.svg?style=flat-square
[unpkg]: https://unpkg.com/
[xxhash]: https://github.com/Cyan4973/xxHash
[xxhashjs]: https://github.com/pierrec/js-xxhash
