// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*
Vulnerabilities:
- tx.origin --> changed to msg.sender
- lack of access controls (setDexAddress) --> add onlyOwner modifier (alternatively use Ownable.sol)
- overflow (old pragma) --> use SafeMath for uint256 (alternatively can change the pragma)
*/
contract ETBTokenFin {

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

//modifier never used - use on setDexAddress()
  modifier onlyOwner() {
    //tx.origin problem - change to msg.sender
    require(msg.sender == owner, "Restricted Access");
    _;
  }

  function setDexAddress(address _dex) external onlyOwner {
    etbDex = _dex;
  }

  function transfer(address recipient, uint256 amount) external {
    require(recipient != address(0), "ERC20: transfer from the zero address");
    //Potential overflow problem - fixed
    require(balances[msg.sender] >= amount, "Not enough balance");
    balances[msg.sender] -= amount;
    balances[recipient] += amount;
  }

  function approve(address spender, uint256 amount) external {
    require(spender != address(0), "ERC20: approve to the zero address");
    require(balances[msg.sender] > 0, "No tokens owned");
    allowances[msg.sender][spender] = amount;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool) {
    //Potential overflow problem - fixed
    require(allowances[sender][msg.sender] >= amount, "ERC20: amount exceeds allowance");
    require(balances[sender] >= amount, "Not enough balance");
    allowances[sender][msg.sender] -= amount;
    balances[sender] -= amount;
    balances[recipient] += amount;

    return true;
  }

  function mint(uint256 amount) external onlyEtbDex {
    //Potential overflow problem - fixed
    totalSupply += amount;
    balances[owner] += amount;
  }

  function burn(address account, uint256 amount) external onlyEtbDex {
    //Potential overflow problems - fixed
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
