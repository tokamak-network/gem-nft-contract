# GemSTON

<div align="center">
<img src="images/gem.png" alt="Mythic gem" width="250" />
</div>

## Description

The GEM NFTs project is a sophisticated NFT collection and marketplace centered around Gems. This platform allows users to earn monetary rewards by staking TON tokens. Users engage with a gamified interface to mine new Gems, as well as to buy, sell, and burn them. Additionally, users have the ability to forge two Gems to create a rarer Gem. To acquire WSTON tokens, users can either deposit WTON on Layer 1 (L1) to receive WSTON on the same layer or utilize the WSTON swapper on Layer 2 (L2). L2 WSTON can be used to purchase GEMs at a discounted rate.

When a user claims a mined GEM, the token is assigned randomly using the VDF random beacon. The RandomPack feature allows users to obtain a random GEM in exchange for an upfront fee, with the probability being equally distributed.

GEMs have the following specifications:
- Value: Each Gem has a specific value based on its rarity. For example, a Common Gem inherits a value of 10 WSTON.
- Rarity: There are six different rarity levels: Common, Rare, Unique, Epic, Legendary, and Mythic.
- Quadrants: Each Gem is defined by a set of quadrant numbers. For example, [1, 1, 1, 1] represents a perfect Common Gem, while [2, 2, 2, 2] represents a perfect Rare Gem. A Gem with [2, 1, 1, 1] would have its top-left quadrant associated with a Rare Gem and the other three quadrants associated with a Common Gem. Note that the value for perfect and non-perfect Gems remains the same, as it depends solely on the overall rarity.
- Color: The color of a Gem can be either solid (e.g., solid Turquoise) or gradient (e.g., semi-Amber/semi-Ruby). The color is defined by a ```uint256 color[2]``` variable.
- Cooldown Period: Each GEM holder must wait until the cooldown period elapses before being able to mine that particular GEM.
- Mining Period: Each GEM has a specific mining period, which the holder must wait for before the mining process can be completed.
- Mining Attempts: Gems cannot be mined indefinitely. Once the mining attempts reach zero, the GEM can no longer be mined.
- Random Request: This tracks the random token associated with the GEM when the mining process concludes.
- Token URI: This holds the IPFS address of the metadata file.


## Contracts

### MarketPlace (L2)

The marketplace allows users to list their GEMs for sale at desired prices in WSTON. Interested buyers can pay in L2 TON or L2 WSTON (at a discounted price). Upon successful transfer, the NFT is sent to the new owner. Users can list multiple GEMs for sale in a single transaction using the `putGemListForSale` function. Ownership of the NFT is not transferred when calling the `putGemForSale` function; instead, the GEM's `isLocked` status is set to true, preventing its transfer until it is either purchased or removed from sale.

### Treasury (L2)

The Treasury contract is responsible for creating pools of pre-mined GEMs, which is an admin-only function. It manages all user transactions, including locking GEM values and holding TON/WSTON tokens in reserve. The admin has the abil  ity to list pre-mined GEMs for sale on the marketplace. Therefore it is also possible for the owner or admins to remove (if owned by the treasury) or buy a Gem from the marketplace. It's important to note that new GEMs cannot be created if the WSTON collateral does not cover the value of the new GEM.

### RandomPack (L2)

This contract allows users to obtain a random GEM from the pre-mined GEM pool, which is held in the Treasury, in exchange for an upfront fee. The admin can customize the fee rate. The VDF random beacon is used to generate a random value, which involves running an off-chain node that calls the `fulfillRandomWords` function to transfer ownership of the selected GEM. If no GEM is available in the pool, a new perfect Common GEM is minted (only if there are sufficient funds in the Treasury contract). 

To distribution of the probability is based on the rarity. Here is an example of a probability distribution
- common Gem probability: 70%
- rare Gem probability: 20%
- unique Gem probability: 10%
- epic Gem probability: 0%
- legendary Gem probability: 0%
- mythic Gem probability: 0%

this values are setup by the contract owner at initialization

### WstonSwapPool (L2)

Users can swap their WSTON for TON if the Treasury holds enough TON. This feature is free of fees and can be accessed by anyone. The Treasury is always seeking WSTON as it will be used as collateral for newly minted GEMs.

### GemFactory (L2)

This contract carries the logic behind GEMs Minting, Forging, mining and melting.
- Minting: there is two cases where NFTs are minted: 
    - When a new Gem is forged, the GEMs used in the process are burned, and a new NFT is minted, inheriting the WSTON value of the burned GEMs (following a specific valuation model).
    - When the admin calls createGEMPool or createGEM from the Treasury contract with specific GEM parameters. The color must exist in the colors array; otherwise, the admin must add the color using the addColor function.
- Forging: any user can forge their GEMs if it respects specific rules:
    - Two Gems must be forged to obtain one Rare Gem, three Rares for one Unique, four Uniques for one Epic, five Epics for one Legendary, and six Legendaries for one Mythic.
    - Users can choose the color of the new token, but it must adhere to specific rules based on the colors of at least two of the tokens forged: 
        - two same solids (ex: [1,1] + [1,1]): the new token color can be [1,1].
        - two different solids (ex: [1,1] + [2,2]): the new token color can be either [1,2] or [2,1].
        - one solid and one gradient & one gradient color is the same as the solid color (ex: [1,1] + [2,1]): the new token color can be [2,1].
        - one solid and one gradient & solid different from both gradients (ex: [1,1] + [3,2]): the new token color can be either [3,1] or [2,1] or [1,3] or [1,2].
        - two same gradients (ex: [1,2] + [1+2]): the new color can be either [1,2] or [2,1].
        - two different gradients (ex: [1,2] + [3,4]): the new color can be either [1,3] or [1,4] or [2,3] or [2,4] or [3,1] or [4,1] or [3,2] or [4,2].
    - Quadrants are calculated by summing the quadrants of each Gem. If the sum is even, the new Gem's quadrant will match the next rarity base quadrant number. If the sum is odd, the next rarity quadrant base number is incremented by one. If the result is a perfect Gem, the last quadrant is decremented by one to avoid jumping two levels in rarity.
- Mining: Users must wait for the cooldown period to elapse before mining a Gem. After initiating mining, they must wait for the mining period to complete before randomly selecting and claiming a Gem. The probability of obtaining a Gem is equally distributed across the pool of pre-mined Gems, but users cannot obtain a Gem rarer than the one they are mining with.
- Melting: Melting burns the GEM and sends the associated WSTON from the Treasury to the user.

### GemFactoryProxy (L2)

GemFactory is split into three different contracts due to contract size issues. Therefore, the deployment of these contracts must adhere to specific proxy rules. After deploying instances of each contract, as well as an instance of the GemFactoryProxy, the deployer must call the upgradeTo function to set the initial implementation using the GemFactory instance address.

Next, the deployer must use the `setImplementation` function with an index of 1, passing the address of the GemFactoryForging instance. Finally, the deployer must call the `setImplementation` function again with an index of 2, passing the address of the GemFactoryMining instance.

It is then mandatory to call the `setSelectorImplementations2` function for the `forgeTokens(uint256[], uint8, uint8[2])` function, as well as for each function within the GemFactoryMining implementation. This ensures that the proxy knows which implementation the function signature must be routed to when called.

Refers to the following test suite for more information on the deployment process: [L2BaseTest.t.sol](test/L2/L2BaseTest.sol)


### L1WrappedStakedTON (L1)

This contract is responsible for staking users' WTON and minting WSTON for the same user. WSTON is an indexed token whose value is pegged to TON * stakingIndex. The staking index evolves over time based on the seigniorage received by the pool of sWTON owned by the contract.
<div align="center">
<img src="images/stakingIndex.png" alt="stakingIndex" width="500" />
</div>

- Staking Index: The value of WSTON increases as the pool receives more seigniorage, rewarding long-term depositors in line with the Layer 2 candidate reward distribution. The staking index is updated before each deposit or requestWithdrawal transaction.
- Note: An instance of L1WrappedStakedTON must be created for each Layer 2 candidate (e.g., Titan, Thanos). This is done through the L1WrappedStakingTONFactory contract.

### L1WrappedStakedTONFactory (L1)

The factory allows the creation of new L1WrappedStakedTON contract. The owner/admins of the factory become the owner of L1WrappedStakedTON created through the `createWSTON` function. Note that L1WrappedStakedTON owners must use the upgradeWSTONTo function to upgrade the implementation of the L1WrapedStakedTON contract they own.

## Installation

1.  Clone this repository.
```
git clone https://github.com/tokamak-network/gem-nft-contracts
cd gem-nft-contracts
```

2. install foundry dependencies (foundry must be installed and updated first. See foundry [documentation](https://book.getfoundry.sh/getting-started/installation) for more info)
```
forge install
```

3. install hardhat dependencies (optionnal)
```
yarn install
```

4. Compile 
```
forge compile
```

5. Test
```
forge test
```

## Contract addresses

Titan Sepolia
```
TON_ADDRESS=0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2
TITAN_WRAPPED_STAKED_TON=0xD6253ca94733d42BF7233BB71EBC71816bBBdcC0
DRB_COORDINATOR_MOCK=0x253e11B49d761Ae5Eb3cEA24921E7D54ac0fbEF2
GEM_FACTORY_PROXY=0x73367c018d8AA6Dd149FF7C4bd30197CC97092f2
GEM_FACTORY=0x6338e5aa83d8c992D47f6c145988c0A57ff4C091
GEM_FACTORY_FORGING=0x21cF9693ca31E89ECF0A1fA9790ed35bac2CEa47
GEM_FACTORY_MINING=0x6eA33804ABf1b214AC3F0A8C6A8634492aDd03ff
TREASURY=0x65f65bFAaAeC2d31DD24420205Ec7E4D34C6f2Aa
TREASURY_PROXY=0xC127c8db7FBCa0b3E1AbA9E12b9978ddba8B4f7e
MARKETPLACE=0x8121cA3a85D52eAa75268Ce5482EA23ca6Ca19BE
MARKETPLACE_PROXY=0x2F1CD4317Bd9c3d3b2D9F08EBD57bfe7143eb111
WSTON_SWAP_POOL=0xbE21e502d5d536F40C3AB06E0FE9830fe1E86c2D
WSTON_SWAP_POOL_PROXY=0xAF6b64801E977B93D9f1F12B267dBeb94eD2cae2
RANDOM_PACK=0xaa185F301f398bf15096968bF0CE15AbBA265911
RANDOM_PACK_PROXY=0x91F23650bb9F2C58B7C85d25E452A25656195C36
L2_BRIDGE=0x4200000000000000000000000000000000000010
```

Ethereum Sepolia
```
L1_WRAPPED_STAKED_TON_FACTORY=0xc25cd6237814d940F83E05C28D3459ccB93358a6
L1_WRAPPED_STAKED_TON=0xafAc56155F5987acaB99FcE872b59367606cC7f5
L1_WRAPPED_STAKED_TON_FACTORY_PROXY=0x321C99455515afd4179D2570c1eEec355f62c51E
L1_WRAPPED_STAKED_TON_PROXY=0x5a0c87852310E62B77899110ED6c7c8Df1c5703B
L1_WTON=0x79e0d92670106c85e9067b56b8f674340dca0bbd
L1_TON=0xa30fe40285B8f5c0457DbC3B7C8A280373c40044
DEPOSIT_MANAGER=0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F
SEIG_MANAGER=0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7
LAYER_2=0xCBeF7Cc221c04AD2E68e623613cc5d33b0fE1599
```

## Contact

For any inquiries, you can reach me through [my GitHub profile](https://github.com/mehdi-defiesta)

Or you can leave a message on the GitHub forum. 