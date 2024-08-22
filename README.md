# OPAL project

<div align="center">
<img src="images/gem.png" alt="Mythic gem" width="250" />
</div>

### Description

The project is an NFT collection and marketplace featuring Gems, which rewards users with monetary value through staking TON. Users interact with a game-like interface to mine new Gems, as well as to buy, sell, and burn them. Additionally, users can forge two Gems to obtain a rarer Gem. Users can deposit WTON on Layer 1 (L1) and receive a wrapped version called WSTON on L2. Users utilize L2 WSTON to buy GEMs at a discount price.

When a user wishes to acquire a new Gem from the pre-mined pool, the token is assigned randomly using the VDF verifier implementation.

### Installation

1.  Clone this repository.
```
git clone https://github.com/tokamak-network/gem-nft-contracts
```

2. Navigate to the project directory.
```
cd gem-nft-contracts
```

3. install dependencies (foundry must be installed and updated first)
```
yarn install
```

4. Compile 
```
forge compile
```

4. Test
```
forge test
```

### Contract addresses

On Titan
```
TON_ADDRESS=0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2
TITAN_WRAPPED_STAKED_TON=0x256Cf034962292C111436F43e5d92a9EC24dcD3C
DRB_COORDINATOR_MOCK=0x7BD32dd4ED2Cf10483B19EAb3486FD88a84cE59E
GEM_FACTORY=0x4451535e9f29e6F5ed4206fde982a28fb5B316B8
TREASURY=0x77b8ad30Eea01e0aceA5DcC7d4a2da456aDf3F48
MARKETPLACE=0xEBA1406390d242854b1860fCF3e07A4Cb5642896
WSTON_SWAP_POOL=0xEce74cEc10e292e47F6D2FA08401039947Cb843f
```

On Ethereum
```
L1_WRAPPED_STAKED_TON=0x17Ddb5CEaE35A40a520c4DcF1f70409BE9a25406
```


### Contact

For any inquiries, you can reach me through [my GitHub profile](https://github.com/mehdi-defiesta)

Or you can leave a message on the GitHub forum. 