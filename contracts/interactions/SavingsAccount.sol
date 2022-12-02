// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";

contract SavingsAccount {
  using Address for address payable;

  mapping(address => uint256) public balanceOf;

  function deposit() external payable {
    balanceOf[msg.sender] += msg.value;
  }

  function withdraw() external {
    uint256 amountDeposited = balanceOf[msg.sender];

    balanceOf[msg.sender] = 0;
//    payable(msg.sender).transfer(amountDeposited); //gas limnited to 2300wei, not enough to run receive() in Investor.sol
//    payable(msg.sender).call{ value: amountDeposited }(""); //possible, but potentially problematic solution, costs extra to run receive()
    payable(msg.sender).sendValue(amountDeposited); //preferred solution o use sendValue() from Address.sol
                                                    //checks if enough eth and reverts if the call fails
  }
}
