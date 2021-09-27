const Hodl = artifacts.require("Hodl");

contract('Hodl', function([deployer, user1, user2, user3]) {
  let hodl;

  beforeEach(async() => {
    console.log(`deployer: ${deployer}`);
    console.log(`user1: ${user1}`);
    console.log(`user2: ${user2}`);
    console.log(`user3: ${user3}`);

    hodl = await Hodl.new();
    await hodl.doHodl(1, { from: user1, value: 1000000000000000000});
    await hodl.doHodl(1, { from: user1, value: 1000000000000000000});
  })

  it('Basic test', async () =>{
    function timeout(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    let balance;

    balance = await hodl.getBalance();
    assert.equal(balance, 2000000000000000000);

    await hodl.cancelHodl(1, 1, { from: user1, value: 0});
    balance = await hodl.getBalance();
    assert.equal(balance, 1100000000000000000);

    await timeout(4000);

    await hodl.cancelHodl(1, 0, { from: user1, value: 0});
    balance = await hodl.getBalance();
    assert.equal(balance, 0);

    let getMinimumAmount = (await hodl.getMinimumAmount()).toString();
    assert.equal(getMinimumAmount, 1000000000000000, "wrong value");
  })
});