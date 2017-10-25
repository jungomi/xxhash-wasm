import nodeResolve from "rollup-plugin-node-resolve";
import babel from "rollup-plugin-babel";
import uglify from "rollup-plugin-uglify";
import { minify } from "uglify-es";

export default {
  input: "src/index.js",
  output: [
    { file: "esm/xxhash-wasm.js", format: "es" },
    { file: "umd/xxhash-wasm.js", format: "umd", name: "Xxhash" }
  ],
  sourcemap: true,
  plugins: [
    babel({ exclude: "node_modules/**" }),
    nodeResolve({ jsnext: true }),
    uglify({}, minify)
  ]
};
