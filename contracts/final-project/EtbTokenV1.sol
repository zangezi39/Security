// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;
//Use SafeMath

/*
Vulnerabilities:
- tx.origin
- lack of access controls (setDexAddress)
- overflow (old pragma)
*/
contract ETBTokenV1 {
  address public owner;
  address public etbDex;
  uint256 public totalSupply;
  string public name = "Eat the Blocks Token";
  string public symbol = "ETBT";
  uint8 public decimals = 18;

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) private allowances;

  constructor(uint256 initialSupply) public {
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
    owner = msg.sender;
  }

  modifier onlyEtbDex() {
    require(msg.sender == etbDex, "Restricted Access");
    _;
  }

//modifier never used
  modifier onlyOwner() {
    //tx.origin problem
    require(tx.origin == owner, "Restricted Access");
    _;
  }

  function setDexAddress(address _dex) external {
    etbDex = _dex;
  }

  function transfer(address recipient, uint256 amount) external {
    require(recipient != address(0), "ERC20: transfer from the zero address");
    //Potential overflow problems
    require(balances[msg.sender] - amount >= 0, "Not enough balance");
    balances[msg.sender] -= amount;
    balances[recipient] += amount;
  }

  function approve(address spender, uint256 amount) external {
    require(spender != address(0), "ERC20: approve to the zero address");

    allowances[msg.sender][spender] = amount;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool) {
    //Potential overflow problems
    require(allowances[sender][msg.sender] - amount >= 0, "ERC20: amount exceeds allowance");
    require(balances[sender] - amount >= 0, "Not enough balance");
    allowances[sender][msg.sender] -= amount;
    balances[sender] -= amount;
    balances[recipient] += amount;

    return true;
  }

  function mint(uint256 amount) external onlyEtbDex {
    //Potential overflow problems
    totalSupply += amount;
    balances[owner] += amount;
  }

  function burn(address account, uint256 amount) external onlyEtbDex {
    //Potential overflow problems
    totalSupply -= amount;
    balances[account] -= amount;
  }

  /* --- Getters --- */

  function balanceOf(address account) public view returns (uint256) {
    return balances[account];
  }

  function allowanceOf(address balanceOwner, address spender) public view virtual returns (uint256) {
    return allowances[balanceOwner][spender];
  }
}
