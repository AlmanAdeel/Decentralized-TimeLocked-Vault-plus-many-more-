# Modular Vault System – Phase 1 (TimeLock, Milestone, ETH, NFT, Factory)

## Overview

This repository contains the foundational architecture for a modular, upgrade-ready **DeFi Vault System**. The vaults are designed for scenarios involving delayed fund releases, milestone-based withdrawals, and NFT ownership integration.

This is **Phase 1** of the larger system, focusing on:
- ETH-based vaults
- TimeLock and Milestone-specific vault logic
- NFT integrations for access or collateral tracking
- A factory contract to deploy vaults programmatically

Collateral-based minting will be added in a future update (Phase 2).

---

## Contracts Included

### 1. `TimeLockVault.sol`
- Stores ETH for a user-defined duration
- Withdrawals are only possible after the lock period expires
- Useful for vesting schedules, time-based payouts, and personal fund locking

### 2. `MilestoneVault.sol`
- Allows depositors to define multiple milestones
- Each milestone has a release condition and associated fund percentage
- Designed for use in:
  - Freelance project payments
  - Crowdfunding stages
  - DAO-governed budget releases

### 3. `VaultEth.sol`
- Handles basic ETH deposit and withdrawal logic
- Used as a base for both TimeLock and Milestone vaults
- Integrates with the factory for automated deployment

### 4. `VaultNft.sol`
- Issues NFTs representing ownership or access rights to a specific vault
- Acts as a vault access control layer
- Enables transferable vault ownership and tracking

### 5. `VaultFactory.sol`
- Deploys vaults dynamically via minimal proxy (clone pattern)
- Efficient gas usage for multiple vault instantiations
- Tracks deployed vaults per user and vault type

---

## Architecture Goals

- Modularity: Each vault type is designed as a separate contract inheriting shared logic
- Upgradeability: Contracts structured to support future extension (e.g., collateral minting, ERC-20 support)
- Flexibility: Supports both time-based and task-based fund release mechanisms
- NFT Integration: Bridges the gap between DeFi vaults and NFT-based authorization or collateral models

---

## Phase Roadmap

### ✅ Phase 1 (Current)
- ETH-based vaults with milestone and time-based logic
- Vault factory
- NFT vault integration

### 🔜 Phase 2 (Planned)
- Collateral-based minting
- Yield farming integration (via Aave or other protocols)
- Governance vaults
- Full front-end deployment and UX layer

---

## Development Notes

This system is part of a long-term smart contract architecture exploration focused on real-world DeFi applications. It emphasizes gas efficiency, modular logic, and composability with NFTs and other external systems.

Code is still undergoing optimization and internal testing.  
Security audits and formal testing will follow in later phases.

---

## Built by:
Alman Adeel
Smart Contract Developer | DeFi Systems Designer  
