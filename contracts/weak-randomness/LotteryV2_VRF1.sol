// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LoteryV2 is VRFConsumerBase, Ownable {
  using Address for address payable;

  mapping(address => uint8) public bets;
  bool public betsClosed;
  bool public prizeTaken;

  bytes32 internal keyHash;
  uint256 internal fee;

  uint256 public randomResult;
  uint8 public winningNumber;

  constructor()
    VRFConsumerBase(
      0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
      0xa36085F69e2889c224210F603D836748e7dC0088 // LINK Token
    )
  {
    keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
  }

  function getRandomNumber() public returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    return requestRandomness(keyHash, fee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    randomResult = randomness;
  }

  // function withdrawLink() external onlyOwner {
  //   payable(owner).transfer(address(this).balance)
  // }

  function placeBet(uint8 _number) external payable {
    require(bets[msg.sender] == 0, "Only 1 bet per player");
    require(msg.value == 10 ether, "Bet cost: 10 ether");
    require(betsClosed == false, "Bets are closed");
    require(_number > 0 && _number <= 255, "Must be a number from 1 to 255");

    bets[msg.sender] = _number;
  }

  function endLottery() external onlyOwner {
    betsClosed = true;

    winningNumber = uint8(randomResult % 254 + 1);
  }

  function withdrawPrize() external {
    require(betsClosed == true, "Bets are still open");
    require(prizeTaken == false, "Prize already taken");
    require(bets[msg.sender] == winningNumber, "You aren't the winner");

    prizeTaken = true;

    payable(msg.sender).sendValue(address(this).balance);
  }

}
