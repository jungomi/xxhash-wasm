module.exports = {
  parser: "@babel/eslint-parser",
  parserOptions: {
    ecmaVersion: 6,
    sourceType: "module",
    ecmaFeatures: {
      jsx: true,
    },
    requireConfigFile: false,
  },
  env: {
    es2020: true,
    es6: true,
    browser: true,
    node: true,
  },
  globals: {
    WebAssembly: true,
  },
  extends: ["eslint:recommended", "prettier"],
  plugins: ["prettier"],
  rules: {
    "prettier/prettier": "error",
    "brace-style": ["error", "1tbs"],
    "no-unused-vars": "warn",
    "no-var": "error",
    "prefer-const": "warn",
  },
};
