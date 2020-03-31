declare module 'xxhash-wasm' {
    type Exports = {
        h32(input: string, seed?: number): string;
        h64(input: string, seedHigh?: number, seedLow?: number): string;
    };
    export default function xxhash(): Promise<Exports>;
}