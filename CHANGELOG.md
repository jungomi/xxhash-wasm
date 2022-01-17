# Changelog

This changelog keeps all release notes in one place and mirrors the release
notes from the [GitHub releases][github-releases], except for older versions,
where no GitHub releases had been created.

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
