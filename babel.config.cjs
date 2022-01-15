const isTest = process.env.NODE_ENV === "test";
const isNode = isTest || process.env.TARGET === "node";

// Browsers that support WebAssembly
const supportedBrowsers = {
  chrome: 85,
  edge: 79,
  firefox: 79,
  safari: 15,
};

const targets = isNode ? { node: 16 } : supportedBrowsers;
const modules = isTest ? "commonjs" : false;

module.exports = {
  presets: [["@babel/env", { targets, modules }]],
};
