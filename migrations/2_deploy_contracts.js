const Organiser = artifacts.require("Organiser");

module.exports = function(deployer) {
  deployer.deploy(Organiser);
};
