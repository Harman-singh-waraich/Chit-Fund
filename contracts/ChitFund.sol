pragma solidity >=0.4.21 <0.7.0;
import 'node_modules/@openzeppelin/contracts/math/SafeMath.sol';
import "./BeaconContract.sol";

// interface Aion
contract Aion {
    uint256 public serviceFee;
    function ScheduleCall(uint256 blocknumber, address to, uint256 value, uint256 gaslimit, uint256 gasprice, bytes memory data, bool schedType) public payable returns (uint,address);

}

contract ChitFund{

    using SafeMath for uint256;
    Aion aion;

    address payable public  Organiser;
    address payable [] public subscribers;
    address [] public winners;

    bool isOpen = false;
    bool firstLottery = true;

    uint public startDate;
    uint public approvals = 0;
    uint public minApprovals = 3;
    uint public maxApprovals = 6;
    uint public installment;
    uint payingWindow = 7 minutes;
    uint cyclePeriod = 10 minutes;
    uint counter = 1 ;
    uint chitPeriod = 0;
    uint duesPaid = 0 ;

    mapping(uint => uint) public cycleStarts;
    mapping(address => bool) isMember;
    mapping(address => bool) public duePaid;

    event DuePaid(address _address, uint amount);
    event WinnerSelected(address _address);
    event PaidWinner(address _address);
    event chitInitialized(uint _installment, address [] _subcribers);

    constructor (address payable _creator, uint256 _startDate, uint256 _installment) public{
        Organiser = _creator;
        startDate = _startDate;
        installment = _installment;
        isOpen  = true;
        subscribers.push(Organiser);
        approvals += 1;
    }

    function () external payable {}

    function approve() payable external{
        require(isOpen == true, "chit is closed");
        require(approvals < maxApprovals, "maximum occupancy reached");
        require(msg.value == installment, "please pay installment fee");
        require(isMember[msg.sender]==false, "you are already a member");

        isMember[msg.sender] =true;
        approvals += 1;
        subscribers.push(msg.sender);
    }

    function initializeChit() private {
        chitPeriod = subscribers.length.mul(cyclePeriod);  /*chitPeriod = no. of subscribers * month(30 days) */
        cycleStarts[counter] = block.timestamp;

        payWinner();
    }


    function depositMonthlyDue(uint amount) public payable {
        require(isMember[msg.sender] == true,"you are not a member");
        require(!isOpen,"Approval process underway");
        require( chitPeriod.sub(block.timestamp) <= payingWindow , "paying window is not open yet");

        if(counter != 1){
             require(block.timestamp.sub(cycleStarts[counter]) >= cyclePeriod);
          }
        require(duePaid[msg.sender] == false , "Due already paid");
        require(amount == msg.value);
        require(amount == installment,"installment mismatch");

        duePaid[msg.sender] = true;
        duesPaid += 1 ;

        emit DuePaid(msg.sender,msg.value);
    }

    function startChit() public {
          require(isOpen,"one time function");
          require(block.timestamp >= startDate + 4 days + 30 minutes , "nows not the time");
          isOpen = false;
          if(approvals < minApprovals){
             uint refund = address(this).balance.div(subscribers.length);
             for(uint i = 0 ;i < subscribers.length; i++){
                   subscribers[i].transfer(refund);
                 }
            }else{
               initializeChit();
            }
      }

    function payWinner() public {
        if(!firstLottery){
          require(duesPaid == subscribers.length, "some installments are pending");
          require(block.timestamp.sub(cycleStarts[counter]) >= cyclePeriod, "month has not ended yet! Be patient");
        }
        address payable _winner = pickWinner();


        duesPaid = 0;
        counter += 1;
        cycleStarts[counter] = block.timestamp;
        firstLottery = false;


        if(counter <= subscribers.length){
              scheduleLottery();
            }
        emit PaidWinner(_winner);
        if(counter > subscribers.length){
          close();
        }
        _winner.transfer(address(this).balance);
    }

    function pickWinner() private returns(address payable){
          BeaconContract beacon = BeaconContract(0x79474439753C7c70011C3b00e06e559378bAD040);
          (, bytes32 random) = beacon.getLatestRandomness();
          uint ran  = uint(random).mod(subscribers.length.sub(winners.length));

          address payable _winner = subscribers[ran];
          subscribers[ran] = subscribers[subscribers.length.sub(winners.length).sub(1)];
          subscribers[subscribers.length.sub(winners.length).sub(1)] = _winner;
          winners.push(_winner);

          emit WinnerSelected(_winner);

          return _winner;
    }



    function scheduleLottery() private {
        aion = Aion( 0xFcFB45679539667f7ed55FA59A15c8Cad73d9a4E);
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256('payWinner()')));
        uint callCost = 300000*1e9 + aion.serviceFee();
        aion.ScheduleCall.value(callCost)( block.timestamp + cyclePeriod, address(this), 0, 300000, 1e9, data, true);
    }

    function scheduleStarting() external {
        aion = Aion( 0xFcFB45679539667f7ed55FA59A15c8Cad73d9a4E);
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256('startChit()')));
        uint callCost = 300000*1e9 + aion.serviceFee();
        aion.ScheduleCall.value(callCost)( block.timestamp + 10 minutes, address(this), 0, 300000, 1e9, data, true);
    }

    function close() private {
      selfdestruct(Organiser);
    }
}
