// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LotteryV2 is VRFConsumerBaseV2, Ownable {
  using Address for address payable;

  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  mapping(address => uint8) public bets;
  bool public betsClosed;
  bool public prizeTaken;

  uint8 public winningNumber;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // Rinkeby LINK token contract. For other networks, see
  // https://docs.chain.link/docs/vrf-contracts/#configurations
  address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  //constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
  constructor() VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link_token_contract);
  //  s_owner = msg.sender;
    s_subscriptionId = 6615;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() public onlyOwner {
    // Will revert if subscription is not set and funded.
    require(LINKTOKEN.balanceOf(address(this)) >= callbackGasLimit, "Not enough LINK ");
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  function placeBet(uint8 _number) external payable {
    require(bets[msg.sender] == 0, "Only 1 bet per player");
    require(msg.value == 1 ether, "Bet cost: 1 ether");
    require(betsClosed == false, "Bets are closed");
    require(_number > 0 && _number <= 255, "Must be a number from 1 to 255");

    bets[msg.sender] = _number;
  }

  function endLottery() external onlyOwner {
    betsClosed = true;
    requestRandomWords();
    winningNumber = uint8(s_randomWords[0] % 254 + 1);
  }

  function withdrawPrize() external {
    require(betsClosed == true, "Bets are still open");
    require(prizeTaken == false, "Prize already taken");
    require(bets[msg.sender] == winningNumber, "You aren't the winner");

    prizeTaken = true;

    payable(msg.sender).sendValue(address(this).balance);
  }

}
