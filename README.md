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

3. Compile 

```
forge compile
```

4. Test

```
forge test
```

### Oracle Testing on Sepolia

We have created a minimalistic script that listens for Deposited event from WrappedStakedTON contract (deployed on Sepolia Ethereum). The script calls onWSTONDeposit function from WSTON manager (which is deployed on Titan Sepolia). Therefore, the script allows us to update the staking index on L2 whenever a user deposit WTON and gets WSTON on L1. 

1. update the .env.example (by removing the .example). Fill in the PRIVATE_KEY (you must have enough ETH on both Ethereum Sepolia and Titan Sepolia), the SEPOLIA_RPC_URL, ETHERSCAN_API_KEY and TIITAN_SEPOLIA_RPC_URL.
2. run the node : 
```
node oracle/TitanOracle.js
```
3. Open another terminal and run callsDepoositAndGetWSTON.js. It deposits WTON on behalf of the user on WrappedStakedTON contract. User must have at least 10 Sepolia WTON available.
```
node oracle/callsDepositAndGetWSTON.js
```

You should get the following output on the first terminal ```Deposited event detected:...```


### Contact

For any inquiries, you can reach me through [my GitHub profile](https://github.com/mehdi-defiesta)

Or you can leave a message on the GitHub forum. 