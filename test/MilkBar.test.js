const { advanceBlockTo } = require("@openzeppelin/test-helpers/src/time");
const { assert } = require("chai");
const OreoToken = artifacts.require("OreoToken");
const MilkBar = artifacts.require("MilkBar");

contract("MilkBar", ([alice, bob, carol, dev, minter]) => {
  beforeEach(async () => {
    this.oreo = await OreoToken.new({ from: minter });
    this.milk = await MilkBar.new(this.oreo.address, { from: minter });
  });

  it("mint", async () => {
    await this.milk.mint(alice, 1000, { from: minter });
    assert.equal((await this.milk.balanceOf(alice)).toString(), "1000");
  });

  it("burn", async () => {
    await advanceBlockTo("650");
    await this.milk.mint(alice, 1000, { from: minter });
    await this.milk.mint(bob, 1000, { from: minter });
    assert.equal((await this.milk.totalSupply()).toString(), "2000");
    await this.milk.burn(alice, 200, { from: minter });

    assert.equal((await this.milk.balanceOf(alice)).toString(), "800");
    assert.equal((await this.milk.totalSupply()).toString(), "1800");
  });

  it("safeOreoTransfer", async () => {
    assert.equal(
      (await this.oreo.balanceOf(this.milk.address)).toString(),
      "0"
    );
    await this.oreo.mint(this.milk.address, 1000, { from: minter });
    await this.milk.safeOreoTransfer(bob, 200, { from: minter });
    assert.equal((await this.oreo.balanceOf(bob)).toString(), "200");
    assert.equal(
      (await this.oreo.balanceOf(this.milk.address)).toString(),
      "800"
    );
    await this.milk.safeOreoTransfer(bob, 2000, { from: minter });
    assert.equal((await this.oreo.balanceOf(bob)).toString(), "1000");
  });
});
