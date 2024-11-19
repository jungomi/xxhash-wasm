import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import copy from "rollup-plugin-copy";
import nodeResolve from "rollup-plugin-node-resolve";
import replace from "rollup-plugin-replace";
import { swc } from "rollup-plugin-swc3";
import { fileURLToPath } from "url";

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

const plugins = [
  replace(replacements),
  // The config is necessary, because the plugin overwrites some of the settings,
  // instead of just falling back to .swcrc
  swc(swc_config),
  nodeResolve(),
];

export default [
  {
    input: "src/index.js",
    output,
    plugins,
  },
  {
    input: "src/index.workerd.js",
    output: { file: "workerd/xxhash-wasm.js", format: "es", sourcemap: true },
    external: /\.wasm$/,
    plugins: [
      ...plugins,
      copy({
        targets: [{ src: "src/xxhash.wasm", dest: "workerd" }],
      }),
    ],
  },
];
