// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title FundRaising Smart Contract
 * @notice A Fund Raising Smart Contract used to raise funds, with payments then released based on contributors voting
 */

contract FundRaising {

    mapping(address => uint) public contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minimumContribution;
    uint public deadline; // timestamp (seconds)
    uint public goal;
    uint public raisedAmount;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;

    event ContributeEvent(address sender, uint value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address recipient, uint value);

    constructor(uint _goal, uint _deadline, uint _minimumContribution) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        
        admin = msg.sender;
        minimumContribution = _minimumContribution;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "Only admin is allowed to call this function!");
        _;
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Fundraising deadline has exprired.");
        require(msg.value >= minimumContribution, "min contribution");
        
        if(contributors[msg.sender] == 0) {
            numberOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value; 

        emit ContributeEvent(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline, "Refunds can be required only after the deadline has expired!");
        require(raisedAmount < goal, "Refunds can be required only if the goals hasen't been meet!");
        require(contributors[msg.sender] > 0, "Only contributors can request refund");

        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];

        recipient.transfer(value);

        // after the user got refunded, set it's value to 0
        contributors[msg.sender] = 0;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public isAdmin {

        Request storage newRequest = requests.push();
        
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.approvalCount = 0;

        emit CreateRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint index) public {
      Request storage thisRequest = requests[index];
    
      require(contributors[msg.sender] > 0);
      require(thisRequest.approvals[msg.sender] == false);
      
      thisRequest.approvals[msg.sender] = true;
      thisRequest.approvalCount++;
    }

    function makePayment(uint index) public payable isAdmin {
        Request storage currentRequest = requests[index];

        require(currentRequest.completed == false, "Request needs to be completed");
        require(currentRequest.approvalCount > numberOfContributors / 2, "Payments can be made when more than 50% voted for");
        
        currentRequest.recipient.transfer(currentRequest.value);
        currentRequest.completed = true;

        emit MakePaymentEvent(currentRequest.recipient, currentRequest.value);
    }

}