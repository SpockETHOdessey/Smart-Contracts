//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Spock {
    address owner;
    
    struct Player{
        bytes32 name;
        uint id;
    }
    
    struct BuyOrder{
        address buyer;
        uint typeStock;
        uint numStocks;
        uint totalPrice;
        uint holdingPeriod;
        uint timeStamp;
    }
    
    struct SellOrder{
        address seller;
        uint typeStock;
        uint numStocks;
        uint totalPrice;
        uint timeStamp;
    }
    
    mapping(uint => Player) playerMapping;
    mapping(uint => BuyOrder) buyOrderMapping;
    mapping(uint => SellOrder) sellOrderMapping;
    
    constructor() {
        owner = msg.sender;
    }
}
