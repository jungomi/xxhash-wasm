// The .wasm is filled in by the build process, so the user doesn't need to load
// xxhash.wasm by themselves because it's part of the bundle. Otherwise it
// couldn't be distributed easily as the user would need to host xxhash.wasm
// and then fetch it, to be able to use it.
// eslint-disable-next-line no-undef
const wasmBytes = new Uint8Array(WASM_PRECOMPILED_BYTES);

let encoder;

function writeBufferToMemory(buffer, memory, offset) {
  if (memory.buffer.byteLength < buffer.byteLength + offset) {
    const extraPages = Math.ceil(
      (buffer.byteLength + offset - memory.buffer.byteLength) / (64 * 1024)
    );
    memory.grow(extraPages);
  }
  const u8memory = new Uint8Array(memory.buffer, offset);
  u8memory.set(buffer);
}

async function xxhash() {
  const {
    instance: {
      exports: { mem, xxh32, xxh64 },
    },
  } = await WebAssembly.instantiate(wasmBytes);
  function h32Raw(inputBuffer, seed = 0) {
    writeBufferToMemory(inputBuffer, mem, 0);
    // Logical shift right makes it an u32, otherwise it's interpreted as
    // an i32.
    return xxh32(0, inputBuffer.byteLength, seed) >>> 0;
  }

  function h32(str, seed = 0) {
    if (!encoder) encoder = new TextEncoder();
    const strBuffer = encoder.encode(str);
    return h32Raw(strBuffer, seed).toString(16);
  }

  function h64RawToDataView(inputBuffer, seedHigh = 0, seedLow = 0) {
    writeBufferToMemory(inputBuffer, mem, 8);
    // The first word (64-bit) is used to communicate an u64 between
    // JavaScript and WebAssembly. First the seed will be set from
    // JavaScript and afterwards the result will be set from WebAssembly.
    const dataView = new DataView(mem.buffer);
    dataView.setUint32(0, seedHigh, true);
    dataView.setUint32(4, seedLow, true);
    xxh64(0, inputBuffer.byteLength);
    return dataView;
  }

  function h64Raw(inputBuffer, seedHigh = 0, seedLow = 0) {
    return new Uint8Array(
      h64RawToDataView(inputBuffer, seedHigh, seedLow).buffer,
      0,
      8
    );
  }

  function h64(str, seedHigh = 0, seedLow = 0) {
    if (!encoder) encoder = new TextEncoder();
    const strBuffer = encoder.encode(str);
    const dataView = h64RawToDataView(strBuffer, seedHigh, seedLow);
    const h64str =
      dataView.getUint32(0, true).toString(16) +
      dataView.getUint32(4, true).toString(16).padStart(8, '0');
    return h64str;
  }

  return {
    h32,
    h32Raw,
    h64,
    h64Raw,
  };
}

export default xxhash;
