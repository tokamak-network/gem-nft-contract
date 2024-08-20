// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "./L2BaseTest.sol";
import { UniswapV3Factory } from "../../src/L2/Mock/Tokamak-uniswap/uniswap-core/UniswapV3Factory.sol";
import { UniswapV3Pool } from "../../src/L2/Mock/Tokamak-uniswap/uniswap-core/UniswapV3Pool.sol";
import { Weth9 } from "../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/WETH9.sol";
import { IUniswapV3Pool } from "../../src/L2/Mock/Tokamak-uniswap/uniswap-core/interfaces/IUniswapV3Pool.sol";
import { SwapRouter } from "../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/SwapRouter.sol";
import { NonfungibleTokenPositionDescriptor } from "../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/NonFungibleTokenPositionDescriptor.sol";
import { NonfungiblePositionManager } from "../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/NonFungiblePositionManager.sol";
import { INonfungiblePositionManager } from '../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/interfaces/INonfungiblePositionManager.sol';
//import { LiquidityManagement } from '../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/base/LiquidityManagement.sol';
import { ProvideLiquidity } from "../../src/L2/Mock/Tokamak-uniswap/uniswap-core/ProvideLiquidity.sol";

import '../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/libraries/PoolAddress.sol';
import '../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/libraries/CallbackValidation.sol';
import '../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/libraries/LiquidityAmounts.sol';
import '../../src/L2/Mock/Tokamak-uniswap/uniswap-core/libraries/TickMath.sol';
import '../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/base/PeripheryPayments.sol';
import '../../src/L2/Mock/Tokamak-uniswap/uniswap-periphery/base/PeripheryImmutableState.sol';
import '../../src/L2/Mock/Tokamak-uniswap/uniswap-core/libraries/SqrtPriceMath.sol';
import '../../src/L2/Mock/Tokamak-uniswap/uniswap-core/libraries/LiquidityMath.sol';

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WstonSwapTest is L2BaseTest {

    address public uniswapV3Factory;
    address public wstonPool;
    address public weth9;
    address public swapRouter;
    address public nonfungiblePositionManager;
    address public nonfungibleTokenPositionDescriptor;
    address public provideLiquidity;
    uint256 fee = 3000;

    function setUp() public override {

        super.setUp();

        vm.startPrank(owner);
        // Deploy the pool contract
        uniswapV3Factory = address(new UniswapV3Factory());
        wstonPool = UniswapV3Factory(uniswapV3Factory).createPool(ton, wston, 3000);
            
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // 1 TON = 1 WSTON
        UniswapV3Pool(wstonPool).initialize(sqrtPriceX96);

        weth9 = address(new Weth9());
        swapRouter = address(new SwapRouter(uniswapV3Factory, weth9));
        
        bytes32 nativeCurrencyLabelBytes = "";
        nonfungibleTokenPositionDescriptor = address(new NonfungibleTokenPositionDescriptor(weth9, nativeCurrencyLabelBytes));
        nonfungiblePositionManager = address(new NonfungiblePositionManager(uniswapV3Factory, weth9, nonfungibleTokenPositionDescriptor));

        provideLiquidity = address(new ProvideLiquidity(INonfungiblePositionManager(nonfungiblePositionManager), ton, wston));

        IUniswapV3Pool(wstonPool).increaseObservationCardinalityNext(10);

        vm.stopPrank();
    }

    function testProvideLiquidity() public {
        vm.startPrank(user1);
        //ProvideLiquidity(provideLiquidity).mintNewPosition();

        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint256 amount0ToMint = 1000;
        uint256 amount1ToMint = 1000;

        // Approve the position manager
        IERC20(ton).approve(address(nonfungiblePositionManager), amount0ToMint);
        IERC20(wston).approve(address(nonfungiblePositionManager), amount1ToMint);

        IERC20(ton).approve(address(this), amount0ToMint);
        IERC20(wston).approve(address(this), amount1ToMint);

        int24 adjustedTickLower = -887220; 
        int24 adjustedTickUpper = 887220; 

        // Initialize the pool's observation cardinality
        //IUniswapV3Pool(wstonPool).increaseObservationCardinalityNext(10);
        this.increaseObservationCardinalityNext(10);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
                token0: ton,
                token1: wston,
                fee: 3000,
                tickLower: adjustedTickLower,
                tickUpper: adjustedTickUpper,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
        });

        /*AddLiquidityParams memory liquidityParams = AddLiquidityParams({
                token0: ton,
                token1: wston,
                fee: 3000,
                tickLower: adjustedTickLower,
                tickUpper: adjustedTickUpper,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this)
        });*/

        uint256 tokenId;
        uint128 _liquidity;
        uint256 amount0;
        uint256 amount1;

        IUniswapV3Pool pool;
        //(_liquidity, amount0, amount1, pool) = addLiquidity(liquidityParams);

        // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized in order to mint
        (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(nonfungiblePositionManager).mint(params);

        vm.stopPrank;
    }  

    struct MintCallbackData {
        PoolAddress.PoolKey poolKey;
        address payer;
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        CallbackValidation.verifyCallback(uniswapV3Factory, decoded.poolKey);

        if (amount0Owed > 0) pay(decoded.poolKey.token0, decoded.payer, msg.sender, amount0Owed);
        if (amount1Owed > 0) pay(decoded.poolKey.token1, decoded.payer, msg.sender, amount1Owed);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == weth9 && address(this).balance >= value) {
            // pay with weth9
            IWETH9(weth9).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(weth9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }

    struct AddLiquidityParams {
        address token0;
        address token1;
        uint24 fee;
        address recipient;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    /// @notice Add liquidity to the wston initialized pool
    function addLiquidity(AddLiquidityParams memory params)
        public
        returns (
            uint128 _liquidity,
            uint256 amount0,
            uint256 amount1,
            IUniswapV3Pool pool
        )
    {

        pool = IUniswapV3Pool(wstonPool);

        // compute the liquidity amount
        {
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
            uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

            _liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                params.amount0Desired,
                params.amount1Desired
            );
        }

        (amount0, amount1) = this.mint(
            params.recipient,
            params.tickLower,
            params.tickUpper,
            _liquidity,
            ""
        );

        console.log("amount0:", amount0);
        console.log("amount1:", amount1);

        require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, 'Price slippage check');
    }


    int24 public  tickSpacing = 60;
    uint128 public maxLiquidityPerTick = 10000;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    Slot0 public slot0;


    uint256 public feeGrowthGlobal0X128;
    uint256 public feeGrowthGlobal1X128;

    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    ProtocolFees public protocolFees;

    uint128 public liquidity;
    
    struct Observation {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        bool initialized;
    }
    Observation[65535] public observations;

    mapping(int24 => TickInfo) public ticks;
    mapping(int16 => uint256) public tickBitmap;
    mapping(bytes32 => PositionInfo) public positions;


    struct ModifyPositionParams {
        address owner;
        int24 tickLower;
        int24 tickUpper;
        int128 liquidityDelta;
    }

    struct TickInfo {
        uint128 liquidityGross;
        int128 liquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        bool initialized;
    }

     struct PositionInfo {
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata 
    ) external returns (uint256 amount0, uint256 amount1) {
        require(amount > 0);

        (, uint256 amount0Int, uint256 amount1Int) =
            _modifyPosition(
                ModifyPositionParams({
                    owner: recipient,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidityDelta: toInt128(int256(uint256(amount)))
                })  
            );

        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        console.log("amount0Int:", amount0Int);
        console.log("amount1Int:", amount1Int);

        if(amount0 > 0) {
            IERC20(ton).transferFrom(msg.sender, address(this), amount0);
        }

        if(amount1 > 0) {
            IERC20(wston).transferFrom(msg.sender, address(this), amount1);
        }

        emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
    }

    event Mint(address sender, address owner, int24 tickLower, int24 tickUpper, uint128 amount, uint256 amount0, uint256 amount1); 

    function _modifyPosition(ModifyPositionParams memory params)
        private
        returns (
            PositionInfo storage _position,
            uint256 amount0,
            uint256 amount1
        )
    {
        checkTicks(params.tickLower, params.tickUpper);

        Slot0 memory _slot0 = slot0;

        _position = _updatePosition(
            params.owner,
            params.tickLower,
            params.tickUpper,
            params.liquidityDelta,
            _slot0.tick
        );
        console.log("params.liquidityDelta:", params.liquidityDelta);
        if (params.liquidityDelta != 0) {
            if (_slot0.tick < params.tickLower) {

                uint160 sqrtRatioAtTickLower = TickMath.getSqrtRatioAtTick(params.tickLower);
                uint160 sqrtRatioAtTickUpper = TickMath.getSqrtRatioAtTick(params.tickUpper);
                console.log("sqrtRatioAtTickLower:", sqrtRatioAtTickLower);
                console.log("sqrtRatioAtTickUpper:", sqrtRatioAtTickUpper);
                console.log("params.liquidityDelta:", params.liquidityDelta);

                amount0 = uint256(SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                ));
            } else if (_slot0.tick < params.tickUpper) {
                uint128 liquidityBefore = liquidity; 
                
                (slot0.observationIndex, slot0.observationCardinality) = write(
                    observations,
                    _slot0.observationIndex,
                    uint32(block.timestamp),
                    _slot0.tick,
                    liquidityBefore,
                    _slot0.observationCardinality,
                    _slot0.observationCardinalityNext
                );
                console.log("slot0.observationIndex", slot0.observationIndex);
                console.log("slot0.observationCardinality", slot0.observationCardinality);

                amount0 = getAmount0Delta(
                    _slot0.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    uint128(params.liquidityDelta),
                    true
                );
                amount1 = getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    _slot0.sqrtPriceX96,
                    uint128(params.liquidityDelta),
                    true
                );

                console.log("amount0:", amount0);
                console.log("amount1:", amount1);

                liquidity = LiquidityMath.addDelta(liquidityBefore, params.liquidityDelta);
            } else {
                amount1 = getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    uint128(params.liquidityDelta),
                    true
                );
            }
        }
    }

    function checkTicks(int24 tickLower, int24 tickUpper) private pure {
        require(tickLower < tickUpper, 'TLU');
        require(tickLower >= TickMath.MIN_TICK, 'TLM');
        require(tickUpper <= TickMath.MAX_TICK, 'TUM');
    }

    // ok
    function _updatePosition(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta,
        int24 tick
    ) private returns (PositionInfo storage _position) {
        _position = get(positions, owner, tickLower, tickUpper);

        uint256 _feeGrowthGlobal0X128 = feeGrowthGlobal0X128; 
        uint256 _feeGrowthGlobal1X128 = feeGrowthGlobal1X128; 

        bool flippedLower;
        bool flippedUpper;
        if (liquidityDelta != 0) {
            uint32 time = uint32(block.timestamp);
            (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) =
                observeSingle(
                    observations,
                    time,
                    0,
                    slot0.tick,
                    slot0.observationIndex,
                    liquidity,
                    slot0.observationCardinality
                );

            flippedLower = update(
                ticks,
                tickLower,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                false,
                maxLiquidityPerTick
            );
            flippedUpper = update(
                ticks,
                tickUpper,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                true,
                maxLiquidityPerTick
            );

            if (flippedLower) {
                flipTick(tickBitmap, tickLower, tickSpacing);
            }
            if (flippedUpper) {
                flipTick(tickBitmap, tickUpper, tickSpacing);
            }
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            getFeeGrowthInside(ticks, tickLower, tickUpper, tick, _feeGrowthGlobal0X128, _feeGrowthGlobal1X128);

        updatePosition(_position, liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

        if (liquidityDelta < 0) {
            if (flippedLower) {
                clear(ticks, tickLower);
            }
            if (flippedUpper) {
                clear(ticks, tickUpper);
            }
        }
    }

    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 _liquidity,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

        // if the conditions are right, we can bump the cardinality
        if (cardinalityNext > cardinality) {
            cardinalityUpdated = cardinalityNext;
        } else {
            cardinalityUpdated = cardinality;
        }

        // Ensure cardinalityUpdated is not zero to avoid division by zero
        console.log("cardinalityUpdated:", cardinalityUpdated);
        require(cardinalityUpdated > 0, "Cardinality must be greater than zero");

        indexUpdated = (index + 1) % cardinalityUpdated;
        self[indexUpdated] = transform(last, blockTimestamp, tick, _liquidity);

        console.log("indexUpdated:", indexUpdated);
        console.log("cardinalityUpdated:", cardinalityUpdated);
        console.log("index:", index);
        console.log("blockTimestamp:", blockTimestamp);
        console.log("tick:", tick);
        console.log("_liquidity:", _liquidity);
        console.log("cardinality:", cardinality);
        console.log("cardinalityNext:", cardinalityNext);
    }


    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick,
        uint128 _liquidity
    ) private pure returns (Observation memory) {
        uint32 delta = blockTimestamp - last.blockTimestamp;
        require(delta > 0, "Delta must be greater than zero");

        uint160 secondsPerLiquidityCumulativeX128;
        if (_liquidity > 0) {
            secondsPerLiquidityCumulativeX128 = last.secondsPerLiquidityCumulativeX128 +
                ((uint160(delta) << 128) / _liquidity);
        } else {
            secondsPerLiquidityCumulativeX128 = last.secondsPerLiquidityCumulativeX128;
        }

        int56 tickCumulative = last.tickCumulative + int56(tick) * int56(int256(uint256(delta)));
        require(tickCumulative >= last.tickCumulative, "Tick cumulative overflow");

        Observation memory newObservation;
        newObservation.blockTimestamp = blockTimestamp;
        newObservation.tickCumulative = tickCumulative;
        newObservation.secondsPerLiquidityCumulativeX128 = secondsPerLiquidityCumulativeX128;
        newObservation.initialized = true;

        return newObservation;
    }


    function get(
        mapping(bytes32 => PositionInfo) storage self,
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (PositionInfo storage _position) {
        _position = self[keccak256(abi.encodePacked(owner, tickLower, tickUpper))];
    }

    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 _liquidity,
        uint16 cardinality
    ) internal view returns (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            if (last.blockTimestamp != time) last = transform(last, time, tick, _liquidity);
            console.log("last.tickCumulative", last.tickCumulative);
            return (last.tickCumulative, last.secondsPerLiquidityCumulativeX128);
        }

        uint32 target = time - secondsAgo;
        console.log("target:", target);

        (Observation memory beforeOrAt, Observation memory atOrAfter) =
            getSurroundingObservations(self, time, target, tick, index, _liquidity, cardinality);

        if (target == beforeOrAt.blockTimestamp) {
            // we're at the left boundary
            return (beforeOrAt.tickCumulative, beforeOrAt.secondsPerLiquidityCumulativeX128);
        } else if (target == atOrAfter.blockTimestamp) {
            // we're at the right boundary
            return (atOrAfter.tickCumulative, atOrAfter.secondsPerLiquidityCumulativeX128);
        } else {
            // we're in the middle
            uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;

            console.log("observationTimeDelta:", observationTimeDelta);
            console.log("targetDelta:", targetDelta);

            require(observationTimeDelta > 0, "Observation time delta must be greater than zero");

            int56 tickCumulativeDelta = (atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / int56(int256(uint256(observationTimeDelta)));
            int56 tickCumulativeResult = beforeOrAt.tickCumulative + (tickCumulativeDelta * int56(int256(uint256(targetDelta))));

            uint160 secondsPerLiquidityCumulativeDelta = uint160(
                (uint256(atOrAfter.secondsPerLiquidityCumulativeX128 - beforeOrAt.secondsPerLiquidityCumulativeX128) * targetDelta) / observationTimeDelta
            );
            uint160 secondsPerLiquidityCumulativeResult = beforeOrAt.secondsPerLiquidityCumulativeX128 + secondsPerLiquidityCumulativeDelta;

            console.log("tickCumulativeResult:", tickCumulativeResult);
            console.log("secondsPerLiquidityCumulativeResult:", secondsPerLiquidityCumulativeResult);

            return (tickCumulativeResult, secondsPerLiquidityCumulativeResult);
        }
    }


    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint128 _liquidity,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (lte(time, beforeOrAt.blockTimestamp, target)) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // otherwise, we need to transform
                return (beforeOrAt, transform(beforeOrAt, target, tick, _liquidity));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(lte(time, beforeOrAt.blockTimestamp, target), 'OLD');

        // if we've reached this point, we have to binary search
        return binarySearch(self, time, target, index, cardinality);
    }

    function lte(
        uint32 time,
        uint32 a,
        uint32 b
    ) private pure returns (bool) {
        // if there hasn't been overflow, no need to adjust
        if (a <= time && b <= time) return a <= b;

        uint256 aAdjusted = a > time ? a : a + 2**32;
        uint256 bAdjusted = b > time ? b : b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = (index +         1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

            // check if we've found the answer!
            if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }


    function update(
        mapping(int24 => TickInfo) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 _feeGrowthGlobal0X128,
        uint256 _feeGrowthGlobal1X128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        TickInfo storage info = self[tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, liquidityDelta);

        require(liquidityGrossAfter <= maxLiquidity, 'LO');

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= tickCurrent) {
                info.feeGrowthOutside0X128 = _feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = _feeGrowthGlobal1X128;
                info.secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128;
                info.tickCumulativeOutside = tickCumulative;
                info.secondsOutside = time;
            }
            info.initialized = true;
        }

        info.liquidityGross = liquidityGrossAfter;

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.liquidityNet = int128(upper
            ? int256(info.liquidityNet) - toInt128(liquidityDelta)
            : int256(info.liquidityNet) + toInt128(liquidityDelta));
    }

    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 _tickSpacing
    ) internal {
        require(tick % _tickSpacing == 0, "Tick not spaced correctly"); // ensure that the tick is spaced
        (int16 wordPos, uint8 bitPos) = position(tick / _tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint256(int256(tick)) % 256);
    }

    function getFeeGrowthInside(
        mapping(int24 => TickInfo) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 _feeGrowthGlobal0X128,
        uint256 _feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        TickInfo storage lower = self[tickLower];
        TickInfo storage upper = self[tickUpper];

        // calculate fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = _feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = _feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
        }

        // calculate fee growth above
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = _feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = _feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;

    }

    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function updatePosition(
        PositionInfo storage self,
        int128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) internal {
        PositionInfo memory _self = self;

        uint128 liquidityNext;
        if (liquidityDelta == 0) {
            require(_self.liquidity > 0, 'NP'); // disallow pokes for 0 liquidity positions
            liquidityNext = _self.liquidity;
        } else {
            liquidityNext = LiquidityMath.addDelta(_self.liquidity, liquidityDelta);
        }

        // calculate accumulated fees
        uint128 tokensOwed0 =
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside0X128 - _self.feeGrowthInside0LastX128,
                    _self.liquidity,
                    Q128
                )
            );
        uint128 tokensOwed1 =
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside1X128 - _self.feeGrowthInside1LastX128,
                    _self.liquidity,
                    Q128
                )
            );

        // update the position
        if (liquidityDelta != 0) self.liquidity = liquidityNext;
        self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
        self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
        if (tokensOwed0 > 0 || tokensOwed1 > 0) {
            // overflow is acceptable, have to withdraw before you hit type(uint128).max fees
            self.tokensOwed0 += tokensOwed0;
            self.tokensOwed1 += tokensOwed1;
        }
    }

    function clear(mapping(int24 => TickInfo) storage self, int24 tick) internal {
        delete self[tick];
    }

    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext)
        external
    {
        uint16 observationCardinalityNextOld = slot0.observationCardinalityNext; // for the event
        uint16 observationCardinalityNextNew =
            grow(observations, observationCardinalityNextOld, observationCardinalityNext);
        slot0.observationCardinalityNext = observationCardinalityNextNew;
        if (observationCardinalityNextOld != observationCardinalityNextNew)
            emit IncreaseObservationCardinalityNext(observationCardinalityNextOld, observationCardinalityNextNew);
    }

    function grow(
        Observation[65535] storage self,
        uint16 current,
        uint16 next
    ) internal returns (uint16) {
        //require(current > 0, 'I');
        // no-op if the passed next value isn't greater than the current next value
        if (next <= current) return current;
        // store in each slot to prevent fresh SSTOREs in swaps
        // this data will not be used because the initialized boolean is still false
        for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
        return next;
    }

    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 _liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(_liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        if(sqrtRatioAX96 == 0) return 0;
        else {
            return
                roundUp
                    ? UnsafeMath.divRoundingUp(
                        FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                        sqrtRatioAX96
                    )
                    : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
        }
    }

    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 _liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(_liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                : FullMath.mulDiv(_liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }
}
