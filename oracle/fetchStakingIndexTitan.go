package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/joho/godotenv"
)

type DepositedEvent struct {
	To                 common.Address
	Amount             *big.Int
	WstonAmount        *big.Int
	DepositTime        *big.Int
	DepositBlockNumber *big.Int
}

type WithdrawalRequestedEvent struct {
	To     common.Address
	Amount *big.Int
}

func main() {
	// Load environment variables from .env file
	err := godotenv.Load()
	if err != nil {
		log.Fatalf("Error loading .env file")
	}

	// Fetch environment variables
	sepoliaRPCURL := os.Getenv("SEPOLIA_RPC_URL")
	titanSepoliaRPCURL := os.Getenv("TITAN_SEPOLIA_RPC_URL")
	privateKeyHex := os.Getenv("PRIVATE_KEY")
	l1WrappedStakedTonAddress := os.Getenv("L1_WRAPPED_STAKED_TON")
	wstonSwapPoolAddress := os.Getenv("WSTON_SWAP_POOL")
	marketplaceAddress := os.Getenv("MARKETPLACE")

	// Connect to Sepolia (L1)
	clientL1, err := ethclient.Dial(sepoliaRPCURL)
	if err != nil {
		log.Fatalf("Failed to connect to Sepolia: %v", err)
	}

	// Connect to Titan Sepolia (L2)
	clientL2, err := ethclient.Dial(titanSepoliaRPCURL)
	if err != nil {
		log.Fatalf("Failed to connect to Titan Sepolia: %v", err)
	}

	// Set up the event listener
	contractAddress := common.HexToAddress(l1WrappedStakedTonAddress)
	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddress},
	}

	logs := make(chan types.Log)
	sub, err := clientL1.SubscribeFilterLogs(context.Background(), query, logs)
	if err != nil {
		log.Fatalf("Failed to subscribe to logs: %v", err)
	}

	// Define the ABI of the contract
	contractABI, err := abi.JSON(strings.NewReader(`
		[{
			"anonymous": false,
			"inputs": [
				{"indexed": false, "internalType": "address", "name": "to", "type": "address"},
				{"indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256"},
				{"indexed": false, "internalType": "uint256", "name": "wstonAmount", "type": "uint256"},
				{"indexed": false, "internalType": "uint256", "name": "depositTime", "type": "uint256"},
				{"indexed": false, "internalType": "uint256", "name": "depositBlockNumber", "type": "uint256"}
			],
			"name": "Deposited",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{"indexed": true, "internalType": "address", "name": "_to", "type": "address"},
				{"indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256"}
			],
			"name": "WithdrawalRequested",
			"type": "event"
		}]`))
	if err != nil {
		log.Fatalf("Failed to parse contract ABI: %v", err)
	}

	// Listen for the events
	for {
		select {
		case err := <-sub.Err():
			log.Fatalf("Error in subscription: %v", err)
		case vLog := <-logs:
			// Determine which event was emitted
			switch vLog.Topics[0].Hex() {
			case crypto.Keccak256Hash([]byte("Deposited(address,uint256,uint256,uint256,uint256)")).Hex():
				// Parse the Deposited event
				event := new(DepositedEvent)
				err := contractABI.UnpackIntoInterface(event, "Deposited", vLog.Data)
				if err != nil {
					log.Fatalf("Failed to unpack Deposited event log data: %v", err)
				}

				fmt.Printf("Deposited event detected: To=%s, Amount=%s, WstonAmount=%s, DepositTime=%s, DepositBlockNumber=%s\n",
					event.To.Hex(), event.Amount.String(), event.WstonAmount.String(), event.DepositTime.String(), event.DepositBlockNumber.String())

				// Fetch the stakingIndex from L1
				stakingIndex, err := fetchStakingIndex(clientL1, l1WrappedStakedTonAddress)
				if err != nil {
					log.Fatalf("Failed to fetch staking index: %v", err)
				}

				// Trigger the oracle job for Deposited event
				runOracleJob(clientL1, clientL2, privateKeyHex, l1WrappedStakedTonAddress, wstonSwapPoolAddress, marketplaceAddress, stakingIndex)

			case crypto.Keccak256Hash([]byte("WithdrawalRequested(address,uint256)")).Hex():
				// Parse the WithdrawalRequested event
				event := new(WithdrawalRequestedEvent)
				err := contractABI.UnpackIntoInterface(event, "WithdrawalRequested", vLog.Data)
				if err != nil {
					log.Fatalf("Failed to unpack WithdrawalRequested event log data: %v", err)
				}

				fmt.Printf("WithdrawalRequested event detected: To=%s, Amount=%s\n",
					event.To.Hex(), event.Amount.String())

				// Fetch the stakingIndex from L1
				stakingIndex, err := fetchStakingIndex(clientL1, l1WrappedStakedTonAddress)
				if err != nil {
					log.Fatalf("Failed to fetch staking index: %v", err)
				}

				// Trigger the oracle job for WithdrawalRequested event
				runOracleJob(clientL1, clientL2, privateKeyHex, l1WrappedStakedTonAddress, wstonSwapPoolAddress, marketplaceAddress, stakingIndex)
			}
		}
	}
}

func fetchStakingIndex(client *ethclient.Client, contractAddress string) (*big.Int, error) {
	contractAddr := common.HexToAddress(contractAddress)
	contractABI := `[{"constant":true,"inputs":[],"name":"stakingIndex","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]`

	parsedABI, err := abi.JSON(strings.NewReader(contractABI))
	if err != nil {
		return nil, fmt.Errorf("failed to parse contract ABI: %v", err)
	}

	callData, err := parsedABI.Pack("stakingIndex")
	if err != nil {
		return nil, fmt.Errorf("failed to pack call data: %v", err)
	}

	msg := ethereum.CallMsg{
		To:   &contractAddr,
		Data: callData,
	}

	result, err := client.CallContract(context.Background(), msg, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call contract: %v", err)
	}

	var stakingIndex *big.Int
	err = parsedABI.UnpackIntoInterface(&stakingIndex, "stakingIndex", result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack result: %v", err)
	}

	return stakingIndex, nil
}

func runOracleJob(clientL1, clientL2 *ethclient.Client, privateKeyHex, l1WrappedStakedTonAddress, wstonSwapPoolAddress, marketplaceAddress string, stakingIndex *big.Int) {
	// Use the stakingIndex directly from the event
	fmt.Printf("Using Staking Index from L1: %s\n", stakingIndex.String())

	// Update the staking index on L2 (WstonSwapPool)
	err := updateStakingIndexOnL2(clientL2, privateKeyHex, wstonSwapPoolAddress, stakingIndex)
	if err != nil {
		log.Fatalf("Failed to update staking index on L2: %v", err)
	}

	fmt.Println("Staking index updated successfully on L2 (WstonSwapPool)")

	// Set the staking index on the Marketplace contract
	err = setStakingIndexOnMarketplace(clientL2, privateKeyHex, marketplaceAddress, stakingIndex)
	if err != nil {
		log.Fatalf("Failed to set staking index on Marketplace: %v", err)
	}

	fmt.Println("Staking index set successfully on Marketplace")
}

func updateStakingIndexOnL2(client *ethclient.Client, privateKeyHex, contractAddress string, newIndex *big.Int) error {
	log.Println("Starting updateStakingIndexOnL2...")

	// Parse the private key
	privateKey, err := crypto.HexToECDSA(strings.TrimPrefix(privateKeyHex, "0x"))
	if err != nil {
		log.Printf("Failed to parse private key: %v\n", err)
		return fmt.Errorf("failed to parse private key: %w", err)
	}
	log.Println("Private key parsed successfully.")

	// Get the public key and address
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Println("Failed to cast public key to ECDSA")
		return fmt.Errorf("failed to cast public key to ECDSA")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	log.Printf("From address: %s\n", fromAddress.Hex())

	// Get the nonce
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Printf("Failed to get nonce: %v\n", err)
		return fmt.Errorf("failed to get nonce: %w", err)
	}
	log.Printf("Nonce: %d\n", nonce)

	// Suggest gas price
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Printf("Failed to suggest gas price: %v\n", err)
		return fmt.Errorf("failed to suggest gas price: %w", err)
	}
	log.Printf("Suggested gas price: %s\n", gasPrice.String())

	// Prepare the transaction data
	contractAddr := common.HexToAddress(contractAddress)
	contractABI := `[{"inputs":[{"internalType":"uint256","name":"newIndex","type":"uint256"}],"name":"updateStakingIndex","outputs":[],"stateMutability":"nonpayable","type":"function"}]`

	parsedABI, err := abi.JSON(strings.NewReader(contractABI))
	if err != nil {
		log.Printf("Failed to parse contract ABI: %v\n", err)
		return fmt.Errorf("failed to parse contract ABI: %w", err)
	}
	log.Println("Contract ABI parsed successfully.")

	callData, err := parsedABI.Pack("updateStakingIndex", newIndex)
	if err != nil {
		log.Printf("Failed to pack call data: %v\n", err)
		return fmt.Errorf("failed to pack call data: %w", err)
	}
	log.Println("Call data packed successfully.")

	// Estimate gas limit
	gasLimit := uint64(300000) // Set an appropriate gas limit
	log.Printf("Gas limit: %d\n", gasLimit)

	// Create the transaction
	tx := types.NewTransaction(nonce, contractAddr, big.NewInt(0), gasLimit, gasPrice, callData)
	log.Println("Transaction created successfully.")

	// Get the chain ID
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Printf("Failed to get network ID: %v\n", err)
		return fmt.Errorf("failed to get network ID: %w", err)
	}
	log.Printf("Chain ID: %s\n", chainID.String())

	// Sign the transaction
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Printf("Failed to sign transaction: %v\n", err)
		return fmt.Errorf("failed to sign transaction: %w", err)
	}
	log.Println("Transaction signed successfully.")

	// Send the transaction
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Printf("Failed to send transaction: %v\n", err)
		return fmt.Errorf("failed to send transaction: %w", err)
	}
	log.Printf("Transaction sent: %s\n", signedTx.Hash().Hex())

	// Wait for the transaction to be mined
	receipt, err := bind.WaitMined(context.Background(), client, signedTx)
	if err != nil {
		log.Printf("Failed to wait for transaction to be mined: %v\n", err)
		return fmt.Errorf("failed to wait for transaction to be mined: %w", err)
	}

	// Check if the transaction was successful
	if receipt.Status != 1 {
		log.Printf("Transaction failed with status: %v\n", receipt.Status)
		return fmt.Errorf("transaction failed with status: %v", receipt.Status)
	}

	log.Printf("Transaction mined successfully! Block number: %d\n", receipt.BlockNumber.Uint64())
	return nil
}

func setStakingIndexOnMarketplace(client *ethclient.Client, privateKeyHex, contractAddress string, newIndex *big.Int) error {
	log.Println("Starting setStakingIndexOnMarketplace...")

	// Parse the private key
	privateKey, err := crypto.HexToECDSA(strings.TrimPrefix(privateKeyHex, "0x"))
	if err != nil {
		log.Printf("Failed to parse private key: %v\n", err)
		return fmt.Errorf("failed to parse private key: %w", err)
	}
	log.Println("Private key parsed successfully.")

	// Get the public key and address
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Println("Failed to cast public key to ECDSA")
		return fmt.Errorf("failed to cast public key to ECDSA")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	log.Printf("From address: %s\n", fromAddress.Hex())

	// Get the nonce
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Printf("Failed to get nonce: %v\n", err)
		return fmt.Errorf("failed to get nonce: %w", err)
	}
	log.Printf("Nonce: %d\n", nonce)

	// Suggest gas price
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Printf("Failed to suggest gas price: %v\n", err)
		return fmt.Errorf("failed to suggest gas price: %w", err)
	}
	log.Printf("Suggested gas price: %s\n", gasPrice.String())

	// Prepare the transaction data
	contractAddr := common.HexToAddress(contractAddress)
	contractABI := `[{"inputs":[{"internalType":"uint256","name":"_stakingIndex","type":"uint256"}],"name":"setStakingIndex","outputs":[],"stateMutability":"nonpayable","type":"function"}]`

	parsedABI, err := abi.JSON(strings.NewReader(contractABI))
	if err != nil {
		log.Printf("Failed to parse contract ABI: %v\n", err)
		return fmt.Errorf("failed to parse contract ABI: %w", err)
	}
	log.Println("Contract ABI parsed successfully.")

	callData, err := parsedABI.Pack("setStakingIndex", newIndex)
	if err != nil {
		log.Printf("Failed to pack call data: %v\n", err)
		return fmt.Errorf("failed to pack call data: %w", err)
	}
	log.Println("Call data packed successfully.")

	// Estimate gas limit
	gasLimit := uint64(300000) // Set an appropriate gas limit
	log.Printf("Gas limit: %d\n", gasLimit)

	// Create the transaction
	tx := types.NewTransaction(nonce, contractAddr, big.NewInt(0), gasLimit, gasPrice, callData)
	log.Println("Transaction created successfully.")

	// Get the chain ID
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Printf("Failed to get network ID: %v\n", err)
		return fmt.Errorf("failed to get network ID: %w", err)
	}
	log.Printf("Chain ID: %s\n", chainID.String())

	// Sign the transaction
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Printf("Failed to sign transaction: %v\n", err)
		return fmt.Errorf("failed to sign transaction: %w", err)
	}
	log.Println("Transaction signed successfully.")
	// Send the transaction
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Printf("Failed to send transaction: %v\n", err)
		return fmt.Errorf("failed to send transaction: %w", err)
	}
	log.Printf("Transaction sent: %s\n", signedTx.Hash().Hex())

	// Wait for the transaction to be mined
	receipt, err := bind.WaitMined(context.Background(), client, signedTx)
	if err != nil {
		log.Printf("Failed to wait for transaction to be mined: %v\n", err)
		return fmt.Errorf("failed to wait for transaction to be mined: %w", err)
	}

	// Check if the transaction was successful
	if receipt.Status != 1 {
		log.Printf("Transaction failed with status: %v\n", receipt.Status)
		return fmt.Errorf("transaction failed with status: %v", receipt.Status)
	}

	log.Printf("Transaction mined successfully! Block number: %d\n", receipt.BlockNumber.Uint64())
	return nil
}
