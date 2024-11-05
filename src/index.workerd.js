import { xxhash } from "./xxhash";

// In CloudFlare workerd we must use import to prevent code injection.
import module from "./xxhash.wasm";

export default async function () {
  return xxhash(await WebAssembly.instantiate(module));
}
