const isTest = process.env.NODE_ENV === "test";

const targets = isTest
  ? { node: "current" }
  : { browsers: ["last 2 versions"] };
const modules = isTest ? "commonjs" : false;

module.exports = {
  presets: [["env", { targets, modules }]]
};
