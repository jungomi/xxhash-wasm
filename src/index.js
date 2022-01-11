// The .wasm is filled in by the build process, so the user doesn't need to load
// xxhash.wasm by themselves because it's part of the bundle. Otherwise it
// couldn't be distributed easily as the user would need to host xxhash.wasm
// and then fetch it, to be able to use it.
// eslint-disable-next-line no-undef
const wasmBytes = new Uint8Array(WASM_PRECOMPILED_BYTES);

async function xxhash() {
  const {
    instance: {
      exports: { mem, xxh32, xxh64 },
    },
  } = await WebAssembly.instantiate(wasmBytes);

  const encoder = new TextEncoder();
  const defaultSeed = 0;
  const defaultBigSeed = BigInt(0);
  const u64Max = 2n ** 64n - 1n;

  let memory = new Uint8Array(mem.buffer);
  function growMemory(length, offset) {
    if (mem.buffer.byteLength < length + offset) {
      const extraPages = Math.ceil(
        // Wasm pages are spec'd to 64K
        (length + offset - mem.buffer.byteLength) / (64 * 1024)
      );
      mem.grow(extraPages);
      // After growing, the original memory's ArrayBuffer is detached, so we'll
      // need to replace our view over it with a new one over the new backing
      // ArrayBuffer.
      memory = new Uint8Array(mem.buffer);
    }
  }

  function h32Raw(inputBuffer, seed = defaultSeed) {
    growMemory(inputBuffer.byteLength, 0);
    memory.set(inputBuffer, 0);
    // Logical shift right makes it an u32, otherwise it's interpreted as
    // an i32.
    return xxh32(0, inputBuffer.byteLength, seed) >>> 0;
  }

  function h32(str, seed = defaultSeed) {
    // https://developer.mozilla.org/en-US/docs/Web/API/TextEncoder/encodeInto#buffer_sizing
    // By sizing the buffer to 3 * string-length we guarantee that the buffer
    // will be appropriately sized for the utf-8 encoding of the string.
    growMemory(str.length * 3, 0);
    const { written } = encoder.encodeInto(str, memory);
    return (xxh32(0, written, seed) >>> 0).toString(16).padStart(8, "0");
  }

  function h64Raw(inputBuffer, seed = defaultBigSeed) {
    growMemory(inputBuffer.byteLength, 0);
    memory.set(inputBuffer, 0);
    // BigInts are arbitrary precision and signed, so to get the "correct"
    // u64 value from the return, we'll need to force that interpretation.
    return xxh64(0, inputBuffer.byteLength, seed) & u64Max;
  }

  function h64(str, seed = defaultBigSeed) {
    growMemory(str.length * 3, 0);
    const { written } = encoder.encodeInto(str, memory);
    return (xxh64(0, written, seed) & u64Max).toString(16).padStart(16, "0");
  }

  return {
    h32,
    h32Raw,
    h64,
    h64Raw,
  };
}

export default xxhash;
