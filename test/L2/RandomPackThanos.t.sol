// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";
import "../../src/L2/RandomPackStorage.sol";
import "../../src/L2/RandomPackThanos.sol";

contract RandomPackThanosTest is L2BaseTest {
    
    RandomPackThanos randomPackThanos; 

    // probabilities
    uint8 constant commonProb = 40;
    uint8 constant rareProb = 20;
    uint8 constant uniqueProb = 15;
    uint8 constant epicProb = 10;
    uint8 constant legendaryProb = 10;
    uint8 constant mythicProb = 5;

    event EthSentBack(uint256 amount);

    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
        randomPackThanos = new RandomPackThanos();
        randomPackProxy.upgradeTo(address(randomPackThanos));
        // setting the probabilities
        RandomPackThanos(randomPackProxyAddress).setProbabilities(
            commonProb,
            rareProb,
            uniqueProb,
            epicProb,
            legendaryProb,
            mythicProb
        );
        vm.stopPrank();

        assert(RandomPackThanos(randomPackProxyAddress).getTreasuryAddress() == treasuryProxyAddress);
        assert(RandomPackThanos(randomPackProxyAddress).getGemFactoryAddress() == gemfactoryProxyAddress);
        assert(RandomPackThanos(randomPackProxyAddress).getCallbackGasLimit() == 2100000);
        assert(RandomPackThanos(randomPackProxyAddress).getRequestCount() == 0);
        assert(RandomPackThanos(randomPackProxyAddress).getRandomPackFees() == randomPackFees);
        assert(keccak256(abi.encodePacked(RandomPackThanos(randomPackProxyAddress).getPerfectCommonGemURI())) == keccak256(abi.encodePacked("")));

    }

    // ----------------------------------- INITIALIZERS --------------------------------------

    /**
     * @notice testing the behavior of initialize function if called for the second time
     */
    function testInitializeShouldRevertIfCalledTwice() public {
        vm.startPrank(owner);
        // should revert
        vm.expectRevert(RandomPackStorage.AlreadyInitialized.selector);
        RandomPackThanos(randomPackProxyAddress).initialize(
            address(drbCoordinatorMock),
            gemfactoryProxyAddress,
            treasuryProxyAddress,
            randomPackFees
        );
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setGemFactory function
     */
    function testSetGemFactory() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit RandomPackStorage.GemFactoryAddressUpdated(address(0x1));
        RandomPackThanos(randomPackProxyAddress).setGemFactory(address(0x1));
        assert(RandomPackThanos(randomPackProxyAddress).getGemFactoryAddress() == address(0x1));
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setGemFactory function if address zero
     */
    function testSetGemFactoryShouldRevertIfAddressZero() public {
        vm.startPrank(owner);
        vm.expectRevert(RandomPackStorage.InvalidAddress.selector);
        RandomPackThanos(randomPackProxyAddress).setGemFactory(address(0));
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setGemFactory function if not owner
     */
    function testSetGemFactoryShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        RandomPackThanos(randomPackProxyAddress).setGemFactory(address(0x1));
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setRandomPackFees function
     */
    function testSetRandomPackFees() public {
        uint256 newFees = 15*10**18;
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit RandomPackStorage.RandomPackFeesUpdated(newFees);
        RandomPackThanos(randomPackProxyAddress).setRandomPackFees(newFees);
        assert(RandomPackThanos(randomPackProxyAddress).getRandomPackFees() == newFees);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setRandomPackFees function if new value is 0
     */
    function testSetRandomPackFeesShouldRevertIfAddressZero() public {
        vm.startPrank(owner);
        vm.expectRevert(RandomPackStorage.RandomPackFeesEqualToZero.selector);
        RandomPackThanos(randomPackProxyAddress).setRandomPackFees(0);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setRandomPackFees function if not owner
     */
    function testSetRandomPackFeesShouldRevertIfNotOwner() public {
        uint256 newFees = 15*10**18;
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        RandomPackThanos(randomPackProxyAddress).setRandomPackFees(newFees);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setTreasury function
     */
    function testSetTreasury() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit RandomPackStorage.TreasuryAddressUpdated(address(0x1));
        RandomPackThanos(randomPackProxyAddress).setTreasury(address(0x1));
        assert(RandomPackThanos(randomPackProxyAddress).getTreasuryAddress() == address(0x1));
        vm.stopPrank();
    }

        /**
     * @notice testing the behavior of setTreasury function if address zero
     */
    function testSetTreasuryShouldRevertIfAddressZero() public {
        vm.startPrank(owner);
        vm.expectRevert(RandomPackStorage.InvalidAddress.selector);
        RandomPackThanos(randomPackProxyAddress).setTreasury(address(0));
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setTreasury function if not owner
     */
    function testSetTreasuryShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        RandomPackThanos(randomPackProxyAddress).setTreasury(address(0x1));
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setCommonGemTokenURI function 
     */
    function testSetCommonGemTokenURI() public {
        vm.startPrank(owner);
        string memory tokenURI = "https://example.com/token/1";
        emit RandomPackStorage.PerfectCommonGemURIUpdated(tokenURI);
        RandomPackThanos(randomPackProxyAddress).setPerfectCommonGemURI(tokenURI);
        assert(keccak256(abi.encodePacked(RandomPack(randomPackProxyAddress).getPerfectCommonGemURI())) == keccak256(abi.encodePacked(tokenURI)));
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setCallbackGasLimit function 
     */
    function testSetCallbackGasLimit() public {
        vm.startPrank(owner);
        uint32 newcallback = 50000;
        emit RandomPackStorage.CallBackGasLimitUpdated(newcallback);
        RandomPackThanos(randomPackProxyAddress).setCallbackGasLimit(newcallback);
        assert(RandomPackThanos(randomPackProxyAddress).getCallbackGasLimit() == newcallback);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of SetProbabilities function if all probabilities are equal to 0
     */
    function testSetProbabilitiesShouldRevertIfAllProbAreEqualToZero() public {
         vm.startPrank(owner);
         vm.expectRevert(RandomPackStorage.invalidProbabilities.selector);
         RandomPackThanos(randomPackProxyAddress).setProbabilities(0,0,0,0,0,0);
         vm.stopPrank();
    }

    /**
     * @notice testing the behavior of SetProbabilities function if the sum of all probbilities is not equal to 100
     */
    function testSetProbabilitiesShouldRevertIfSumIsNotEqualToHundred() public {
         vm.startPrank(owner);
         vm.expectRevert(RandomPackStorage.invalidProbabilities.selector);
         //sum = 110
         RandomPackThanos(randomPackProxyAddress).setProbabilities(50,20,10,10,10,10);
         vm.stopPrank();
    }

    // ----------------------------------- CORE FUNCTIONS --------------------------------------

    /**
     * @notice testing the getRandomGem function 
     * @dev we created 3 gems (ont COMMON, one RARE and one UNIQUE) that are eligible for being picked by the node
     * @dev called requestRandomGem with msg.value = 0.005 ETH (price of requesting is equal to 0.001 ETH)
     * @dev expected the EthSentBack event is triggered with the appropriate amount
     * @dev simulated the node calling fulfillRandomness and ensured the GEM is appropriately picked and transferred
     */
    function testGetRandomGem() public {

        // create a pool of premined gem
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](3);
        colors[0] = [0,0];
        colors[1] = [1,1];
        colors[2] = [1,1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](3);
        rarities[0] = GemFactoryStorage.Rarity.COMMON;
        rarities[1] = GemFactoryStorage.Rarity.RARE;
        rarities[2] = GemFactoryStorage.Rarity.UNIQUE;
        
        uint8[4][] memory quadrants = new uint8[4][](3);
        quadrants[0] = [1, 2, 2, 1];
        quadrants[1] = [2, 3, 3, 2];
        quadrants[2] = [4, 3, 4, 3];

        string[] memory tokenURIs = new string[](3);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasuryProxyAddress).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM creation
        assert(newGemIds.length == 3);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == treasuryProxyAddress);
        assert(keccak256(abi.encodePacked(GemFactory(gemfactoryProxyAddress).tokenURI(newGemIds[0]))) == keccak256(abi.encodePacked(tokenURIs[0])));
        assert(keccak256(abi.encodePacked(GemFactory(gemfactoryProxyAddress).tokenURI(newGemIds[1]))) == keccak256(abi.encodePacked(tokenURIs[1])));
        assert(keccak256(abi.encodePacked(GemFactory(gemfactoryProxyAddress).tokenURI(newGemIds[2]))) == keccak256(abi.encodePacked(tokenURIs[2])));

        vm.stopPrank();

        vm.startPrank(user1);
        // calculate the price of funding the DRBCoordinator
        uint32 callbackGasLimit = 600000;
        uint256 directFundingCost = drbCoordinatorMock.calculateDirectFundingPrice(
            IDRBCoordinator.RandomWordsRequest({security: 0, mode: 0, callbackGasLimit: callbackGasLimit})
        );

        // Calculate the expected amount to be sent back for the event
        uint256 expectedAmount = randomBeaconFees - directFundingCost;
        uint256 totalAmount = randomBeaconFees + randomPackFees;
        // Capture the event
        vm.expectEmit(true, true, true, true);
        emit RandomPackStorage.EthSentBack(expectedAmount);
        // call requestRandomGem by sending msg.value = 0.005 ETH
        uint256 requestId = RandomPackThanos(randomPackProxyAddress).requestRandomGem{value: totalAmount}();
        // simulated the node calling fulfillRandomness
        drbCoordinatorMock.fulfillRandomness(requestId);
        // ensuring the either one of the minted GEM is transferred to user 1
        assert(
            GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1 || 
            GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == user1 || 
            GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == user1
        );
        console.log("owner of the new COMMON GEM: ", GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]));
        console.log("owner of the new RARE GEM: ", GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]));
        console.log("owner of the new UNIQUE GEM: ", GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]));

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the getRandomGem function if not sufficient ETH is sent 
     * @dev we created 2 gems (one RARE and one UNIQUE) that are eligible for being picked by the node
     * @dev called calculateDirectFundingPrice function from the DRBCoordinator to calculate the minimal amount of ETH that must be consumed
     * @dev called requestRandomGem with msg.value equal to 1 WEI less than the price calculated previously. Ensured the function reverts
     */
    function testGetRandomGemShouldRevertIfNotEnoughETHSent() public {
         // create a pool of premined gem
        vm.startPrank(owner);
        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](2);
        colors[0] = [0,0];
        colors[1] = [1,1];
        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](2);
        rarities[0] = GemFactoryStorage.Rarity.RARE;
        rarities[1] = GemFactoryStorage.Rarity.UNIQUE;
        uint8[4][] memory quadrants = new uint8[4][](2);
        quadrants[0] = [2, 3, 3, 2];
        quadrants[1] = [4, 3, 4, 3];
        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        // Call createPreminedGEMPool function from the Treasury contract
        Treasury(treasuryProxyAddress).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );
        vm.stopPrank();

        vm.startPrank(user1);
        // calculate the price of funding the DRBCoordinator
        uint32 callbackGasLimit = 600000;
        uint256 directFundingCost = drbCoordinatorMock.calculateDirectFundingPrice(
            IDRBCoordinator.RandomWordsRequest({security: 0, mode: 0, callbackGasLimit: callbackGasLimit})
        );
        MockTON(ton).approve(randomPackProxyAddress, randomPackFees);
        //call requestRandomGem with not sufficient ETH (1 WEI less than the price calculated)
        vm.expectRevert();
        RandomPackThanos(randomPackProxyAddress).requestRandomGem{value: directFundingCost - 1}();
        vm.stopPrank();
    }
    
     /**
     * @notice testing the behavior of the getRandomGem function if there is no GEMs available
     * @dev called requestRandomGem ensured the CommonGemMinted event is emitted
     */
    function testGetRandomGemIfNoGemAvailable() public {
        vm.startPrank(user1);
        uint256 totalFees = randomBeaconFees + randomPackFees;
        uint256 requestId = RandomPackThanos(randomPackProxyAddress).requestRandomGem{value: totalFees}();

        // Expect the CommonGemMinted event to be emitted
        vm.expectEmit(false, false, false, true);
        emit CommonGemMinted();
        drbCoordinatorMock.fulfillRandomness(requestId);

        vm.stopPrank();
    }


    // ----------------------------------- PAUSE/UNPAUSE --------------------------------------


    /**
     * @notice testing the behavior of pause function
     */
    function testPause() public {
        vm.startPrank(owner);
        RandomPackThanos(randomPackProxyAddress).pause();
        assert(RandomPack(randomPackProxyAddress).getPaused() == true);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of pause function if called by user1
     */
    function testPauseShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        RandomPackThanos(randomPackProxyAddress).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testPauseShouldRevertIfPaused() public {
        testPause();
        vm.startPrank(owner);
        vm.expectRevert("Pausable: paused");
        RandomPackThanos(randomPackProxyAddress).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function
     */
    function testUnpause() public {
        testPause();
        vm.startPrank(owner);
        RandomPackThanos(randomPackProxyAddress).unpause();
        assert(RandomPack(randomPackProxyAddress).getPaused() == false);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if called by user1
     */
    function testUnpauseShouldRevertIfNotOwner() public {
        testPause();
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        RandomPackThanos(randomPackProxyAddress).unpause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testUnpauseShouldRevertIfunpaused() public {
        vm.startPrank(owner);
        vm.expectRevert("Pausable: not paused");
        RandomPackThanos(randomPackProxyAddress).unpause();
        vm.stopPrank();
    }


}
