import { xxhash } from "./xxhash";

// The .wasm is filled in by the build process, so the user doesn't need to load
// xxhash.wasm by themselves because it's part of the bundle. Otherwise it
// couldn't be distributed easily as the user would need to host xxhash.wasm
// and then fetch it, to be able to use it.
// eslint-disable-next-line no-undef
const wasmBytes = new Uint8Array(WASM_PRECOMPILED_BYTES);

export default async function () {
  return xxhash((await WebAssembly.instantiate(wasmBytes)).instance);
}
