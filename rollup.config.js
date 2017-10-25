import { readFileSync } from "fs";
import nodeResolve from "rollup-plugin-node-resolve";
import babel from "rollup-plugin-babel";
import uglify from "rollup-plugin-uglify";
import replace from "rollup-plugin-replace";
import { minify } from "uglify-es";

const wasmBytes = Array.from(readFileSync("xxhash.wasm"));

export default {
  input: "src/index.js",
  output: [
    { file: "esm/xxhash-wasm.js", format: "es" },
    { file: "umd/xxhash-wasm.js", format: "umd", name: "Xxhash" }
  ],
  sourcemap: true,
  plugins: [
    replace({
      WASM_PRECOMPILED_BYTES: JSON.stringify(wasmBytes)
    }),
    babel({ exclude: "node_modules/**" }),
    nodeResolve({ jsnext: true }),
    uglify({}, minify)
  ]
};
