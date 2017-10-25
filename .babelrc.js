const isTest = process.env.NODE_ENV === "test";

// Browsers that support WebAssembly
const supportedBrowsers = {
  chrome: 57,
  edge: 16,
  firefox: 53,
  safari: 11
};

const targets = isTest ? { node: "current" } : supportedBrowsers;
const modules = isTest ? "commonjs" : false;

module.exports = {
  presets: [["env", { targets, modules }]]
};
