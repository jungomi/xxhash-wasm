const isTest = process.env.NODE_ENV === "test";
const isNode = isTest || process.env.TARGET === "node";

// Browsers that support WebAssembly
const supportedBrowsers = {
  chrome: 57,
  edge: 16,
  firefox: 53,
  safari: 11
};

const targets = isNode ? { node: 10 } : supportedBrowsers;
const modules = isTest ? "commonjs" : false;

module.exports = {
  presets: [["@babel/env", { targets, modules }]]
};
