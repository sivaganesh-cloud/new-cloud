// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockEncryptedERC20 {
    string public name = "Encrypted Avalanche Token";
    string public symbol = "eAVAX";
    uint8 public decimals = 18;
    
    // In a real eERC, balances are encrypted babyjubjub points/ciphertext
    mapping(address => bytes32) private encryptedBalances;
    mapping(address => uint256) private rawBalances; // local mock representation

    event Transfer(address indexed from, address indexed to, uint256 value);
    event BalanceEncrypted(address indexed user, bytes32 encryptedValue);

    constructor() {
        rawBalances[msg.sender] = 1000000 * 10**18;
    }

    function mint(address to, uint256 amount) external {
        rawBalances[to] += amount;
    }

    // Emulates zero-knowledge/homomorphic encrypted balance setting
    function setEncryptedBalance(address user, bytes32 ciphertext) external {
        encryptedBalances[user] = ciphertext;
        emit BalanceEncrypted(user, ciphertext);
    }

    function transferPrivate(address to, uint256 amount, bytes32 encryptedProof) external returns (bool) {
        require(rawBalances[msg.sender] >= amount, "Insufficient balance");
        rawBalances[msg.sender] -= amount;
        rawBalances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function getRawBalance(address account) external view returns (uint256) {
        return rawBalances[account];
    }
}