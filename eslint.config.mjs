import prettier from "eslint-plugin-prettier";
import globals from "globals";
import babelParser from "@babel/eslint-parser";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

export default [
  {
    ignores: [
      "bench/node_modules",
      "**/coverage",
      "**/cjs",
      "**/esm",
      "**/umd",
      "**/workerd",
    ],
  },
  ...compat.extends("eslint:recommended", "prettier"),
  {
    plugins: {
      prettier,
    },

    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        BigInt: true,
        WebAssembly: true,
      },

      parser: babelParser,
      ecmaVersion: 6,
      sourceType: "module",

      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },

        requireConfigFile: false,
      },
    },

    rules: {
      "prettier/prettier": "error",
      "brace-style": ["error", "1tbs"],
      "no-unused-vars": "warn",
      "no-var": "error",
      "prefer-const": "warn",
    },
  },
];
