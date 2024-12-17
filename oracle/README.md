# Staking Index Oracle

## description

This script is an event listener which catches events ```Deposited``` and ```WithdrawalRequested``` emitted in L1WrappedStakedTON. the script is made to run within a docker container. 

## Installation steps

fill the .env
```
SEPOLIA_RPC_URL=
PRIVATE_KEY=
THANOS_SEPOLIA_RPC_URL=https://rpc.thanos-sepolia.tokamak.network

L1_WRAPPED_STAKED_TON=0xf94C0C0421d5cB2C6D1E11435d83203701927B9a
MARKETPLACE=0x144104f7645101578165764C4aa9EFf8aDE71043
WSTON_SWAP_POOL=0xB080256CD1aeb1b9E6AfEd3D96C108a029F1AfA4
```

build the docer image
```
docker build -t my-go-app .
```

run the container
```
docker run -d -p 8080:8080 --env-file .env my-go-app
```
