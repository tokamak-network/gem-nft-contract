// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import { L1WrappedStakedTONFactory } from "../../src/L1/L1WrappedStakedTONFactory.sol";
import { L1WrappedStakedTON } from "../../src/L1/L1WrappedStakedTON.sol";
import { L1WrappedStakedTONStorage } from "../../src/L1/L1WrappedStakedTONStorage.sol";


import { DepositManager } from "../../src/L1/Mock/DepositManager.sol";
import { SeigManager } from "../../src/L1/Mock/SeigManager.sol";
import { MockToken } from "../../src/L1/Mock/MockToken.sol";
import { CoinageFactory } from "../../src/L1/Mock/CoinageFactory.sol";
import { Layer2Registry } from "../../src/L1/Mock/Layer2Registry.sol";
import { Candidate } from "../../src/L1/Mock/Candidate.sol";
import { RefactorCoinageSnapshot } from "../../src/L1/Mock/proxy/RefactorCoinageSnapshot.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract L1BaseTest is Test {
    using SafeERC20 for IERC20;

    address payable owner;
    address payable user1;
    address payable user2;
    address payable committee;

    address l1wrappedstakedton;
    address l1wrappedstakedtonFactory;
    address wton;
    address ton;

    address depositManager;
    address seigManager;
    address factory;
    address layer2Registry;
    address stakingLayer2Address;
    address candidate;

    uint256 delay = 93046;
    uint256 seigPerBlock = 3920000000000000000000000000;
    uint256 lastSeigBlock = block.number;

    uint256 public constant DECIMALS = 10**27;

    event WithdrawalRequested(address indexed _to, uint256 amount);

    function setUp() public virtual {
        owner = payable(makeAddr("Owner"));
        user1 = payable(makeAddr("User1"));
        user2 = payable(makeAddr("User2"));
        committee = payable(makeAddr("Committee"));

        vm.startPrank(owner);
        vm.warp(1632934800);

        wton = address(new MockToken("Wrapped Ton", "WTON", 27)); // 27 decimals
        ton = address(new MockToken("Ton", "TON", 18)); // 18 decimals

        // Transfer some tokens to User1
        IERC20(wton).transfer(user1, 10000 * 10 ** 27); // 10000 WTON
        IERC20(wton).transfer(user2, 10000 * 10 ** 27); // 10000 WTON
        IERC20(ton).transfer(user1, 10000 * 10 ** 18); // 10000 TON
        IERC20(ton).transfer(user2, 10000 * 10 ** 18); // 10000 TON

        // give ETH to User1 to cover gasFees associated with using VRF functions
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        depositManager = address(new DepositManager());
        seigManager = address(new SeigManager());
        factory = address(new CoinageFactory());
        layer2Registry = address(new Layer2Registry());
        candidate = address(new Candidate());

        DepositManager(depositManager).initialize(
            wton,
            layer2Registry,
            seigManager,
            delay
        );

        SeigManager(seigManager).initialize(
            ton,
            wton,
            layer2Registry,
            depositManager,
            seigPerBlock,
            factory,
            lastSeigBlock
        );

        Candidate(candidate).initialize(
            owner,
            true,
            "",
            committee,
            seigManager
        );

        require(Layer2Registry(layer2Registry).registerAndDeployCoinage(candidate, seigManager));

        l1wrappedstakedtonFactory = address(new L1WrappedStakedTONFactory(wton, ton));
        
        DepositManager(depositManager).setSeigManager(seigManager);

        // deploy and initialize Wrapped Staked TON
        l1wrappedstakedton = L1WrappedStakedTONFactory(l1wrappedstakedtonFactory).createWSTONToken(
            candidate,
            depositManager,
            seigManager,
            "Titan Wrapped Staked TON",
            "Titan WSTON"
        );

        vm.stopPrank();
    }


    function testSetup() public view {
        address l1wtonCheck = L1WrappedStakedTON(l1wrappedstakedton).depositManager();
        assert(l1wtonCheck == depositManager);

        address seigManagerCheck =  L1WrappedStakedTON(l1wrappedstakedton).seigManager();
        assert(seigManagerCheck == seigManager);

    }
}
