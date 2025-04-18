// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Multisig {
    event Approve(address indexed owner, uint indexed vaultId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    // vaultId => approvals (owner => bool)
    mapping(uint => mapping(address => bool)) public approvals;
    mapping(uint => uint256) public approvalCount;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier notApproved(uint vaultId) {
        require(!approvals[vaultId][msg.sender], "Already approved");
        _;
    }

    constructor(uint _required) {
        require(_required > 0, "At least one approval required");

        owners.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        owners.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        owners.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);

        for (uint i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = true;
        }

        required = _required;
    }

    function approve(uint vaultId) external  notApproved(vaultId) returns (bool) {
        approvals[vaultId][msg.sender] = true;
        approvalCount[vaultId]++;

        emit Approve(msg.sender, vaultId);

        if (approvalCount[vaultId] >= required) {
            return true; // Approval threshold met
        }
        return false; // Not enough approvals yet
    }

    function hasApproved(uint vaultId, address owner) external view returns (bool) {
        return approvals[vaultId][owner];
    }

    function getApprovalCount(uint vaultId) external view returns (uint) {
        return approvalCount[vaultId];
    }

    function getRequiredApprovals() external view returns (uint) {
        return required;
    }
}

