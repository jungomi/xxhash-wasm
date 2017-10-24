module.exports = {
  parser: "babel-eslint",
  parserOptions: {
    ecmaVersion: 6,
    sourceType: "module",
    ecmaFeatures: {
      jsx: true
    }
  },
  env: {
    es6: true,
    browser: true,
    node: true
  },
  globals: {
    WebAssembly: true
  },
  extends: ["eslint:recommended", "prettier"],
  plugins: ["prettier"],
  rules: {
    "prettier/prettier": "error",
    "brace-style": ["error", "1tbs"],
    "no-unused-vars": "warn",
    "no-var": "error",
    "prefer-const": "warn"
  }
};
