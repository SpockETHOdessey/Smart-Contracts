// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
	
contract Spock {
    address owner;

    using Counters for Counters.Counter;
    Counters.Counter private _playerIds;
    Counters.Counter private _buyOrderIds;
    Counters.Counter private _sellOrderIds;

    event Buy(uint, uint, uint, address);
    event Sell(uint, uint, uint, address);

    struct Player{
        //bytes32 name;
        uint id;
    }
    
   
    struct BuyOrder{

        //Random 5 digit number
        uint buyOrderId;
        address buyer;
        uint playerId;
        uint numStocks;
        //To be eventually calculated using Chainlink
        uint currentPrice;
        uint totalPrice;
        //There should be a max cap defined for this
        uint holdingPeriod;
        uint timeStamp;
        bool active;
    }
    
    struct SellOrder{
        //Random 6 digit number
        uint sellOrderId;
        address seller;
        uint playerId;
        uint numStocks;
        //To be eventually calculated using Chainlink
        uint currentPrice;
        uint totalPrice;
        uint timeStamp;
    }

    struct StockBalance{
        address holder;

    }
    
    mapping(uint => Player) playerMapping;
    mapping(uint => BuyOrder) buyOrderMapping;
    mapping(uint => SellOrder) sellOrderMapping;
    
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    //Store all the player information in the contract
    function addPlayers(uint[] memory playerIds) public onlyOwner returns(bool){
        require(playerIds.length > 0, "Player Id length cannot be zero");
        
        
        for(uint i = 0; i< playerIds.length; i++){
            _playerIds.increment();
            Player memory player = Player(playerIds[i]);
            playerMapping[_playerIds.current()] = player;
        }
    
        return true;
    }

    //Buy stocks of a particular player
    function buyStocks(uint playerId, uint numStocks, uint currentPrice, uint holdingPeriod) payable public returns(uint) {
            
            //Platform commission = 5%
            uint commission = (1 ether* 0.05* numStocks*currentPrice);
            uint totalValue = commission+numStocks*currentPrice;

            require(msg.value >= totalValue, "Amount not enough to buy the stocks");
            _buyOrderIds.increment();

            uint buyId = 20001 + _buyOrderIds.current();
            BuyOrder memory newOrder = BuyOrder(buyId, msg.sender, playerId, numStocks, currentPrice, numStocks*currentPrice, holdingPeriod, block.timestamp, true);

            buyOrderMapping[buyId] = newOrder;


            emit Buy(playerId, numStocks, numStocks*currentPrice, msg.sender);
            return buyId;

    }

    //Sell stocks of a particular player
    function sellStocks(uint playerId, uint numStocks, uint currentPrice, uint buyOrderId) public returns(uint) {
        //Check if this person holds these stocks
        BuyOrder memory buyOrder = buyOrderMapping[buyOrderId];
        require(buyOrder.active == true, "BuyOrder is not active anymore");
        require(buyOrder.playerId == playerId && buyOrder.numStocks >= numStocks, "buyOrder data is not matching");
        require(buyOrder.buyer == msg.sender, "Only owner can sell the stocks");
        require(buyOrder.holdingPeriod >= (block.timestamp - buyOrder.timeStamp), "You can sell only wthin holding period");
        _sellOrderIds.increment();

        uint sellId = 200015 + _sellOrderIds.current();
        uint payout = numStocks*currentPrice;

        if(numStocks == buyOrder.numStocks){
            buyOrder.active = false;
            buyOrderMapping[buyOrderId] = buyOrder;

            SellOrder memory sellOrder = SellOrder(sellId, msg.sender, playerId, numStocks, currentPrice, numStocks*currentPrice, block.timestamp);
            sellOrderMapping[sellId] = sellOrder;
        }

        else if(numStocks < buyOrder.numStocks){
            //If the number of stocks is less than the current number of stocks in the buy order, deactivate the older buy order and create a new one for the remaining stocks
            uint leftNumberOfStocks = buyOrder.numStocks - numStocks;

            _buyOrderIds.increment();

            uint buyId = 20001 + _buyOrderIds.current();
            BuyOrder memory newOrder = BuyOrder(buyId, msg.sender, playerId, leftNumberOfStocks, buyOrder.currentPrice, leftNumberOfStocks*currentPrice, buyOrder.holdingPeriod, block.timestamp, true);

            buyOrder.active = false;
            buyOrderMapping[buyOrderId] = buyOrder;
            buyOrderMapping[buyId] = newOrder;

            SellOrder memory sellOrder = SellOrder(sellId, msg.sender, playerId, numStocks, currentPrice, numStocks*currentPrice, block.timestamp);
            sellOrderMapping[sellId] = sellOrder;
        }

        //Transferring the value from the contract to the msg.sender subtracting the commission
        //Platform commission = 5%
        uint commission = (1 ether* 0.05* numStocks*currentPrice);
        uint totalPayout = payout - commission;
        
        payable(msg.sender).transfer(totalPayout);
        payable(owner).transfer(commission);
        
        emit Buy(playerId, numStocks, numStocks*currentPrice, msg.sender);

        return sellId;
    }


    /**
    All getters will reside below
     */

     function getBuyOrderPlayer(uint buyId) public view returns(uint){
         return buyOrderMapping[buyId].playerId;
     }


     function getBuyOrderStockNum(uint buyId) public view returns(uint){
         return buyOrderMapping[buyId].numStocks;
     }

    function getBuyOrderHoldingPeriod(uint buyId) public view returns(uint){
         return buyOrderMapping[buyId].holdingPeriod;
     }

    function getBuyOrderStockPrice(uint buyId) public view returns(uint){
         return buyOrderMapping[buyId].currentPrice;
    }
}
