export default class Xxhash {
  constructor(wasmBuffer) {
    this.wasmInstance = WebAssembly.instantiate(wasmBuffer).then(
      wasmResult => wasmResult.instance
    );
  }

  async h32(str, seed = 0) {
    const strBuffer = new TextEncoder("utf-8").encode(str);
    const { exports: { mem, xxh32 } } = await this.wasmInstance;
    this.writeBufferToMemory(strBuffer, mem, 0);
    // Logical shift right makes it an u32, otherwise it's interpreted as i32.
    const h32 = xxh32(0, strBuffer.byteLength, seed) >>> 0;
    return h32.toString(16);
  }

  async h64(str, seedHigh = 0, seedLow = 0) {
    const strBuffer = new TextEncoder("utf-8").encode(str);
    const { exports: { mem, xxh64 } } = await this.wasmInstance;
    this.writeBufferToMemory(strBuffer, mem, 8);
    // The first word (64-bit) is used to communicate an u64 between JavaScript
    // and WebAssembly. First the seed will be set from JavaScript and
    // afterwards the result will be set from WebAssembly.
    const dataView = new DataView(mem.buffer);
    dataView.setUint32(0, seedHigh, true);
    dataView.setUint32(4, seedLow, true);
    xxh64(0, strBuffer.byteLength);
    const h64 =
      dataView.getUint32(0, true).toString(16) +
      dataView.getUint32(4, true).toString(16);
    return h64;
  }

  writeBufferToMemory(buffer, memory, offset) {
    if (memory.buffer.byteLength < buffer.byteLength + offset) {
      const extraPages = Math.ceil(
        (buffer.byteLength + offset - memory.buffer.byteLength) / (64 * 1024)
      );
      memory.grow(extraPages);
    }
    const u8memory = new Uint8Array(memory.buffer, offset);
    u8memory.set(buffer);
  }
}
