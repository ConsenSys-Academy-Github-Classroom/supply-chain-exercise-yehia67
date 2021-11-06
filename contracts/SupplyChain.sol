// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

import './Context.sol';

contract SupplyChain is Context {

  address public owner;

  // <skuCount>
  uint256 public skuCount = 0;

 enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

   struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  mapping (uint256 => Item ) public items;

  // <enum State: ForSale, Sold, Shipped, Received>
  // <struct Item: name, sku, price, state, seller, and buyer>
  
   event LogForSale(uint256 indexed sku);
   event LogSold(uint256 indexed sku);
   event LogShipped(uint256 indexed sku);
   event LogReceived(uint256 indexed sku);   

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract

  // <modifier: isOwner
  modifier isOwner() { 
    require (owner == _msgSender(),"REVERT: Sender is not the owner of the contract"); 
    _;
  }
  modifier verifyCaller (address _address) { 
    require (_msgSender() == _address,"REVERT: Incorrect address"); 
    _;
  }

  modifier paidEnough(uint256 _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint256 sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    require(msg.value >= items[sku].price, "REVERT: Not enough ether"); 
    _;
  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

  
  modifier forSale(uint256 sku) {
    require(items[sku].state == State.ForSale && items[sku].seller != address(0), "REVERT: Item not for sale");
    _;
  }
  modifier sold(uint256 sku){
      require(items[sku].state == State.Sold, "REVERT: Item not for sale"); 
      _;
  }
  modifier shipped(uint256 sku){
    require(items[sku].state == State.Shipped, "REVERT: Item not shipped"); 
    _;
  }
  modifier received(uint256 sku){
    require(items[sku].state == State.Received," REVERT: Item not received"); 
    _;
  }
  
  constructor() {
    // 1. Set the owner to the transaction sender
    // 2. Initialize the sku count to 0. Question, is this necessary?
    owner = _msgSender();
    skuCount = 0;
  }

  function addItem(string memory _name, uint256 _price) public returns (bool) {
    require(_price > 0, "REVERT: Price must be greater than 0");
    require(bytes(_name).length > 0, "REVERT: Name should not be empty");

    items[skuCount] = Item({
      name: _name, 
      sku: skuCount, 
      price: _price, 
      state: State.ForSale, 
      seller: payable(_msgSender()), 
      buyer: payable(address(0))
    });
    emit LogForSale(skuCount);

    skuCount = skuCount + 1;
    return true;
  }

  // Implement this buyItem function. 
  // 1. it should be payable in order to receive refunds
  // 2. this should transfer money to the seller, 
  // 3. set the buyer as the person who called this transaction, 
  // 4. set the state to Sold. 
  // 5. this function should use 3 modifiers to check 
  //    - if the item is for sale, 
  //    - if the buyer paid enough, 
  //    - check the value after the function is called to make 
  //      sure the buyer is refunded any excess ether sent. 
  // 6. call the event associated with this function!
  function buyItem(uint256 sku) public  payable forSale(sku) checkValue(sku) {

    uint256 amountToRefund = msg.value - items[sku].price;
    (bool isRefund,) = payable(_msgSender()).call{value: amountToRefund}(abi.encode(amountToRefund));
    
    require(isRefund, "Failed to refund Ether");

    items[sku].buyer = payable(_msgSender());

    items[sku].state = State.Sold;

    
    (bool isSent,) = payable(items[sku].seller).call{value: items[sku].price}(abi.encode(items[sku].price));
    require(isSent, "Failed to refund Ether");
    
    emit LogSold(sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint256 sku) public sold(sku) verifyCaller(items[sku].seller) {
      items[sku].state = State.Shipped;
      emit LogShipped(sku);
  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint256 sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint256 _sku) public view 
     returns (string memory name, uint256 sku, uint256 price, uint256 state, address seller, address buyer)  
   { 
     name = items[_sku].name; 
     sku = items[_sku].sku; 
     price = items[_sku].price; 
     state = uint256(items[_sku].state); 
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer; 
     return (name, sku, price, state, seller, buyer); 
   } 
}
