const { assert } = require("chai");

const OreoToken = artifacts.require("OreoToken");

contract("OreoToken", ([alice, bob, carol, dev, minter]) => {
  beforeEach(async () => {
    this.oreo = await OreoToken.new({ from: minter });
  });

  it("mint", async () => {
    await this.oreo.mint(alice, 1000, { from: minter });
    assert.equal((await this.oreo.balanceOf(alice)).toString(), "1000");
  });
});
