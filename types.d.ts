declare module "xxhash-wasm" {
  type Exports = {
    h32(input: string, seed?: number): string;
    h32Raw(inputBuffer: Uint8Array, seed?: number): number;
    h64(input: string, seed?: BigInt): string;
    h64Raw(inputBuffer: Uint8Array, seed?: BigInt): BigInt;
  };
  export default function xxhash(): Promise<Exports>;
}
