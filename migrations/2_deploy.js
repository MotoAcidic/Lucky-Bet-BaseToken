const Token = artifacts.require("LuckyToken");

module.exports = function (deployer) {
  deployer.deploy(Token);
};