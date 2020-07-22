pragma solidity >=0.4.21 <0.7.0;

import "./ChitFund.sol";

contract Organiser{

    mapping(address => Chit) public Chits;
    mapping(address => address) public SubscriberToChit;

    address [] public chits;

    struct Chit{
      address creator;
      uint installment;
      uint startDate;
    }

    event ChitCreated(address _address);

    function createChit(uint256 _installment)
     public
     payable
     returns (ChitFund tokenAddress)
      {
        require(_installment == msg.value, "please supply correct installment");
        ChitFund chit = new ChitFund(msg.sender,block.timestamp,_installment);
        address(chit).transfer(msg.value);
        chit.scheduleStarting();  // chit starts 5 days after creation if minimum approvals have reached

        chits.push(address(chit));
        Chits[address(chit)] = Chit(msg.sender,_installment,block.timestamp);

        emit ChitCreated(address(chit));
        return chit;
  }
}
