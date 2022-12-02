// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*
Vulnerabilities:
-visibility --> encrypted
-overflow --> SafeMath
-send() not verified --> Address.sol
-send() gas limit --> Address.sol

-reentrancy in sellTokens() --> implement Check-Effects-Interaction pattern
*/
import { ETBTokenFin } from "./EtbTokenFin.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract EtbDexFin {
  using Address for address payable;

  address public owner;
  ETBTokenFin private _etbToken;
  uint256 public fee;

  constructor(address _token) public {
    _etbToken = ETBTokenFin(_token);
    owner = msg.sender;
  }

  modifier onlyOwner() {
    //eliminate password
    require(msg.sender == owner, "Restricted Access");
    _;
  }

  function buyTokens() external payable {
    require(msg.value > 0, "Should send ETH to buy tokens");
    //Potential overflow problem
    require(_etbToken.balanceOf(owner) >=  msg.value, "Not enough tokens to sell");
    _etbToken.transferFrom(owner, msg.sender, msg.value - calculateFee(msg.value));
  }

  function sellTokens(uint256 _amount) external {
    //Potential overflow problem
    require(_etbToken.balanceOf(msg.sender) >= _amount, "Not enough tokens");
    //reentrancy - fixed
    _etbToken.burn(msg.sender, _amount);
    _etbToken.mint(_amount);

    //Gas limit 2300
    //Need to check the result of send() or use sendValue() from Address.sol
    payable(msg.sender).sendValue(_amount);


  }

  function setFee(uint256 _fee) external onlyOwner {
    fee = _fee;
  }

  function calculateFee(uint256 _amount) internal view returns (uint256) {
    return (_amount / 100) * fee;
  }

  function withdrawFees() external onlyOwner {
    //Gas limit 2300
    //Need to check the result of send() or use sendValue() from Address.sol
    payable(msg.sender).sendValue(address(this).balance);

  }
}
