export default {
  setupFiles: ["<rootDir>/test/setup.js"],
  transform: {
    "^.+\\.(t|j)sx?$": "@swc/jest",
  },
};
