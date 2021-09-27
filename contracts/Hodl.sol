// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Hodl {
  struct Hodler {
    address hodlAddress;
    uint256 hodlValue;
    uint256 lockEndTimestamp;
    uint month;
    uint256 exclusion;
    bool isClosed;
  }

  mapping (address => Hodler[]) public _hodlers;

  address public owner;
  uint256 minimumAmount;

  mapping (uint => uint256) public _accumulateHodlCoin;
  mapping (uint => uint256) public _accumulateExclusion;
  mapping (uint => uint256) public _accumulateAddedCoin;
  uint256 public _accumulateTotalAddedCoin;
  uint256 public _accumulateTotalCoin;
  uint256 public unit = 100000000000000000;

  constructor() {
    owner = msg.sender;
    minimumAmount = 1000000000000000;
  }

  function doHodl(uint256 month) public payable returns (bool) {
    require(month == 1 || month == 3 || month == 6 || month == 12 || month == 24 || month == 36 || month == 48 || month == 60, "Check the month.");
    require(msg.value >= minimumAmount, "Please check the minimum quantity.");

    Hodler memory hodler;
    hodler.hodlAddress = msg.sender;
    hodler.hodlValue = msg.value;
    hodler.month = month;
    hodler.exclusion = _accumulateExclusion[month];
    hodler.isClosed = false;
    // hodler.lockEndTimestamp = block.timestamp + month * 30 days;
    hodler.lockEndTimestamp = block.timestamp + month * 300 seconds;

    _hodlers[msg.sender].push(hodler);
    _accumulateHodlCoin[month] += msg.value;
    _accumulateTotalCoin += msg.value;

    return true;
  }

  function cancelHodl(uint month, uint index) public payable returns (bool) {
    require(month == 1 || month == 3 || month == 6 || month == 12 || month == 24 || month == 36 || month == 48 || month == 60, "Check the month.");

    // get hold info
    Hodler storage hodler = _hodlers[msg.sender][index];

    // check already closed
    require(!hodler.isClosed, "Already closed.");

    // change hold state to closed
    hodler.isClosed = true;

    // calc more addCoin
    uint256 addCoin = (_accumulateExclusion[month] - hodler.exclusion) * hodler.hodlValue / unit;
    // calc refund value
    uint256 refundValue = hodler.hodlValue + addCoin;
    _accumulateHodlCoin[month] -= hodler.hodlValue;

    // Before LockEndTime
    if(block.timestamp < hodler.lockEndTimestamp) {
      // calc penalty value
      uint256 penaltyValue = refundValue * 10 / 100;
      // calc refund value
      refundValue -= penaltyValue;
      // calc exclusion
      if(_accumulateHodlCoin[month] != 0){
        _accumulateExclusion[month] += penaltyValue * unit / _accumulateHodlCoin[month];
      }else{
        payable(owner).transfer(penaltyValue);
      }
      // increase total penalty value
      _accumulateAddedCoin[month] += penaltyValue * unit ;
      _accumulateTotalAddedCoin += penaltyValue * unit ;
    }

    payable(msg.sender).transfer(refundValue);

    return true;
  }

  function getCancelHodlValue(uint month, uint index) public view returns (uint256) {
    require(month == 1 || month == 3 || month == 6 || month == 12 || month == 24 || month == 36 || month == 48 || month == 60, "Check the month.");

    // get hold info
    Hodler memory hodler = _hodlers[msg.sender][index];

    // check already closed
    require(!hodler.isClosed, "Already closed.");

    // calc more addCoin
    uint256 addCoin = (_accumulateExclusion[month] - hodler.exclusion) * hodler.hodlValue / unit;
    // calc refund value
    uint256 refundValue = hodler.hodlValue + addCoin;

    // Before LockEndTime
    if(block.timestamp < hodler.lockEndTimestamp) {
      // calc penalty value
      uint256 penaltyValue = refundValue * 10 / 100;
      // calc refund value
      refundValue -= penaltyValue;
    }

    return refundValue;
  }

  // set contract minimum
  function setMinimumAmount(uint256 num) public returns (bool) {
    require(owner == msg.sender, "Check the account.");
    minimumAmount = num;
    return true;
  }

  // get contract minimum
  function getMinimumAmount() public view returns (uint256) {
    return minimumAmount;
  }

  function getMyHodlsByAddress(address myAddress) public view returns (Hodler[] memory) {
    return _hodlers[myAddress];
  }

  function getMyHodlsByAddressAndIndex(address myAddress, uint index) public view returns (Hodler memory) {
    return _hodlers[myAddress][index];
  }

  // benefit total return
  function getTotalPenaltyValueByMonth(uint month) public view returns (uint256) {
    return _accumulateAddedCoin[month] / unit;
  }
  // benefit total return
  function getTotalPenaltyValue() public view returns (uint256) {
    return _accumulateTotalAddedCoin / unit;
  }

  function isTimeReady(address myAddress, uint index, uint256 nowDate) public view returns (bool) {
    Hodler memory hodler = _hodlers[myAddress][index];
    if(nowDate < hodler.lockEndTimestamp) {
      return false;
    } else {
      return true;
    }
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }
}