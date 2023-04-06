import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import nodeResolve from "rollup-plugin-node-resolve";
import { swc } from "rollup-plugin-swc3";
import replace from "rollup-plugin-replace";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const wasmBytes = Array.from(
  readFileSync(resolve(__dirname, "src/xxhash.wasm"))
);

const output = [
  {
    file: "cjs/xxhash-wasm.cjs",
    format: "cjs",
    sourcemap: true,
    exports: "default",
  },
  { file: "esm/xxhash-wasm.js", format: "es", sourcemap: true },
  {
    file: "umd/xxhash-wasm.js",
    format: "umd",
    name: "xxhash",
    sourcemap: true,
  },
];
const replacements = {
  WASM_PRECOMPILED_BYTES: JSON.stringify(wasmBytes),
};

const swc_config = JSON.parse(
  readFileSync(resolve(__dirname, ".swcrc"), "utf-8")
);

export default {
  input: "src/index.js",
  output,
  plugins: [
    replace(replacements),
    // The config is necessary, because the plugin overwrites some of the settings,
    // instead of just falling back to .swcrc
    swc(swc_config),
    nodeResolve(),
  ],
};
