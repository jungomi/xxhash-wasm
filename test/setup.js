// The build system includes the xxhash.wasm. Just loading the source will not
// work because WASM_PRECOMPILED_BYTES is not defined. To make it work in the
// tests, xxhash.wasm is read from the file system and assigned to global.
const { readFileSync } = require("fs");
const { resolve } = require("path");

const wasmBytes = readFileSync(resolve(__dirname, "../src/xxhash.wasm"));

global.WASM_PRECOMPILED_BYTES = Array.from(wasmBytes);
