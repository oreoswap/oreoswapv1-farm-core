const OreoToken = artifacts.require("OreoToken");

module.exports = function (deployer) {
  deployer.deploy(OreoToken);
};
