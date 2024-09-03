# GEM NFTs

<div align="center">
<img src="images/gem.png" alt="Mythic gem" width="250" />
</div>

### Description

The project is an NFT collection and marketplace featuring Gems, which rewards users with monetary value through staking TON. Users interact with a game-like interface to mine new Gems, as well as to buy, sell, and burn them. Additionally, users can forge two Gems to obtain a rarer Gem. To get WSTON tokens, users can either deposit WTON on L1 => receive WSTON on the same layer or use the Wston sapper on L2. Users utilize L2 WSTON to buy GEMs at a discount price. 

When a user claim for a mined GEM, the token is assigned randomly using the VDF verifier implementation.

GEMs have the following specifications:
- value: each gem has a specific value based on the rarity. (Example: Common Gems inherrits from 10 WSTON).
- rarity: there is 6 different types of rarity => Common, Rare, Unique, Epic, Legendary & Mythic.
- quadrants: each gem is defined by quadrants number. For exemple, [1, 1, 1, 1] is associated to a perfect common gem, [2, 2, 2, 2] perfect rare gem etc...
[2, 1, 1, 1] would be a gem that has the top left part of the gem associated to a rare gem and the 3 other parts associated to a common gem. Please note that the value for perfect and non-perfect gems is the same (value depends on the global rarity only).
- color: the color could be either solid (ex: solid Turquoise) or gradient (ex: semi Amber/ semi Ruby). The color is defined by ```uint256 color[2]``` variable.
- cooldown period: each GEM holder must wait until the cooldown period elapse before being able to mine this particular GEM. 
- mining period: each GEM has a particular mining period for which the holder must wait until it elapse whenever the mining process has started.
- mining try: Gems cannot be mined infinitely. When the mining try is equal to 0, it means that the GEM cannot mine anymore.
- randomRequest: it is used to track the random token that is associated to the GEM whenever the mining process ends. 
- tokenURI: holds the IPFS address of the metadata file.


### Contracts

#### MarketPlace (L2)

the marketplace is where users put their GEMs for sale at desired prices (in WSTON). A user showing interests for a particular gem will be able to either pay in L2 TON (at a discount price) or in L2 WSTON. Whenever the transfer passes, the NFT is sent to the new owner. Users can use ```putGemListForSale```function to put multiple GEMs for sale using one transaction only.

#### Treasury (L2)

The treasury is where pools of premined GEMs are created (by the admin only). This contract aims to handle every transaction that is made buy users (locks GEMs associated value, keeps TON tokens in reserve). The admin can put premined gem for sale onto the marketplace or use the swapper to get WSTON.  

#### GemFactory (L2)

This contract carries the logic behind GEMs Minting, Forging, mining and melting.
- Minting: there is two cases where NFTs are minted: 
    - If a new gem is forged, we burn the GEMs that were used to forge and we mint a brand new NFT that inherrits from the WSTON value of the burnt GEMs (following a precise valuation model shown below). 
    - Whenever the admin calls ```createGEMPool``` or ```createGEM``` from the ```Treasury``` contract with specific GEMs parammeters.
- Forging: any user can forge their GEMs if it respects specific rules:
    - two gems must be forged to get one rare, three rare for one unique, four unique for one epic, five epics for one legendary and six legendaries for one mythic.
    - the user can choose the color he wants to get for his new token. However, it must respect the following rules on at least 2 of the token forged: 
        - two same solids (ex: [1,1] + [1,1]): the new token color can be [1,1].
        - two different solids (ex: [1,1] + [2,2]): the new token color can be either [1,2] or [2,1].
        - one solid and one gradient & one gradient color is the same as the solid color (ex: [1,1] + [2,1]): the new token color can be [2,1].
        - one solid and one gradient & solid different from both gradients (ex: [1,1] + [3,2]): the new token color can be either [3,1] or [2,1] or [1,3] or [1,2].
        - two same gradients (ex: [1,2] + [1+2]): the new color can be either [1,2] or [2,1].
        - two different gradients (ex: [1,2] + [3,4]): the new color can be either [1,3] or [1,4] or [2,3] or [2,4] or [3,1] or [4,1] or [3,2] or [4,2].
    - quadrants calculation is the following : each quadrants of each gem are added up. the sum is even, the new gem quadrant will be equal of the next rarity base quadrant number. If the sum is odd, we +1 the next rarity quadrant base quandrant number. Exemple [1,2,2,1] + [2,2,1,1] => [3,4,3,2] 3 is odd, 4 and 2 are even => final gem quadrants is [3,2,3,2]. If, using this method, the result is equal to a perfect gem, we substract 1 to the last quadrant in order to avoid jumping from one level to two levels above.
- Mining: As mentioned previously, user must wait until the cooldown period has elapsed in order to mine the Gem. After starting mining, he will have to wait until the mining period has elapsed in order to pick randomly one gem and claim it. The probability of getting a Gem is equally distributed to the overall pool of premined gem. However, the user cannot get a gem which is rarer than the GEM is mining with.
- Melting: melting will burn the GEM and send the associated WSTON from the treasury to the user.


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

Titan Sepolia
```
TON_ADDRESS=0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2
TITAN_WRAPPED_STAKED_TON=0x256Cf034962292C111436F43e5d92a9EC24dcD3C
DRB_COORDINATOR_MOCK=0xe960E5E63e811812b2F5287D026f1aa6cA67E7f6
GEM_FACTORY=0xE7A2448cd6C52DD932F87F31B4CE11430FdE5Db0
TREASURY=0x1958f59fdb4a5956Ef7bDed3d1fa929fd42524d6
MARKETPLACE=0xFFdd70F0f6d8D1b62937F382FF92D14793cbDE36
WSTON_SWAP_POOL=0xe2C9dc6b20000D0F6B51e7fFc9Fb58c2Fb49c173
RANDOM_PACK=0xA662bEC667FE4670DB4DB33120B2D6B89885fe45
```

Ethereum Sepolia
```
L1_WRAPPED_STAKED_TON=0x17Ddb5CEaE35A40a520c4DcF1f70409BE9a25406
```


### Contact

For any inquiries, you can reach me through [my GitHub profile](https://github.com/mehdi-defiesta)

Or you can leave a message on the GitHub forum. 