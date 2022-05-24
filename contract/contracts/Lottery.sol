// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {

    // dynamic array with players addresses
    address[] public players;
    
    // Address of the manager
    address public manager;
    
    constructor() {
        manager = msg.sender;
    }

    modifier hasRequiredEthereum() {
        require(msg.value >= 0.01 ether, 'Minimum entry point is 0.01 ether'); 
        _;
    }

    modifier isManager() {
        require(msg.sender == manager, 'Only the contract manager can call this function');
        _;
    }

    // Automatically called when sending ether to this contract
    receive() external payable hasRequiredEthereum {
        // adds the address of the acoount that send ether to players array
        players.push(msg.sender);
    }

    // returns contract balance
    function get_balance() public view isManager returns(uint) {
        return address(this).balance;
    }

    // generates a random number
    function random() public view returns(uint) {
        // values here are not 100% random, just stimulating for demo/testing purpose.
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    // Selecting the winner and transfering ethers to it.
    function selectWinner() public isManager payable {
        uint r = random();
        uint index = r % players.length;
        address payable winner = payable(players[index]);

        // transfer contract balance to the winner.
        winner.transfer(address(this).balance);
        
        // reset it
        players = new address[](0);
    }
}