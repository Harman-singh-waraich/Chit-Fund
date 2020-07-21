var ChitFund = artifacts.require("./ChitFund.sol");

contract("ChitFund", function(accounts) {
  console.log(accounts);

 // var electionInstance;

  it("initializes with two candidates", async function() {
    var chitFund = await ChitFund.deployed();
    await chitFund.initializeChit(accounts);
    var subscriber = await chitFund.subscribers(1);
    assert.equal(subscriber,accounts[1],"accounts are right");
  });


 it("pays dues",async () =>{
   var chitFund =  await ChitFund.deployed();
   console.log("waiting....");
   function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  await timeout(60000);
  console.log("wait over");
  var result = await chitFund.depositMonthlyDue(web3.utils.toWei("0.0001","ether"),{from : accounts[0],value: web3.utils.toWei("0.0001","ether")})
  console.log(result);
  var due = await chitFund.duesPaid(accounts[0]);
  assert(dues,true);
 })
})
