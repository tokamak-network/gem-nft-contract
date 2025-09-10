# L1WrappedStakedTON (WSTON) Tokenomics Documentation

## Overview

The L1WrappedStakedTON (WSTON) contract implements a liquid staking derivative that wraps TON/WTON tokens and provides users with transferable staking positions. The tokenomics are built around a dynamic exchange rate mechanism that allows users to benefit from staking rewards automatically.

## Core Components

### 1. Token Architecture

- **Input Tokens**: TON (18 decimals) and WTON (27 decimals)  
- **Output Token**: WSTON (27 decimals)
- **Precision**: Uses `DECIMALS = 10^27` for high-precision calculations

### 2. Staking Index Mechanism

The staking index is the core of WSTON tokenomics, representing the exchange rate between WSTON and underlying staked tokens.

#### Formula
```solidity
stakingIndex = (totalStake * DECIMALS) / totalSupply()
```

**Where:**
- `totalStake` = Total WTON staked by the contract in the SeigManager
- `totalSupply()` = Total WSTON tokens in circulation
- `DECIMALS` = 10^27 (precision constant)

#### Initial State
- Initial staking index: `1.0 * 10^27` (1:1 ratio)
- Updates dynamically as staking rewards accumulate

#### Appreciation Mechanism
As staking rewards accrue to the contract's position in the SeigManager, the `totalStake` increases while `totalSupply` remains constant, causing the staking index to appreciate and giving WSTON holders exposure to staking rewards.

## Token Flows

### Deposit Process

#### TON Deposits
1. User transfers TON to contract
2. Contract calls `TON.approveAndCall()` to swap TON → WTON via WTON contract
3. WTON is staked through DepositManager
4. WSTON minted to user based on formula:
   ```solidity
   wstonAmount = (wtonAmount * DECIMALS) / stakingIndex
   ```

#### WTON Deposits  
1. User transfers WTON to contract
2. WTON is directly staked through DepositManager
3. WSTON minted using the same formula

### Withdrawal Process

#### Request Phase
1. User burns WSTON tokens
2. Equivalent WTON amount calculated:
   ```solidity
   wtonToWithdraw = (wstonAmount * stakingIndex) / DECIMALS
   ```
3. Withdrawal request created with delay period
4. Contract calls `DepositManager.requestWithdrawal()`

#### Claim Phase
1. After delay period, user can claim TON (automatically converted from WTON)
2. Final amount: `tonAmount = wtonAmount / 10^9`

## Reward Distribution

### Seigniorage Updates
- Rewards accrue automatically through Tokamak's seigniorage mechanism
- Contract calls `updateSeigniorage()` before each deposit to ensure latest rewards are captured
- Seigniorage is distributed by the SeigManager to staking positions

### Reward Accrual
- Rewards increase the `totalStake` without increasing `totalSupply`
- This appreciation is reflected in the rising staking index
- All WSTON holders benefit proportionally from rewards

## Economic Parameters

### Precision and Scaling
- **TON**: 18 decimals (10^18)
- **WTON**: 27 decimals (10^27)  
- **WSTON**: 27 decimals (10^27)
- **Calculations**: Use 10^27 precision to avoid rounding errors

### Conversion Rates
```solidity
// Deposit: WTON → WSTON
wstonAmount = (wtonAmount * 10^27) / stakingIndex

// Withdrawal: WSTON → WTON  
wtonAmount = (wstonAmount * stakingIndex) / 10^27

// Final conversion: WTON → TON
tonAmount = wtonAmount / 10^9
```

### Withdrawal Constraints
- **Minimum withdrawal**: Configurable `minimumWithdrawalAmount`
- **Maximum concurrent requests**: Configurable `maxNumWithdrawal` per user
- **Delay period**: Determined by DepositManager for the Layer2 address

## Risk Management

### Administrative Controls
- **Pause mechanism**: Owner can pause deposits/withdrawals in emergencies
- **Parameter updates**: Owner can modify withdrawal limits and key addresses
- **Upgradeable**: Contract uses proxy pattern for upgradability

### Economic Safeguards
- **Seigniorage validation**: Updates fail gracefully if seigniorage cannot be updated
- **Minimum amounts**: Prevents dust attacks and gas optimization issues
- **Request limits**: Prevents users from creating excessive withdrawal requests

## Yield Characteristics

### Expected Returns
- WSTON holders receive staking rewards through appreciation of the staking index
- Returns depend on:
  - Tokamak Layer2 staking rewards
  - Network seigniorage rates  
  - Total staked amount across the ecosystem

### Compounding Effect
- Rewards automatically compound as they increase the underlying stake
- No manual claiming required - rewards accrue to token value
- Liquid nature allows trading of staking positions

## Integration Points

### Layer2 Staking
- Integrates with Tokamak's DepositManager for staking operations
- Connects to SeigManager for reward distribution
- Links to specific Layer2 address for staking allocation

### Cross-Chain Compatibility
- Designed for Layer1 (Ethereum) deployment
- Supports bridging mechanisms (referenced in other contracts)
- Compatible with Layer2 WSTON representations

## Technical Considerations

### Gas Optimization
- Batched seigniorage updates to reduce gas costs
- Efficient withdrawal request processing
- Optimized storage patterns for user data

### Precision Handling
- All calculations use 27-decimal precision to minimize rounding errors
- Careful handling of TON ↔ WTON conversions (10^9 scaling factor)
- Safe math operations to prevent overflow/underflow

This tokenomics model creates a liquid staking derivative that automatically accrues staking rewards while maintaining transferability and composability within the broader DeFi ecosystem.