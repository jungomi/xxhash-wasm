# Changelog

This changelog keeps all release notes in one place and mirrors the release
notes from the [GitHub releases][github-releases], except for older versions,
where no GitHub releases had been created.

## v1.0.1

- Export data types separately + fixed bigint data type (#28)

## v1.0.0

This big release includes an up to a 3-4x performance improvement in most cases and a new streaming API similar to Node's built-in `crypto` API. To fully utilise the performance improvements, there are some breaking changes in the API and newer engine requirements.

### 3-4x Performance improvements

To achieve these substantial performance improvements, a handful of new features have been used, which are fairly recent additions to the browsers, Node and the WebAssembly specification.
These include the following:

1. [`BigInt`][bigint-mdn] support in WebAssembly
2. Bulk memory operations in WebAssembly
3. [`TextEncoder.encodeInto`][textencoder-encodeinto-mdn]

Taking all of these requirements into account, `v1.0.0` should be compatible with:

- Chrome >= 85
- Edge >= 79
- Firefox >= 79
- Safari >= 15.0
- Node >= 15.0

If support for an older engine is required, `xxhash-wasm@0.4.2` is available with much broader engine support, but 3-4x slower hashing performance.

Besides the features regarding memory optimisations for WebAssembly, the biggest addition is the use of [`BigInt`][bigint-mdn], which avoids the whole workaround that was previously used in order to represent `u64` integers in JavaScript.
That makes everything a lot simpler and faster, but that also brings some breaking changes of the 64-bit API.

The [`TextEncoder.encodeInto`][textencoder-encodeinto-mdn] allows to encode the string as UTF-8 bytes directly into the WebAssembly memory, meaning that if you have the string and hash it directly, it will be faster than encoding it yourself and then using the `Raw` API.
*If possible, defer the encoding of the string to the hashing, unless you need to use the encoded string (bytes) for other purposes as well, or you are creating the bytes differently (e.g. different encoding), in which case it's much more efficient to use the `h**Raw` APIs instead of having to unnecessarily convert them to a string first.*

### Streaming API

The streaming API allows to build up the input that is being hashed in an iterative manner, which is particularly helpful for larger inputs which are collected over time instead of having it all at once in memory.
It is kept in line with Node's `crypto.createHash`, hence the streams are initialised with `create32`/`create64` and then `.update(string | Uint8Array)` is used to add an input, which can either be a `string` or a `Uint8Array`, and finally `.digest()` needs to be called to finalise the hash.

```javascript
const { create32, create64 } = await xxhash();

// 32-bit version
create32()
  .update("some data")
  // update accepts either a string or Uint8Array
  .update(Uint8Array.from([1, 2, 3]))
  .digest(); // 955607085

// 64-bit version
create64()
  .update("some data")
  // update accepts either a string or Uint8Array
  .update(Uint8Array.from([1, 2, 3]))
  .digest(); // 883044157688673477n
```

### Breaking Changes

#### 64-bit seed as [`BigInt`][bigint-mdn]

64-bit hash APIs now use [`BigInt`][bigint-mdn], where the `seed` is now a single [`BigInt`][bigint-mdn] instead of being split into the two halves `seedHigh` and `seedLow`.
This makes it much simpler to use and avoids any workarounds for previous limitations.

<table align="center">
<tbody>
<tr>
<th>0.4.2</th>
<th>1.0.0</th>
</tr>
<tr valign="top">
<td>

```typescript
h64(input: string, [seedHigh: u32, seedLow: u32]): string
h64Raw(input: Uint8Array, [seedHigh: u32, seedLow: u32]): Uint8Array
```
</td>
<td>

```typescript
h64(input: string, [seed: BigInt]): BigInt
h64ToString(input: string, [seed: BigInt]): string
h64Raw(input: Uint8Array, [seed: BigInt]): BigInt
```

</td>
</tr>
</tbody>
</table>

#### `h32`/`h64` return numbers instead of strings

The hashes are numbers but were previously converted to a string of their a zero-padded hex string representations, mainly to keep the 32-bit in line with the 64-bit version, which could not be expressed by a single number without [`BigInt`][bigint-mdn].
This overhead is unnecessary for many applications and therefore the performance suffers. Now `h32` returns a `number` and `h64` a [`BigInt`][bigint-mdn].
For convenience, `h32ToString` and `h64ToString` have been added to get the hash as a string, which can also be achieved by converting them manually, e.g. `hash64.toString(16).padStart(16, "0")`.

<table align="center">
<tbody>
<tr>
<th>0.4.2</th>
<th>1.0.0</th>
</tr>
<tr valign="top">
<td>

```typescript
h32(input: string, [seed: u32]): string
h64(input: string, [seedHigh: u32, seedLow: u32]): string
```
</td>
<td>

```typescript
h32(input: string, [seed: u32]): number
h64(input: string, [seed: BigInt]): BigInt

// New *ToString methods for convenience and to get old behaviour
h32ToString(input: string, [seed: u32]): string
h64ToString(input: string, [seed: BigInt]): string
```

</td>
</tr>
</tbody>
</table>

[bigint-mdn]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt
[textencoder-encodeinto-mdn]: https://developer.mozilla.org/en-US/docs/Web/API/TextEncoder/encodeInto

## v0.4.2

- Fix 64-bit hex representation when second part has leading zeros (#23)

## v0.4.1

 - Initialise `TextEncoder` lazily

## v0.4.0

- TypeScript definitions
- `h32Raw` and `h64Raw` APIs for use with `Uint8Array`

## v0.3.1

WebAssembly is optimised by binaryen:

- Faster
- Smaller

## v0.3.0

New API to avoid reinitialising WASM instances

## v0.2.0

Include a CommonJS bundle for Node.js


[github-releases]: https://github.com/jungomi/xxhash-wasm/releases
