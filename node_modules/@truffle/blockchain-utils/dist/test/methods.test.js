"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const __1 = __importDefault(require("../"));
const assert_1 = __importDefault(require("assert"));
const mocha_1 = require("mocha");
(0, mocha_1.describe)("BlockchainUtils.parse", () => {
    (0, mocha_1.it)("returns empty parsed object if uri doesn't start with blockchain://", () => {
        const parsed = __1.default.parse("notBlockchain://");
        assert_1.default.deepEqual(parsed, {});
    });
});
//# sourceMappingURL=methods.test.js.map