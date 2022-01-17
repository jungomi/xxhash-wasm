/* eslint-disable no-console */
const Benchmark = require("benchmark");
const xxhash = require("xxhash-wasm");
const XXH = require("xxhashjs");

// This is the highest utf-8 character that uses only one byte. A string will be
// randomly generated and this makes the number of bytes consitent/predictable.
const highestSingleByteChar = 0x7f;

function randomString(numBytes) {
  // If number of bytes is too high it will result in a stackoverflow.
  // To circumvent that the string is generated in chunks.
  const strings = [];
  const numChunks = Math.ceil(numBytes / 1e5);
  for (let i = 1; i <= numChunks; i++) {
    const bytes =
      i === numChunks && numBytes % 1e5 !== 0 ? numBytes % 1e5 : 1e5;
    const codePoints = Array(bytes)
      .fill()
      .map(() => Math.floor(Math.random() * (highestSingleByteChar + 1)));
    strings.push(String.fromCodePoint(...codePoints));
  }
  return "".concat(...strings);
}

const handlers = {
  onCycle(event) {
    console.log(String(event.target));
  },
  onComplete() {
    const fastest = this.filter("fastest").map("name");
    console.log(`Benchmark ${this.name} - Fastest is ${fastest}`);
  },
};

const seed = 0;
const seedBigInt = 0n;

async function runBench() {
  console.time("wasm setup");
  const { h32, h64 } = await xxhash();
  console.timeEnd("wasm setup");

  for (let i = 1; i <= 1e8; i *= 10) {
    const suite = new Benchmark.Suite(`${i} bytes`, handlers);
    const input = randomString(i);

    suite
      .add("xxhashjs#h32", () => {
        XXH.h32(input, seed).toString(16);
      })
      .add("xxhashjs#h64", () => {
        XXH.h64(input, seed).toString(16);
      })
      .add("xxhash-wasm#h32", () => {
        h32(input, seed);
      })
      .add("xxhash-wasm#h64", () => {
        h64(input, seedBigInt);
      })
      .run();
  }
}

runBench();
