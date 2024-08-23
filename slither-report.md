**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [arbitrary-send-erc20](#arbitrary-send-erc20) (3 results) (High)
 - [weak-prng](#weak-prng) (4 results) (High)
 - [incorrect-exp](#incorrect-exp) (1 results) (High)
 - [reentrancy-eth](#reentrancy-eth) (2 results) (High)
 - [uninitialized-state](#uninitialized-state) (1 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (12 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (39 results) (Medium)
 - [locked-ether](#locked-ether) (4 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (8 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (16 results) (Medium)
 - [unused-return](#unused-return) (10 results) (Medium)
 - [shadowing-local](#shadowing-local) (11 results) (Low)
 - [events-access](#events-access) (4 results) (Low)
 - [events-maths](#events-maths) (5 results) (Low)
 - [missing-zero-check](#missing-zero-check) (44 results) (Low)
 - [calls-loop](#calls-loop) (14 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (15 results) (Low)
 - [reentrancy-events](#reentrancy-events) (15 results) (Low)
 - [timestamp](#timestamp) (16 results) (Low)
 - [assembly](#assembly) (29 results) (Informational)
 - [boolean-equal](#boolean-equal) (11 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [cyclomatic-complexity](#cyclomatic-complexity) (1 results) (Informational)
 - [dead-code](#dead-code) (14 results) (Informational)
 - [solc-version](#solc-version) (6 results) (Informational)
 - [low-level-calls](#low-level-calls) (5 results) (Informational)
 - [missing-inheritance](#missing-inheritance) (11 results) (Informational)
 - [naming-convention](#naming-convention) (197 results) (Informational)
 - [too-many-digits](#too-many-digits) (2 results) (Informational)
 - [unused-import](#unused-import) (6 results) (Informational)
 - [unused-state](#unused-state) (2 results) (Informational)
 - [cache-array-length](#cache-array-length) (1 results) (Optimization)
 - [constable-states](#constable-states) (51 results) (Optimization)
 - [immutable-states](#immutable-states) (18 results) (Optimization)
## arbitrary-send-erc20
Impact: High
Confidence: High
 - [ ] ID-0
[MarketPlace._buyGem(uint256,address,bool)](src/L2/MarketPlace.sol#L121-L149) uses arbitrary from in transferFrom: [IERC20(wston_).safeTransferFrom(_treasury,seller,price)](src/L2/MarketPlace.sol#L138)

src/L2/MarketPlace.sol#L121-L149


 - [ ] ID-1
[MarketPlace._buyGem(uint256,address,bool)](src/L2/MarketPlace.sol#L121-L149) uses arbitrary from in transferFrom: [IGemFactory(gemFactory).transferFrom(seller,_payer,_tokenId)](src/L2/MarketPlace.sol#L144)

src/L2/MarketPlace.sol#L121-L149


 - [ ] ID-2
[GemFactory.safeTransferFrom(address,address,uint256,bytes)](src/L2/GemFactory.sol#L777-L785) uses arbitrary from in transferFrom: [this.transferFrom(from,to,tokenId)](src/L2/GemFactory.sol#L781)

src/L2/GemFactory.sol#L777-L785


## weak-prng
Impact: High
Confidence: Medium
 - [ ] ID-3
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) uses a weak PRNG: "[sumOfQuadrants[3] %= 2](src/L2/GemFactory.sol#L263)" 

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-4
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) uses a weak PRNG: "[sumOfQuadrants[0] %= 2](src/L2/GemFactory.sol#L260)" 

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-5
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) uses a weak PRNG: "[sumOfQuadrants[2] %= 2](src/L2/GemFactory.sol#L262)" 

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-6
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) uses a weak PRNG: "[sumOfQuadrants[1] %= 2](src/L2/GemFactory.sol#L261)" 

src/L2/GemFactory.sol#L184-L325


## incorrect-exp
Impact: High
Confidence: Medium
 - [ ] ID-7
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) has bitwise-xor operator ^ instead of the exponentiation operator **: 
	 - [inverse = (3 * denominator) ^ 2](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L184)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


## reentrancy-eth
Impact: High
Confidence: Medium
 - [ ] ID-8
Reentrancy in [GemFactory.pickMinedGEM(uint256)](src/L2/GemFactory.sol#L371-L394):
	External calls:
	- [requestId = requestRandomness(0,0,CALLBACK_GAS_LIMIT)](src/L2/GemFactory.sol#L378)
		- [requestId = i_drbCoordinator.requestRandomWordDirectFunding{value: msg.value}(IDRBCoordinator.RandomWordsRequest({security:security,mode:mode,callbackGasLimit:callbackGasLimit}))](src/L2/Randomness/DRBConsumerBase.sol#L34-L42)
	- [IDRBCoordinator(drbcoordinator).fulfillRandomness(requestId)](src/L2/GemFactory.sol#L389)
	External calls sending eth:
	- [requestId = requestRandomness(0,0,CALLBACK_GAS_LIMIT)](src/L2/GemFactory.sol#L378)
		- [requestId = i_drbCoordinator.requestRandomWordDirectFunding{value: msg.value}(IDRBCoordinator.RandomWordsRequest({security:security,mode:mode,callbackGasLimit:callbackGasLimit}))](src/L2/Randomness/DRBConsumerBase.sol#L34-L42)
	State variables written after the call(s):
	- [Gems[_tokenId].randomRequestId = requestId](src/L2/GemFactory.sol#L390)
	[GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38) can be used in cross function reentrancies:
	- [GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38)
	- [GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940)
	- [GemFactory._transferGEM(address,address,uint256)](src/L2/GemFactory.sol#L942-L947)
	- [GemFactory.burnToken(address,uint256)](src/L2/GemFactory.sol#L440-L449)
	- [GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369)
	- [GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428)
	- [GemFactory.countGemsByQuadrant(uint8,uint8,uint8,uint8)](src/L2/GemFactory.sol#L1079-L1105)
	- [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593)
	- [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757)
	- [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325)
	- [GemFactory.fulfillRandomWords(uint256,uint256)](src/L2/GemFactory.sol#L950-L967)
	- [GemFactory.getGem(uint256)](src/L2/GemFactory.sol#L1108-L1111)
	- [GemFactory.isTokenLocked(uint256)](src/L2/GemFactory.sol#L1065-L1067)
	- [GemFactory.meltGEM(uint256)](src/L2/GemFactory.sol#L430-L438)
	- [GemFactory.setIsLocked(uint256,bool)](src/L2/GemFactory.sol#L824-L826)
	- [GemFactory.startMiningGEM(uint256)](src/L2/GemFactory.sol#L332-L354)
	- [GemFactory.totalSupply()](src/L2/GemFactory.sol#L1144-L1146)
	- [GemFactory.transferFrom(address,address,uint256)](src/L2/GemFactory.sol#L759-L775)

src/L2/GemFactory.sol#L371-L394


 - [ ] ID-9
Reentrancy in [GemFactory.pickMinedGEM(uint256)](src/L2/GemFactory.sol#L371-L394):
	External calls:
	- [requestId = requestRandomness(0,0,CALLBACK_GAS_LIMIT)](src/L2/GemFactory.sol#L378)
		- [requestId = i_drbCoordinator.requestRandomWordDirectFunding{value: msg.value}(IDRBCoordinator.RandomWordsRequest({security:security,mode:mode,callbackGasLimit:callbackGasLimit}))](src/L2/Randomness/DRBConsumerBase.sol#L34-L42)
	State variables written after the call(s):
	- [Gems[_tokenId].randomRequestId = requestId](src/L2/GemFactory.sol#L380)
	[GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38) can be used in cross function reentrancies:
	- [GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38)
	- [GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940)
	- [GemFactory._transferGEM(address,address,uint256)](src/L2/GemFactory.sol#L942-L947)
	- [GemFactory.burnToken(address,uint256)](src/L2/GemFactory.sol#L440-L449)
	- [GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369)
	- [GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428)
	- [GemFactory.countGemsByQuadrant(uint8,uint8,uint8,uint8)](src/L2/GemFactory.sol#L1079-L1105)
	- [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593)
	- [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757)
	- [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325)
	- [GemFactory.fulfillRandomWords(uint256,uint256)](src/L2/GemFactory.sol#L950-L967)
	- [GemFactory.getGem(uint256)](src/L2/GemFactory.sol#L1108-L1111)
	- [GemFactory.isTokenLocked(uint256)](src/L2/GemFactory.sol#L1065-L1067)
	- [GemFactory.meltGEM(uint256)](src/L2/GemFactory.sol#L430-L438)
	- [GemFactory.setIsLocked(uint256,bool)](src/L2/GemFactory.sol#L824-L826)
	- [GemFactory.startMiningGEM(uint256)](src/L2/GemFactory.sol#L332-L354)
	- [GemFactory.totalSupply()](src/L2/GemFactory.sol#L1144-L1146)
	- [GemFactory.transferFrom(address,address,uint256)](src/L2/GemFactory.sol#L759-L775)

src/L2/GemFactory.sol#L371-L394


## uninitialized-state
Impact: High
Confidence: High
 - [ ] ID-10
[CandidateStorage._supportedInterfaces](src/L1/Mock/CandidateStorage.sol#L7) is never initialized. It is used in:
	- [Candidate.supportsInterface(bytes4)](src/L1/Mock/Candidate.sol#L44-L46)

src/L1/Mock/CandidateStorage.sol#L7


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-11
[WstonSwapPool.swapTONforWSTON(uint256)](src/L2/WstonSwapPool.sol#L112-L132) performs a multiplication on the result of a division:
	- [wstonAmount = (tonAmount * (10 ** 9) * DECIMALS) / stakingIndex](src/L2/WstonSwapPool.sol#L116)
	- [fee = (wstonAmount * feeRate) / FEE_RATE_DIVIDER](src/L2/WstonSwapPool.sol#L117)

src/L2/WstonSwapPool.sol#L112-L132


 - [ ] ID-12
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L169)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L192)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


 - [ ] ID-13
[OptimismL1Fees._calculateOptimismL1DataFee(uint256)](src/L2/Mock/OptimismL1Fees.sol#L96-L114) performs a multiplication on the result of a division:
	- [(s_l1FeeCoefficient * (fee / (16 * 10 ** OVM_GASPRICEORACLE.decimals()))) / 100](src/L2/Mock/OptimismL1Fees.sol#L111-L113)

src/L2/Mock/OptimismL1Fees.sol#L96-L114


 - [ ] ID-14
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L169)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L191)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


 - [ ] ID-15
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) performs a multiplication on the result of a division:
	- [prod0 = prod0 / twos](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L172)
	- [result = prod0 * inverse](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L199)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


 - [ ] ID-16
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L169)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L190)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


 - [ ] ID-17
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L169)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L193)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


 - [ ] ID-18
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L169)
	- [inverse = (3 * denominator) ^ 2](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L184)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


 - [ ] ID-19
[WstonSwapPool.swapWSTONforTON(uint256)](src/L2/WstonSwapPool.sol#L90-L110) performs a multiplication on the result of a division:
	- [tonAmount = ((wstonAmount * stakingIndex) / DECIMALS) / (10 ** 9)](src/L2/WstonSwapPool.sol#L94)
	- [fee = (tonAmount * feeRate) / FEE_RATE_DIVIDER](src/L2/WstonSwapPool.sol#L95)

src/L2/WstonSwapPool.sol#L90-L110


 - [ ] ID-20
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L169)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L188)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


 - [ ] ID-21
[MarketPlace._buyGem(uint256,address,bool)](src/L2/MarketPlace.sol#L121-L149) performs a multiplication on the result of a division:
	- [wtonPrice = (price * stakingIndex) / DECIMALS](src/L2/MarketPlace.sol#L135)
	- [totalprice = _toWAD(wtonPrice + ((wtonPrice * tonFeesRate) / TON_FEES_RATE_DIVIDER))](src/L2/MarketPlace.sol#L136)

src/L2/MarketPlace.sol#L121-L149


 - [ ] ID-22
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L169)
	- [inverse *= 2 - denominator * inverse](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L189)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-23
[GemFactory.getCooldownPeriod(GemFactoryStorage.Rarity)](src/L2/GemFactory.sol#L982-L990) uses a dangerous strict equality:
	- [rarity == Rarity.UNIQUE](src/L2/GemFactory.sol#L985)

src/L2/GemFactory.sol#L982-L990


 - [ ] ID-24
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) uses a dangerous strict equality:
	- [forgedQuadrants[0] == baseValue + 1 && forgedQuadrants[1] == baseValue + 1 && forgedQuadrants[2] == baseValue + 1 && forgedQuadrants[3] == baseValue + 1](src/L2/GemFactory.sol#L280-L283)

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-25
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_1))](src/L2/GemFactory.sol#L918)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-26
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [_color1_0 == _color1_1 && _color2_0 == _color2_1 && _color1_0 == _color2_0](src/L2/GemFactory.sol#L870)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-27
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) uses a dangerous strict equality:
	- [require(bool,string)(Gems[_tokenIds[i]].rarity == _rarity,wrong rarity Gems)](src/L2/GemFactory.sol#L240)

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-28
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [(_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_1)](src/L2/GemFactory.sol#L919)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-29
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color1_1 && _color_1 == _color2_1) || (_color_0 == _color2_0 && _color_1 == _color1_0) || (_color_0 == _color2_0 && _color_1 == _color1_1) || (_color_0 == _color2_1 && _color_1 == _color1_0) || (_color_0 == _color2_1 && _color_1 == _color1_1))](src/L2/GemFactory.sol#L930-L933)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-30
[GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757) uses a dangerous strict equality:
	- [require(bool)(newGemId == uint256(uint32(newGemId)))](src/L2/GemFactory.sol#L743)

src/L2/GemFactory.sol#L603-L757


 - [ ] ID-31
[GemFactory.getCooldownPeriod(GemFactoryStorage.Rarity)](src/L2/GemFactory.sol#L982-L990) uses a dangerous strict equality:
	- [rarity == Rarity.MYTHIC](src/L2/GemFactory.sol#L988)

src/L2/GemFactory.sol#L982-L990


 - [ ] ID-32
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [_color1_0 != _color1_1 && _color2_0 != _color2_1 && (_color1_0 == _color2_0 || _color1_0 == _color2_1 || _color1_1 == _color2_0 || _color1_1 == _color2_1)](src/L2/GemFactory.sol#L913)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-33
[GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593) uses a dangerous strict equality:
	- [require(bool)(newGemId == uint256(uint32(newGemId)))](src/L2/GemFactory.sol#L581)

src/L2/GemFactory.sol#L465-L593


 - [ ] ID-34
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color2_0 && _color_1 == _color2_1) || (_color_1 == _color2_0 && _color_0 == _color2_1))](src/L2/GemFactory.sol#L886)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-35
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [_color1_0 == _color1_1 && _color2_0 == _color2_1](src/L2/GemFactory.sol#L875)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-36
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_0))](src/L2/GemFactory.sol#L876)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-37
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = (_color_0 == _color1_0 && _color_1 == _color1_1)](src/L2/GemFactory.sol#L871)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-38
[SeigManager._calcSeigsDistribution(address,RefactorCoinageSnapshotI,uint256,uint256,bool,address)](src/L1/Mock/SeigManager.sol#L608-L675) uses a dangerous strict equality:
	- [operatorRate == RAY](src/L1/Mock/SeigManager.sol#L668-L670)

src/L1/Mock/SeigManager.sol#L608-L675


 - [ ] ID-39
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [_color1_0 != _color1_1 && _color2_0 != _color2_1 && ((_color1_0 == _color2_0 && _color1_1 == _color2_1) || (_color1_0 == _color2_1 && _color1_1 == _color2_0))](src/L2/GemFactory.sol#L908)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-40
[SeigManager._calcSeigsDistribution(address,RefactorCoinageSnapshotI,uint256,uint256,bool,address)](src/L1/Mock/SeigManager.sol#L608-L675) uses a dangerous strict equality:
	- [operatorRate == RAY](src/L1/Mock/SeigManager.sol#L663-L665)

src/L1/Mock/SeigManager.sol#L608-L675


 - [ ] ID-41
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [_color1_0 == _color2_0](src/L2/GemFactory.sol#L914)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-42
[GemFactory.getCooldownPeriod(GemFactoryStorage.Rarity)](src/L2/GemFactory.sol#L982-L990) uses a dangerous strict equality:
	- [rarity == Rarity.LEGENDARY](src/L2/GemFactory.sol#L987)

src/L2/GemFactory.sol#L982-L990


 - [ ] ID-43
[DSMath.mul(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L11-L13) uses a dangerous strict equality:
	- [require(bool,string)(y == 0 || (z = x * y) / y == x,ds-math-mul-overflow)](src/L1/Mock/libraries/DSMath.sol#L12)

src/L1/Mock/libraries/DSMath.sol#L11-L13


 - [ ] ID-44
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [_color1_1 == _color2_1](src/L2/GemFactory.sol#L923)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-45
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_0 == _color2_1 && _color_1 == _color1_0))](src/L2/GemFactory.sol#L921)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-46
[SeigManager._calcSeigsDistribution(address,RefactorCoinageSnapshotI,uint256,uint256,bool,address)](src/L1/Mock/SeigManager.sol#L608-L675) uses a dangerous strict equality:
	- [operatorBalance == 0](src/L1/Mock/SeigManager.sol#L650)

src/L1/Mock/SeigManager.sol#L608-L675


 - [ ] ID-47
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [((_color1_0 != _color1_1 && _color2_0 == _color2_1) && (_color1_0 == _color2_0 || _color1_1 == _color2_0)) || ((_color1_0 == _color1_1 && _color2_0 != _color2_1) && (_color2_0 == _color1_0 || _color2_1 == _color1_0))](src/L2/GemFactory.sol#L881)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-48
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color1_1) || (_color_0 == _color1_1 && _color_1 == _color1_0))](src/L2/GemFactory.sol#L909)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-49
[GemFactory.getCooldownPeriod(GemFactoryStorage.Rarity)](src/L2/GemFactory.sol#L982-L990) uses a dangerous strict equality:
	- [rarity == Rarity.COMMON](src/L2/GemFactory.sol#L983)

src/L2/GemFactory.sol#L982-L990


 - [ ] ID-50
[SeigManager.initialize(address,address,address,address,uint256,address,uint256)](src/L1/Mock/SeigManager.sol#L158-L182) uses a dangerous strict equality:
	- [require(bool,string)(_ton == address(0) && _lastSeigBlock == 0,already initialized)](src/L1/Mock/SeigManager.sol#L167)

src/L1/Mock/SeigManager.sol#L158-L182


 - [ ] ID-51
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [((_color1_0 != _color1_1 && _color2_0 == _color2_1) && (_color1_0 != _color2_0 && _color1_1 != _color2_0)) || ((_color1_0 == _color1_1 && _color2_0 != _color2_1) && (_color1_0 != _color2_0 && _color1_0 != _color2_1))](src/L2/GemFactory.sol#L891)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-52
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [_color1_0 == _color2_1](src/L2/GemFactory.sol#L917)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-53
[GemFactory.getCooldownPeriod(GemFactoryStorage.Rarity)](src/L2/GemFactory.sol#L982-L990) uses a dangerous strict equality:
	- [rarity == Rarity.RARE](src/L2/GemFactory.sol#L984)

src/L2/GemFactory.sol#L982-L990


 - [ ] ID-54
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) uses a dangerous strict equality:
	- [require(bool)(newGemId == uint256(uint32(newGemId)))](src/L2/GemFactory.sol#L313)

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-55
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [_color1_1 == _color2_0](src/L2/GemFactory.sol#L920)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-56
[GemFactory.getCooldownPeriod(GemFactoryStorage.Rarity)](src/L2/GemFactory.sol#L982-L990) uses a dangerous strict equality:
	- [rarity == Rarity.EPIC](src/L2/GemFactory.sol#L986)

src/L2/GemFactory.sol#L982-L990


 - [ ] ID-57
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_1 == _color1_0 && _color_0 == _color2_0) || (_color_1 == _color1_1 && _color_0 == _color2_0))](src/L2/GemFactory.sol#L893-L896)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-58
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_0))](src/L2/GemFactory.sol#L924)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-59
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_1 == _color1_0 && _color_0 == _color2_0) || (_color_1 == _color1_0 && _color_0 == _color2_1))](src/L2/GemFactory.sol#L899-L902)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-60
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_1 && _color_1 == _color2_1) || (_color_0 == _color2_1 && _color_1 == _color1_1))](src/L2/GemFactory.sol#L915)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-61
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses a dangerous strict equality:
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color1_1) || (_color_1 == _color1_0 && _color_0 == _color1_1))](src/L2/GemFactory.sol#L883)

src/L2/GemFactory.sol#L859-L940


## locked-ether
Impact: Medium
Confidence: High
 - [ ] ID-62
Contract locking ether found:
	Contract [DRBCoordinatorMock](src/L2/Mock/DRBCoordinatorMock.sol#L11-L182) has payable functions:
	 - [IDRBCoordinator.requestRandomWordDirectFunding(IDRBCoordinator.RandomWordsRequest)](src/interfaces/IDRBCoordinator.sol#L18-L20)
	 - [DRBCoordinatorMock.requestRandomWordDirectFunding(IDRBCoordinator.RandomWordsRequest)](src/L2/Mock/DRBCoordinatorMock.sol#L60-L74)
	But does not have a function to withdraw the ether

src/L2/Mock/DRBCoordinatorMock.sol#L11-L182


 - [ ] ID-63
Contract locking ether found:
	Contract [GemFactoryProxy](src/L2/GemFactoryProxy.sol#L11-L13) has payable functions:
	 - [ProxyGemFactory.receive()](src/proxy/ProxyGemFactory.sol#L103-L105)
	 - [ProxyGemFactory.fallback()](src/proxy/ProxyGemFactory.sol#L108-L110)
	But does not have a function to withdraw the ether

src/L2/GemFactoryProxy.sol#L11-L13


 - [ ] ID-64
Contract locking ether found:
	Contract [RefactorCoinageSnapshotProxy](src/L1/Mock/proxy/RefactorCoinageSnapshotProxy.sol#L11-L13) has payable functions:
	 - [ProxyCoinage.receive()](src/L1/Mock/proxy/ProxyCoinage.sol#L116-L118)
	 - [ProxyCoinage.fallback()](src/L1/Mock/proxy/ProxyCoinage.sol#L121-L123)
	But does not have a function to withdraw the ether

src/L1/Mock/proxy/RefactorCoinageSnapshotProxy.sol#L11-L13


 - [ ] ID-65
Contract locking ether found:
	Contract [L1WrappedStakedTONProxy](src/L1/L1WrappedStakedTONProxy.sol#L11-L14) has payable functions:
	 - [ProxyL1WrappedStakedTON.receive()](src/proxy/ProxyL1WrappedStakedTON.sol#L103-L105)
	 - [ProxyL1WrappedStakedTON.fallback()](src/proxy/ProxyL1WrappedStakedTON.sol#L108-L110)
	But does not have a function to withdraw the ether

src/L1/L1WrappedStakedTONProxy.sol#L11-L14


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-66
Reentrancy in [L1WrappedStakedTON._depositAndGetWSTONTo(address,uint256)](src/L1/L1WrappedStakedTON.sol#L74-L119):
	External calls:
	- [require(bool,string)(IERC20(wton).transferFrom(_to,address(this),_amount),failed to transfer wton to this contract)](src/L1/L1WrappedStakedTON.sol#L82-L85)
	- [require(bool,string)(ICandidate(layer2Address).updateSeigniorage(),failed to update seigniorage)](src/L1/L1WrappedStakedTON.sol#L89)
	- [IERC20(wton).approve(depositManager,_amount)](src/L1/L1WrappedStakedTON.sol#L97)
	- [require(bool,string)(IDepositManager(depositManager).deposit(layer2Address,_amount),failed to stake)](src/L1/L1WrappedStakedTON.sol#L100-L106)
	State variables written after the call(s):
	- [totalWstonMinted += wstonAmount](src/L1/L1WrappedStakedTON.sol#L114)
	[L1WrappedStakedTONStorage.totalWstonMinted](src/L1/L1WrappedStakedTONStorage.sol#L21) can be used in cross function reentrancies:
	- [L1WrappedStakedTON.totalSupply()](src/L1/L1WrappedStakedTON.sol#L226-L228)
	- [L1WrappedStakedTONStorage.totalWstonMinted](src/L1/L1WrappedStakedTONStorage.sol#L21)
	- [L1WrappedStakedTON.updateStakingIndex()](src/L1/L1WrappedStakedTON.sol#L192-L206)

src/L1/L1WrappedStakedTON.sol#L74-L119


 - [ ] ID-67
Reentrancy in [SeigManager.deployCoinage(address)](src/L1/Mock/SeigManager.sol#L292-L303):
	External calls:
	- [c = CoinageFactoryI(factory).deploy()](src/L1/Mock/SeigManager.sol#L295)
	State variables written after the call(s):
	- [_coinages[layer2] = RefactorCoinageSnapshotI(c)](src/L1/Mock/SeigManager.sol#L298)
	[SeigManagerStorage._coinages](src/L1/Mock/SeigManagerStorage.sol#L45) can be used in cross function reentrancies:
	- [SeigManager._additionalTotBurnAmount(address,address,uint256)](src/L1/Mock/SeigManager.sol#L584-L605)
	- [SeigManager.checkCoinage(address)](src/L1/Mock/SeigManager.sol#L114-L117)
	- [SeigManager.coinages(address)](src/L1/Mock/SeigManager.sol#L780)
	- [SeigManager.deployCoinage(address)](src/L1/Mock/SeigManager.sol#L292-L303)
	- [SeigManager.getOperatorAmount(address)](src/L1/Mock/SeigManager.sol#L484-L487)
	- [SeigManager.onDeposit(address,address,uint256)](src/L1/Mock/SeigManager.sol#L355-L369)
	- [SeigManager.onWithdraw(address,address,uint256)](src/L1/Mock/SeigManager.sol#L371-L394)
	- [SeigManager.stakeOf(address,address)](src/L1/Mock/SeigManager.sol#L529-L531)
	- [SeigManager.stakeOf(address)](src/L1/Mock/SeigManager.sol#L537-L544)
	- [SeigManager.stakeOfAt(address,uint256)](src/L1/Mock/SeigManager.sol#L546-L553)
	- [SeigManager.stakeOfAt(address,address,uint256)](src/L1/Mock/SeigManager.sol#L533-L535)
	- [SeigManager.uncomittedStakeOf(address,address)](src/L1/Mock/SeigManager.sol#L513-L527)
	- [SeigManager.updateSeigniorage()](src/L1/Mock/SeigManager.sol#L404-L477)

src/L1/Mock/SeigManager.sol#L292-L303


 - [ ] ID-68
Reentrancy in [MarketPlace._buyGem(uint256,address,bool)](src/L2/MarketPlace.sol#L121-L149):
	External calls:
	- [IERC20(wston_).safeTransferFrom(_payer,seller,price)](src/L2/MarketPlace.sol#L133)
	- [IERC20(ton_).safeTransferFrom(_payer,_treasury,totalprice)](src/L2/MarketPlace.sol#L137)
	- [IERC20(wston_).safeTransferFrom(_treasury,seller,price)](src/L2/MarketPlace.sol#L138)
	State variables written after the call(s):
	- [gemsForSale[_tokenId].isActive = false](src/L2/MarketPlace.sol#L141)
	[MarketPlaceStorage.gemsForSale](src/L2/MarketPlaceStorage.sol#L12) can be used in cross function reentrancies:
	- [MarketPlace._buyGem(uint256,address,bool)](src/L2/MarketPlace.sol#L121-L149)
	- [MarketPlace._putGemForSale(uint256,uint256,address)](src/L2/MarketPlace.sol#L104-L119)
	- [MarketPlaceStorage.gemsForSale](src/L2/MarketPlaceStorage.sol#L12)

src/L2/MarketPlace.sol#L121-L149


 - [ ] ID-69
Reentrancy in [L1WrappedStakedTON._depositAndGetWSTONTo(address,uint256)](src/L1/L1WrappedStakedTON.sol#L74-L119):
	External calls:
	- [require(bool,string)(IERC20(wton).transferFrom(_to,address(this),_amount),failed to transfer wton to this contract)](src/L1/L1WrappedStakedTON.sol#L82-L85)
	- [require(bool,string)(ICandidate(layer2Address).updateSeigniorage(),failed to update seigniorage)](src/L1/L1WrappedStakedTON.sol#L89)
	State variables written after the call(s):
	- [lastSeigBlock = block.number](src/L1/L1WrappedStakedTON.sol#L91)
	[L1WrappedStakedTONStorage.lastSeigBlock](src/L1/L1WrappedStakedTONStorage.sol#L23) can be used in cross function reentrancies:
	- [L1WrappedStakedTONStorage.lastSeigBlock](src/L1/L1WrappedStakedTONStorage.sol#L23)

src/L1/L1WrappedStakedTON.sol#L74-L119


 - [ ] ID-70
Reentrancy in [L1WrappedStakedTON._requestWithdrawal(address,uint256,uint256)](src/L1/L1WrappedStakedTON.sol#L131-L156):
	External calls:
	- [require(bool,string)(IDepositManager(depositManager).requestWithdrawal(layer2Address,_amountToWithdraw),failed to request withdrawal from the deposit manager)](src/L1/L1WrappedStakedTON.sol#L140-L143)
	State variables written after the call(s):
	- [_burn(_to,_wstonAmount)](src/L1/L1WrappedStakedTON.sol#L152)
		- [_balances[from] = fromBalance - value](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L199)
		- [_balances[to] += value](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L211)
	[ERC20._balances](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L35) can be used in cross function reentrancies:
	- [ERC20._update(address,address,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L188-L216)
	- [ERC20.balanceOf(address)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L97-L99)

src/L1/L1WrappedStakedTON.sol#L131-L156


 - [ ] ID-71
Reentrancy in [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757):
	External calls:
	- [_safeMint(msg.sender,newGemId)](src/L2/GemFactory.sol#L749)
		- [retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L467-L480)
	State variables written after the call(s):
	- [Gems.push(_Gem)](src/L2/GemFactory.sol#L739)
	[GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38) can be used in cross function reentrancies:
	- [GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38)
	- [GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940)
	- [GemFactory._transferGEM(address,address,uint256)](src/L2/GemFactory.sol#L942-L947)
	- [GemFactory.burnToken(address,uint256)](src/L2/GemFactory.sol#L440-L449)
	- [GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369)
	- [GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428)
	- [GemFactory.countGemsByQuadrant(uint8,uint8,uint8,uint8)](src/L2/GemFactory.sol#L1079-L1105)
	- [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593)
	- [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757)
	- [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325)
	- [GemFactory.fulfillRandomWords(uint256,uint256)](src/L2/GemFactory.sol#L950-L967)
	- [GemFactory.getGem(uint256)](src/L2/GemFactory.sol#L1108-L1111)
	- [GemFactory.isTokenLocked(uint256)](src/L2/GemFactory.sol#L1065-L1067)
	- [GemFactory.meltGEM(uint256)](src/L2/GemFactory.sol#L430-L438)
	- [GemFactory.setIsLocked(uint256,bool)](src/L2/GemFactory.sol#L824-L826)
	- [GemFactory.startMiningGEM(uint256)](src/L2/GemFactory.sol#L332-L354)
	- [GemFactory.totalSupply()](src/L2/GemFactory.sol#L1144-L1146)
	- [GemFactory.transferFrom(address,address,uint256)](src/L2/GemFactory.sol#L759-L775)
	- [Gems[newGemId].tokenId = uint32(newGemId)](src/L2/GemFactory.sol#L744)
	[GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38) can be used in cross function reentrancies:
	- [GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38)
	- [GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940)
	- [GemFactory._transferGEM(address,address,uint256)](src/L2/GemFactory.sol#L942-L947)
	- [GemFactory.burnToken(address,uint256)](src/L2/GemFactory.sol#L440-L449)
	- [GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369)
	- [GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428)
	- [GemFactory.countGemsByQuadrant(uint8,uint8,uint8,uint8)](src/L2/GemFactory.sol#L1079-L1105)
	- [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593)
	- [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757)
	- [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325)
	- [GemFactory.fulfillRandomWords(uint256,uint256)](src/L2/GemFactory.sol#L950-L967)
	- [GemFactory.getGem(uint256)](src/L2/GemFactory.sol#L1108-L1111)
	- [GemFactory.isTokenLocked(uint256)](src/L2/GemFactory.sol#L1065-L1067)
	- [GemFactory.meltGEM(uint256)](src/L2/GemFactory.sol#L430-L438)
	- [GemFactory.setIsLocked(uint256,bool)](src/L2/GemFactory.sol#L824-L826)
	- [GemFactory.startMiningGEM(uint256)](src/L2/GemFactory.sol#L332-L354)
	- [GemFactory.totalSupply()](src/L2/GemFactory.sol#L1144-L1146)
	- [GemFactory.transferFrom(address,address,uint256)](src/L2/GemFactory.sol#L759-L775)
	- [ownershipTokenCount[msg.sender] ++](src/L2/GemFactory.sol#L746)
	[GemFactoryStorage.ownershipTokenCount](src/L2/GemFactoryStorage.sol#L50) can be used in cross function reentrancies:
	- [GemFactory._transferGEM(address,address,uint256)](src/L2/GemFactory.sol#L942-L947)
	- [GemFactory.balanceOf(address)](src/L2/GemFactory.sol#L992-L994)
	- [GemFactory.burnToken(address,uint256)](src/L2/GemFactory.sol#L440-L449)
	- [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593)
	- [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757)
	- [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325)
	- [GemFactoryStorage.ownershipTokenCount](src/L2/GemFactoryStorage.sol#L50)

src/L2/GemFactory.sol#L603-L757


 - [ ] ID-72
Reentrancy in [SeigManager.initialize(address,address,address,address,uint256,address,uint256)](src/L1/Mock/SeigManager.sol#L158-L182):
	External calls:
	- [c = CoinageFactoryI(factory).deploy()](src/L1/Mock/SeigManager.sol#L176)
	State variables written after the call(s):
	- [_lastSeigBlock = lastSeigBlock_](src/L1/Mock/SeigManager.sol#L180)
	[SeigManagerStorage._lastSeigBlock](src/L1/Mock/SeigManagerStorage.sol#L54) can be used in cross function reentrancies:
	- [SeigManager._calcNumSeigBlocks()](src/L1/Mock/SeigManager.sol#L682-L691)
	- [SeigManager._increaseTot()](src/L1/Mock/SeigManager.sol#L698-L766)
	- [SeigManager.initialize(address,address,address,address,uint256,address,uint256)](src/L1/Mock/SeigManager.sol#L158-L182)
	- [SeigManager.lastSeigBlock()](src/L1/Mock/SeigManager.sol#L786)
	- [SeigManager.updateSeigniorage()](src/L1/Mock/SeigManager.sol#L404-L477)

src/L1/Mock/SeigManager.sol#L158-L182


 - [ ] ID-73
Reentrancy in [GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428):
	External calls:
	- [require(bool,string)(ITreasury(treasury).transferTreasuryGEMto(msg.sender,s_requests[requestId].chosenTokenId),failed to transfer token)](src/L2/GemFactory.sol#L417)
	State variables written after the call(s):
	- [Gems[_tokenId].randomRequestId = 0](src/L2/GemFactory.sol#L419)
	[GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38) can be used in cross function reentrancies:
	- [GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38)
	- [GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940)
	- [GemFactory._transferGEM(address,address,uint256)](src/L2/GemFactory.sol#L942-L947)
	- [GemFactory.burnToken(address,uint256)](src/L2/GemFactory.sol#L440-L449)
	- [GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369)
	- [GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428)
	- [GemFactory.countGemsByQuadrant(uint8,uint8,uint8,uint8)](src/L2/GemFactory.sol#L1079-L1105)
	- [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593)
	- [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757)
	- [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325)
	- [GemFactory.fulfillRandomWords(uint256,uint256)](src/L2/GemFactory.sol#L950-L967)
	- [GemFactory.getGem(uint256)](src/L2/GemFactory.sol#L1108-L1111)
	- [GemFactory.isTokenLocked(uint256)](src/L2/GemFactory.sol#L1065-L1067)
	- [GemFactory.meltGEM(uint256)](src/L2/GemFactory.sol#L430-L438)
	- [GemFactory.setIsLocked(uint256,bool)](src/L2/GemFactory.sol#L824-L826)
	- [GemFactory.startMiningGEM(uint256)](src/L2/GemFactory.sol#L332-L354)
	- [GemFactory.totalSupply()](src/L2/GemFactory.sol#L1144-L1146)
	- [GemFactory.transferFrom(address,address,uint256)](src/L2/GemFactory.sol#L759-L775)
	- [Gems[_tokenId].gemCooldownPeriod = block.timestamp + getCooldownPeriod(Gems[_tokenId].rarity)](src/L2/GemFactory.sol#L420)
	[GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38) can be used in cross function reentrancies:
	- [GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38)
	- [GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940)
	- [GemFactory._transferGEM(address,address,uint256)](src/L2/GemFactory.sol#L942-L947)
	- [GemFactory.burnToken(address,uint256)](src/L2/GemFactory.sol#L440-L449)
	- [GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369)
	- [GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428)
	- [GemFactory.countGemsByQuadrant(uint8,uint8,uint8,uint8)](src/L2/GemFactory.sol#L1079-L1105)
	- [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593)
	- [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757)
	- [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325)
	- [GemFactory.fulfillRandomWords(uint256,uint256)](src/L2/GemFactory.sol#L950-L967)
	- [GemFactory.getGem(uint256)](src/L2/GemFactory.sol#L1108-L1111)
	- [GemFactory.isTokenLocked(uint256)](src/L2/GemFactory.sol#L1065-L1067)
	- [GemFactory.meltGEM(uint256)](src/L2/GemFactory.sol#L430-L438)
	- [GemFactory.setIsLocked(uint256,bool)](src/L2/GemFactory.sol#L824-L826)
	- [GemFactory.startMiningGEM(uint256)](src/L2/GemFactory.sol#L332-L354)
	- [GemFactory.totalSupply()](src/L2/GemFactory.sol#L1144-L1146)
	- [GemFactory.transferFrom(address,address,uint256)](src/L2/GemFactory.sol#L759-L775)

src/L2/GemFactory.sol#L396-L428


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-74
[GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._value](src/L2/GemFactory.sol#L474) is a local variable never initialized

src/L2/GemFactory.sol#L474


 - [ ] ID-75
[GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._miningTry](src/L2/GemFactory.sol#L475) is a local variable never initialized

src/L2/GemFactory.sol#L475


 - [ ] ID-76
[SeigManager._increaseTot().powertonSeig](src/L1/Mock/SeigManager.sol#L743) is a local variable never initialized

src/L1/Mock/SeigManager.sol#L743


 - [ ] ID-77
[GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._miningPeriod](src/L2/GemFactory.sol#L473) is a local variable never initialized

src/L2/GemFactory.sol#L473


 - [ ] ID-78
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2]).baseValue](src/L2/GemFactory.sol#L267) is a local variable never initialized

src/L2/GemFactory.sol#L267


 - [ ] ID-79
[GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._gemCooldownPeriod](src/L2/GemFactory.sol#L472) is a local variable never initialized

src/L2/GemFactory.sol#L472


 - [ ] ID-80
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2]).forgedGemsminingTry](src/L2/GemFactory.sol#L195) is a local variable never initialized

src/L2/GemFactory.sol#L195


 - [ ] ID-81
[SeigManager._increaseTot().relativeSeig](src/L1/Mock/SeigManager.sol#L745) is a local variable never initialized

src/L1/Mock/SeigManager.sol#L745


 - [ ] ID-82
[GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._gemCooldownPeriod](src/L2/GemFactory.sol#L622) is a local variable never initialized

src/L2/GemFactory.sol#L622


 - [ ] ID-83
[GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._miningPeriod](src/L2/GemFactory.sol#L623) is a local variable never initialized

src/L2/GemFactory.sol#L623


 - [ ] ID-84
[GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._miningTry](src/L2/GemFactory.sol#L625) is a local variable never initialized

src/L2/GemFactory.sol#L625


 - [ ] ID-85
[SeigManager._increaseTot().daoSeig](src/L1/Mock/SeigManager.sol#L744) is a local variable never initialized

src/L1/Mock/SeigManager.sol#L744


 - [ ] ID-86
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2]).forgedGemsCooldownPeriod](src/L2/GemFactory.sol#L194) is a local variable never initialized

src/L2/GemFactory.sol#L194


 - [ ] ID-87
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2]).forgedGemsValue](src/L2/GemFactory.sol#L192) is a local variable never initialized

src/L2/GemFactory.sol#L192


 - [ ] ID-88
[GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._value](src/L2/GemFactory.sol#L624) is a local variable never initialized

src/L2/GemFactory.sol#L624


 - [ ] ID-89
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2]).forgedGemsMiningPeriod](src/L2/GemFactory.sol#L193) is a local variable never initialized

src/L2/GemFactory.sol#L193


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-90
[SeigManager.updateSeigniorage()](src/L1/Mock/SeigManager.sol#L404-L477) ignores return value by [coinage.mint(operator,operatorSeigs)](src/L1/Mock/SeigManager.sol#L466)

src/L1/Mock/SeigManager.sol#L404-L477


 - [ ] ID-91
[SeigManager.updateSeigniorage()](src/L1/Mock/SeigManager.sol#L404-L477) ignores return value by [coinage.setFactor(_calcNewFactor(prevTotalSupply,nextTotalSupply,coinage.factor()))](src/L1/Mock/SeigManager.sol#L454-L460)

src/L1/Mock/SeigManager.sol#L404-L477


 - [ ] ID-92
[SeigManager._increaseTot()](src/L1/Mock/SeigManager.sol#L698-L766) ignores return value by [_tot.setFactor(_calcNewFactor(prevTotalSupply,nextTotalSupply,_tot.factor()))](src/L1/Mock/SeigManager.sol#L739)

src/L1/Mock/SeigManager.sol#L698-L766


 - [ ] ID-93
[SeigManager.onDeposit(address,address,uint256)](src/L1/Mock/SeigManager.sol#L355-L369) ignores return value by [_tot.mint(layer2,amount)](src/L1/Mock/SeigManager.sol#L365)

src/L1/Mock/SeigManager.sol#L355-L369


 - [ ] ID-94
[L1WrappedStakedTON._depositAndGetWSTONTo(address,uint256)](src/L1/L1WrappedStakedTON.sol#L74-L119) ignores return value by [IERC20(wton).approve(depositManager,_amount)](src/L1/L1WrappedStakedTON.sol#L97)

src/L1/L1WrappedStakedTON.sol#L74-L119


 - [ ] ID-95
[SeigManager._increaseTot()](src/L1/Mock/SeigManager.sol#L698-L766) ignores return value by [IWTON(_wton).mint(address(dao),daoSeig)](src/L1/Mock/SeigManager.sol#L755)

src/L1/Mock/SeigManager.sol#L698-L766


 - [ ] ID-96
[Treasury.approveGemFactory()](src/L2/Treasury.sol#L56-L59) ignores return value by [IERC20(wston).approve(gemFactory,type()(uint256).max)](src/L2/Treasury.sol#L58)

src/L2/Treasury.sol#L56-L59


 - [ ] ID-97
[SeigManager._increaseTot()](src/L1/Mock/SeigManager.sol#L698-L766) ignores return value by [IWTON(_wton).mint(address(_powerton),powertonSeig)](src/L1/Mock/SeigManager.sol#L749)

src/L1/Mock/SeigManager.sol#L698-L766


 - [ ] ID-98
[SeigManager.onDeposit(address,address,uint256)](src/L1/Mock/SeigManager.sol#L355-L369) ignores return value by [_coinages[layer2].mint(account,amount)](src/L1/Mock/SeigManager.sol#L366)

src/L1/Mock/SeigManager.sol#L355-L369


 - [ ] ID-99
[Treasury.approveMarketPlace()](src/L2/Treasury.sol#L61-L64) ignores return value by [IERC20(wston).approve(_marketplace,type()(uint256).max)](src/L2/Treasury.sol#L63)

src/L2/Treasury.sol#L61-L64


## shadowing-local
Impact: Low
Confidence: High
 - [ ] ID-100
[MockToken.constructor(string,string,uint8)._symbol](src/L1/Mock/MockToken.sol#L8) shadows:
	- [ERC20._symbol](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L42) (state variable)

src/L1/Mock/MockToken.sol#L8


 - [ ] ID-101
[L2StandardERC20.constructor(address,address,string,string)._name](src/L2/Mock/L2StandardERC20.sol#L20) shadows:
	- [ERC20._name](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L41) (state variable)

src/L2/Mock/L2StandardERC20.sol#L20


 - [ ] ID-102
[MockToken.constructor(string,string,uint8)._name](src/L1/Mock/MockToken.sol#L8) shadows:
	- [ERC20._name](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L41) (state variable)

src/L1/Mock/MockToken.sol#L8


 - [ ] ID-103
[GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._tokenURIs](src/L2/GemFactory.sol#L607) shadows:
	- [GemFactoryStorage._tokenURIs](src/L2/GemFactoryStorage.sol#L47) (state variable)
	- [ERC721URIStorage._tokenURIs](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L22) (state variable)

src/L2/GemFactory.sol#L607


 - [ ] ID-104
[RefactorCoinageSnapshotI.setFactor(uint256).factor](src/L1/Mock/interfaces/RefactorCoinageSnapshotI.sol#L7) shadows:
	- [RefactorCoinageSnapshotI.factor()](src/L1/Mock/interfaces/RefactorCoinageSnapshotI.sol#L6) (function)

src/L1/Mock/interfaces/RefactorCoinageSnapshotI.sol#L7


 - [ ] ID-105
[L2StandardERC20.constructor(address,address,string,string)._symbol](src/L2/Mock/L2StandardERC20.sol#L21) shadows:
	- [ERC20._symbol](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L42) (state variable)

src/L2/Mock/L2StandardERC20.sol#L21


 - [ ] ID-106
[L1WrappedStakedTON.constructor(address,address,address,address,string,string)._symbol](src/L1/L1WrappedStakedTON.sol#L38) shadows:
	- [ERC20._symbol](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L42) (state variable)

src/L1/L1WrappedStakedTON.sol#L38


 - [ ] ID-107
[MockTON.constructor(address,address,string,string)._symbol](src/L2/Mock/MockTON.sol#L21) shadows:
	- [ERC20._symbol](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L42) (state variable)

src/L2/Mock/MockTON.sol#L21


 - [ ] ID-108
[L1WrappedStakedTON.constructor(address,address,address,address,string,string)._name](src/L1/L1WrappedStakedTON.sol#L37) shadows:
	- [ERC20._name](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L41) (state variable)

src/L1/L1WrappedStakedTON.sol#L37


 - [ ] ID-109
[MockTON.constructor(address,address,string,string)._name](src/L2/Mock/MockTON.sol#L20) shadows:
	- [ERC20._name](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L41) (state variable)

src/L2/Mock/MockTON.sol#L20


 - [ ] ID-110
[AutoRefactorCoinageI.setFactor(uint256).factor](src/L1/Mock/interfaces/AutoRefactorCoinageI.sol#L6) shadows:
	- [AutoRefactorCoinageI.factor()](src/L1/Mock/interfaces/AutoRefactorCoinageI.sol#L5) (function)

src/L1/Mock/interfaces/AutoRefactorCoinageI.sol#L6


## events-access
Impact: Low
Confidence: Medium
 - [ ] ID-111
[Treasury.setMarketPlace(address)](src/L2/Treasury.sol#L51-L54) should emit an event for: 
	- [_marketplace = marketplace](src/L2/Treasury.sol#L53) 

src/L2/Treasury.sol#L51-L54


 - [ ] ID-112
[GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)](src/L2/GemFactory.sol#L83-L106) should emit an event for: 
	- [treasury = _treasury](src/L2/GemFactory.sol#L99) 

src/L2/GemFactory.sol#L83-L106


 - [ ] ID-113
[GemFactory.setMarketPlaceAddress(address)](src/L2/GemFactory.sol#L816-L818) should emit an event for: 
	- [marketplace = _marketplace](src/L2/GemFactory.sol#L817) 

src/L2/GemFactory.sol#L816-L818


 - [ ] ID-114
[Treasury.setGemFactory(address)](src/L2/Treasury.sol#L46-L49) should emit an event for: 
	- [gemFactory = _gemFactory](src/L2/Treasury.sol#L48) 

src/L2/Treasury.sol#L46-L49


## events-maths
Impact: Low
Confidence: Medium
 - [ ] ID-115
[GemFactory.setminingTrys(uint256,uint256,uint256,uint256,uint256,uint256)](src/L2/GemFactory.sol#L140-L154) should emit an event for: 
	- [CommonminingTry = _CommonminingTry](src/L2/GemFactory.sol#L148) 
	- [RareminingTry = _RareminingTry](src/L2/GemFactory.sol#L149) 
	- [UniqueminingTry = _UniqueminingTry](src/L2/GemFactory.sol#L150) 
	- [EpicminingTry = _EpicminingTry](src/L2/GemFactory.sol#L151) 
	- [LegendaryminingTry = _LegendaryminingTry](src/L2/GemFactory.sol#L152) 
	- [MythicminingTry = _MythicminingTry](src/L2/GemFactory.sol#L153) 

src/L2/GemFactory.sol#L140-L154


 - [ ] ID-116
[GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)](src/L2/GemFactory.sol#L83-L106) should emit an event for: 
	- [CommonGemsValue = _CommonGemsValue](src/L2/GemFactory.sol#L100) 
	- [RareGemsValue = _RareGemsValue](src/L2/GemFactory.sol#L101) 
	- [UniqueGemsValue = _UniqueGemsValue](src/L2/GemFactory.sol#L102) 
	- [EpicGemsValue = _EpicGemsValue](src/L2/GemFactory.sol#L103) 
	- [LegendaryGemsValue = _LegendaryGemsValue](src/L2/GemFactory.sol#L104) 
	- [MythicGemsValue = _MythicGemsValue](src/L2/GemFactory.sol#L105) 

src/L2/GemFactory.sol#L83-L106


 - [ ] ID-117
[GemFactory.setGemsCooldownPeriods(uint256,uint256,uint256,uint256,uint256,uint256)](src/L2/GemFactory.sol#L124-L138) should emit an event for: 
	- [CommonGemsCooldownPeriod = _CommonGemsCooldownPeriod](src/L2/GemFactory.sol#L132) 
	- [RareGemsCooldownPeriod = _RareGemsCooldownPeriod](src/L2/GemFactory.sol#L133) 
	- [UniqueGemsCooldownPeriod = _UniqueGemsCooldownPeriod](src/L2/GemFactory.sol#L134) 
	- [EpicGemsCooldownPeriod = _EpicGemsCooldownPeriod](src/L2/GemFactory.sol#L135) 
	- [LegendaryGemsCooldownPeriod = _LegendaryGemsCooldownPeriod](src/L2/GemFactory.sol#L136) 
	- [MythicGemsCooldownPeriod = _MythicGemsCooldownPeriod](src/L2/GemFactory.sol#L137) 

src/L2/GemFactory.sol#L124-L138


 - [ ] ID-118
[GemFactory.setGemsValue(uint256,uint256,uint256,uint256,uint256,uint256)](src/L2/GemFactory.sol#L156-L170) should emit an event for: 
	- [CommonGemsValue = _CommonGemsValue](src/L2/GemFactory.sol#L164) 
	- [RareGemsValue = _RareGemsValue](src/L2/GemFactory.sol#L165) 
	- [UniqueGemsValue = _UniqueGemsValue](src/L2/GemFactory.sol#L166) 
	- [EpicGemsValue = _EpicGemsValue](src/L2/GemFactory.sol#L167) 
	- [LegendaryGemsValue = _LegendaryGemsValue](src/L2/GemFactory.sol#L168) 
	- [MythicGemsValue = _MythicGemsValue](src/L2/GemFactory.sol#L169) 

src/L2/GemFactory.sol#L156-L170


 - [ ] ID-119
[MarketPlace.setStakingIndex(uint256)](src/L2/MarketPlace.sol#L94-L97) should emit an event for: 
	- [stakingIndex = _stakingIndex](src/L2/MarketPlace.sol#L96) 

src/L2/MarketPlace.sol#L94-L97


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-120
[Treasury.setGemFactory(address)._gemFactory](src/L2/Treasury.sol#L46) lacks a zero-check on :
		- [gemFactory = _gemFactory](src/L2/Treasury.sol#L48)

src/L2/Treasury.sol#L46


 - [ ] ID-121
[L2StandardERC20.constructor(address,address,string,string)._l1Token](src/L2/Mock/L2StandardERC20.sol#L19) lacks a zero-check on :
		- [l1Token = _l1Token](src/L2/Mock/L2StandardERC20.sol#L23)

src/L2/Mock/L2StandardERC20.sol#L19


 - [ ] ID-122
[DepositManager.initialize(address,address,address,uint256).wton_](src/L1/Mock/DepositManager.sol#L59) lacks a zero-check on :
		- [_wton = wton_](src/L1/Mock/DepositManager.sol#L66)

src/L1/Mock/DepositManager.sol#L59


 - [ ] ID-123
[SeigManager.initialize(address,address,address,address,uint256,address,uint256).wton_](src/L1/Mock/SeigManager.sol#L160) lacks a zero-check on :
		- [_wton = wton_](src/L1/Mock/SeigManager.sol#L170)

src/L1/Mock/SeigManager.sol#L160


 - [ ] ID-124
[DepositManager.initialize(address,address,address,uint256).registry_](src/L1/Mock/DepositManager.sol#L60) lacks a zero-check on :
		- [_registry = registry_](src/L1/Mock/DepositManager.sol#L67)

src/L1/Mock/DepositManager.sol#L60


 - [ ] ID-125
[SeigManager.setDao(address).daoAddress](src/L1/Mock/SeigManager.sol#L237) lacks a zero-check on :
		- [dao = daoAddress](src/L1/Mock/SeigManager.sol#L238)

src/L1/Mock/SeigManager.sol#L237


 - [ ] ID-126
[DepositManager.initialize(address,address,address,uint256).seigManager_](src/L1/Mock/DepositManager.sol#L61) lacks a zero-check on :
		- [_seigManager = seigManager_](src/L1/Mock/DepositManager.sol#L68)

src/L1/Mock/DepositManager.sol#L61


 - [ ] ID-127
[DepositManager.setSeigManager(address).seigManager_](src/L1/Mock/DepositManager.sol#L76) lacks a zero-check on :
		- [_seigManager = seigManager_](src/L1/Mock/DepositManager.sol#L77)

src/L1/Mock/DepositManager.sol#L76


 - [ ] ID-128
[L1WrappedStakedTON.constructor(address,address,address,address,string,string)._seigManager](src/L1/L1WrappedStakedTON.sol#L36) lacks a zero-check on :
		- [seigManager = _seigManager](src/L1/L1WrappedStakedTON.sol#L41)

src/L1/L1WrappedStakedTON.sol#L36


 - [ ] ID-129
[SeigManager.initialize(address,address,address,address,uint256,address,uint256).ton_](src/L1/Mock/SeigManager.sol#L159) lacks a zero-check on :
		- [_ton = ton_](src/L1/Mock/SeigManager.sol#L169)

src/L1/Mock/SeigManager.sol#L159


 - [ ] ID-130
[SeigManager.initialize(address,address,address,address,uint256,address,uint256).registry_](src/L1/Mock/SeigManager.sol#L161) lacks a zero-check on :
		- [_registry = registry_](src/L1/Mock/SeigManager.sol#L171)

src/L1/Mock/SeigManager.sol#L161


 - [ ] ID-131
[Treasury.constructor(address,address,address)._gemFactory](src/L2/Treasury.sol#L38) lacks a zero-check on :
		- [gemFactory = _gemFactory](src/L2/Treasury.sol#L40)

src/L2/Treasury.sol#L38


 - [ ] ID-132
[SeigManager.setPowerTON(address).powerton_](src/L1/Mock/SeigManager.sol#L233) lacks a zero-check on :
		- [_powerton = powerton_](src/L1/Mock/SeigManager.sol#L234)

src/L1/Mock/SeigManager.sol#L233


 - [ ] ID-133
[SeigManager.initialize(address,address,address,address,uint256,address,uint256).depositManager_](src/L1/Mock/SeigManager.sol#L162) lacks a zero-check on :
		- [_depositManager = depositManager_](src/L1/Mock/SeigManager.sol#L172)

src/L1/Mock/SeigManager.sol#L162


 - [ ] ID-134
[Treasury.constructor(address,address,address)._wston](src/L2/Treasury.sol#L38) lacks a zero-check on :
		- [wston = _wston](src/L2/Treasury.sol#L41)

src/L2/Treasury.sol#L38


 - [ ] ID-135
[L1WrappedStakedTON.constructor(address,address,address,address,string,string)._wton](src/L1/L1WrappedStakedTON.sol#L34) lacks a zero-check on :
		- [wton = _wton](src/L1/L1WrappedStakedTON.sol#L43)

src/L1/L1WrappedStakedTON.sol#L34


 - [ ] ID-136
[RefactorCoinageSnapshot.setSeigManager(address)._seigManager](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L78) lacks a zero-check on :
		- [seigManager = _seigManager](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L79)

src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L78


 - [ ] ID-137
[WstonSwapPool.constructor(address,address,uint256,address,uint256)._wston](src/L2/WstonSwapPool.sol#L40) lacks a zero-check on :
		- [wston = _wston](src/L2/WstonSwapPool.sol#L42)

src/L2/WstonSwapPool.sol#L40


 - [ ] ID-138
[CoinageFactory.setAutoCoinageLogic(address).newLogic](src/L1/Mock/CoinageFactory.sol#L27) lacks a zero-check on :
		- [autoCoinageLogic = newLogic](src/L1/Mock/CoinageFactory.sol#L28)

src/L1/Mock/CoinageFactory.sol#L27


 - [ ] ID-139
[GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._ton](src/L2/GemFactory.sol#L85) lacks a zero-check on :
		- [ton = _ton](src/L2/GemFactory.sol#L98)

src/L2/GemFactory.sol#L85


 - [ ] ID-140
[SeigManager.setData(address,address,uint256,uint256,uint256,uint256,uint256).daoAddress](src/L1/Mock/SeigManager.sol#L210) lacks a zero-check on :
		- [dao = daoAddress](src/L1/Mock/SeigManager.sol#L221)

src/L1/Mock/SeigManager.sol#L210


 - [ ] ID-141
[L1WrappedStakedTONFactory.constructor(address)._l1wton](src/L1/L1WrappedStakedTONFactory.sol#L13) lacks a zero-check on :
		- [l1wton = _l1wton](src/L1/L1WrappedStakedTONFactory.sol#L14)

src/L1/L1WrappedStakedTONFactory.sol#L13


 - [ ] ID-142
[WstonSwapPool.constructor(address,address,uint256,address,uint256)._ton](src/L2/WstonSwapPool.sol#L40) lacks a zero-check on :
		- [ton = _ton](src/L2/WstonSwapPool.sol#L41)

src/L2/WstonSwapPool.sol#L40


 - [ ] ID-143
[GemFactory.constructor(address).coordinator](src/L2/GemFactory.sol#L61) lacks a zero-check on :
		- [drbcoordinator = coordinator](src/L2/GemFactory.sol#L63)

src/L2/GemFactory.sol#L61


 - [ ] ID-144
[WstonSwapPool.constructor(address,address,uint256,address,uint256)._treasury](src/L2/WstonSwapPool.sol#L40) lacks a zero-check on :
		- [treasury = _treasury](src/L2/WstonSwapPool.sol#L43)

src/L2/WstonSwapPool.sol#L40


 - [ ] ID-145
[MarketPlace.initialize(address,address,uint256,address,address).treasury](src/L2/MarketPlace.sol#L37) lacks a zero-check on :
		- [_treasury = treasury](src/L2/MarketPlace.sol#L46)

src/L2/MarketPlace.sol#L37


 - [ ] ID-146
[MarketPlace.initialize(address,address,uint256,address,address)._ton](src/L2/MarketPlace.sol#L41) lacks a zero-check on :
		- [ton_ = _ton](src/L2/MarketPlace.sol#L48)

src/L2/MarketPlace.sol#L41


 - [ ] ID-147
[GemFactory.setMarketPlaceAddress(address)._marketplace](src/L2/GemFactory.sol#L816) lacks a zero-check on :
		- [marketplace = _marketplace](src/L2/GemFactory.sol#L817)

src/L2/GemFactory.sol#L816


 - [ ] ID-148
[MarketPlace.initialize(address,address,uint256,address,address)._wston](src/L2/MarketPlace.sol#L40) lacks a zero-check on :
		- [wston_ = _wston](src/L2/MarketPlace.sol#L47)

src/L2/MarketPlace.sol#L40


 - [ ] ID-149
[L1WrappedStakedTON.setSeigManagerAddress(address)._seigManager](src/L1/L1WrappedStakedTON.sol#L218) lacks a zero-check on :
		- [seigManager = _seigManager](src/L1/L1WrappedStakedTON.sol#L219)

src/L1/L1WrappedStakedTON.sol#L218


 - [ ] ID-150
[MarketPlace.initialize(address,address,uint256,address,address)._gemfactory](src/L2/MarketPlace.sol#L38) lacks a zero-check on :
		- [gemFactory = _gemfactory](src/L2/MarketPlace.sol#L45)

src/L2/MarketPlace.sol#L38


 - [ ] ID-151
[SeigManager.setCoinageFactory(address).factory_](src/L1/Mock/SeigManager.sol#L259) lacks a zero-check on :
		- [factory = factory_](src/L1/Mock/SeigManager.sol#L260)

src/L1/Mock/SeigManager.sol#L259


 - [ ] ID-152
[RefactorCoinageSnapshot.initialize(string,string,uint256,address).seigManager_](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L43) lacks a zero-check on :
		- [seigManager = seigManager_](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L51)

src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L43


 - [ ] ID-153
[GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._treasury](src/L2/GemFactory.sol#L86) lacks a zero-check on :
		- [treasury = _treasury](src/L2/GemFactory.sol#L99)

src/L2/GemFactory.sol#L86


 - [ ] ID-154
[SeigManager.setData(address,address,uint256,uint256,uint256,uint256,uint256).powerton_](src/L1/Mock/SeigManager.sol#L209) lacks a zero-check on :
		- [_powerton = powerton_](src/L1/Mock/SeigManager.sol#L220)

src/L1/Mock/SeigManager.sol#L209


 - [ ] ID-155
[L1WrappedStakedTON.constructor(address,address,address,address,string,string)._depositManager](src/L1/L1WrappedStakedTON.sol#L35) lacks a zero-check on :
		- [depositManager = _depositManager](src/L1/L1WrappedStakedTON.sol#L40)

src/L1/L1WrappedStakedTON.sol#L35


 - [ ] ID-156
[L1WrappedStakedTON.setDepositManagerAddress(address)._depositManager](src/L1/L1WrappedStakedTON.sol#L214) lacks a zero-check on :
		- [depositManager = _depositManager](src/L1/L1WrappedStakedTON.sol#L215)

src/L1/L1WrappedStakedTON.sol#L214


 - [ ] ID-157
[GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._wston](src/L2/GemFactory.sol#L84) lacks a zero-check on :
		- [wston = _wston](src/L2/GemFactory.sol#L97)

src/L2/GemFactory.sol#L84


 - [ ] ID-158
[MockTON.constructor(address,address,string,string)._l2Bridge](src/L2/Mock/MockTON.sol#L18) lacks a zero-check on :
		- [l2Bridge = _l2Bridge](src/L2/Mock/MockTON.sol#L24)

src/L2/Mock/MockTON.sol#L18


 - [ ] ID-159
[SeigManager.initialize(address,address,address,address,uint256,address,uint256).factory_](src/L1/Mock/SeigManager.sol#L164) lacks a zero-check on :
		- [factory = factory_](src/L1/Mock/SeigManager.sol#L175)

src/L1/Mock/SeigManager.sol#L164


 - [ ] ID-160
[MockTON.constructor(address,address,string,string)._l1Token](src/L2/Mock/MockTON.sol#L19) lacks a zero-check on :
		- [l1Token = _l1Token](src/L2/Mock/MockTON.sol#L23)

src/L2/Mock/MockTON.sol#L19


 - [ ] ID-161
[L1WrappedStakedTON.constructor(address,address,address,address,string,string)._layer2Address](src/L1/L1WrappedStakedTON.sol#L33) lacks a zero-check on :
		- [layer2Address = _layer2Address](src/L1/L1WrappedStakedTON.sol#L42)

src/L1/L1WrappedStakedTON.sol#L33


 - [ ] ID-162
[L2StandardERC20.constructor(address,address,string,string)._l2Bridge](src/L2/Mock/L2StandardERC20.sol#L18) lacks a zero-check on :
		- [l2Bridge = _l2Bridge](src/L2/Mock/L2StandardERC20.sol#L24)

src/L2/Mock/L2StandardERC20.sol#L18


 - [ ] ID-163
[Treasury.constructor(address,address,address)._ton](src/L2/Treasury.sol#L38) lacks a zero-check on :
		- [ton = _ton](src/L2/Treasury.sol#L42)

src/L2/Treasury.sol#L38


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-164
[Address.functionCallWithValue(address,bytes,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L83-L89) has external calls inside a loop: [(success,returndata) = target.call{value: value}(data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L87)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L83-L89


 - [ ] ID-165
[ERC721._checkOnERC721Received(address,address,uint256,bytes)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L465-L482) has external calls inside a loop: [retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L467-L480)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L465-L482


 - [ ] ID-166
[SeigManager.stakeOfAt(address,uint256)](src/L1/Mock/SeigManager.sol#L546-L553) has external calls inside a loop: [layer2 = IILayer2Registry(_registry).layer2ByIndex(i)](src/L1/Mock/SeigManager.sol#L550)

src/L1/Mock/SeigManager.sol#L546-L553


 - [ ] ID-167
[SeigManager.transferCoinageOwnership(address,address[])](src/L1/Mock/SeigManager.sol#L263-L270) has external calls inside a loop: [c.addMinter(newSeigManager)](src/L1/Mock/SeigManager.sol#L266)

src/L1/Mock/SeigManager.sol#L263-L270


 - [ ] ID-168
[SeigManager.transferCoinageOwnership(address,address[])](src/L1/Mock/SeigManager.sol#L263-L270) has external calls inside a loop: [c.transferOwnership(newSeigManager)](src/L1/Mock/SeigManager.sol#L268)

src/L1/Mock/SeigManager.sol#L263-L270


 - [ ] ID-169
[SeigManager.stakeOfAt(address,uint256)](src/L1/Mock/SeigManager.sol#L546-L553) has external calls inside a loop: [amount += _coinages[layer2].balanceOfAt(account,snapshotId)](src/L1/Mock/SeigManager.sol#L551)

src/L1/Mock/SeigManager.sol#L546-L553


 - [ ] ID-170
[MarketPlace._putGemForSale(uint256,uint256,address)](src/L2/MarketPlace.sol#L104-L119) has external calls inside a loop: [require(bool,string)(IGemFactory(gemFactory).ownerOf(_tokenId) == _seller,Not the owner of the GEM)](src/L2/MarketPlace.sol#L105)

src/L2/MarketPlace.sol#L104-L119


 - [ ] ID-171
[SeigManager.stakeOf(address)](src/L1/Mock/SeigManager.sol#L537-L544) has external calls inside a loop: [amount += _coinages[layer2].balanceOf(account)](src/L1/Mock/SeigManager.sol#L542)

src/L1/Mock/SeigManager.sol#L537-L544


 - [ ] ID-172
[MarketPlace._putGemForSale(uint256,uint256,address)](src/L2/MarketPlace.sol#L104-L119) has external calls inside a loop: [GemFactory(gemFactory).setIsLocked(_tokenId,true)](src/L2/MarketPlace.sol#L109)

src/L2/MarketPlace.sol#L104-L119


 - [ ] ID-173
[DepositManager._processRequest(address,bool)](src/L1/Mock/DepositManager.sol#L263-L292) has external calls inside a loop: [require(bool)(IWTON(_wton).swapToTONAndTransfer(msg.sender,amount))](src/L1/Mock/DepositManager.sol#L285)

src/L1/Mock/DepositManager.sol#L263-L292


 - [ ] ID-174
[SeigManager.transferCoinageOwnership(address,address[])](src/L1/Mock/SeigManager.sol#L263-L270) has external calls inside a loop: [c.renounceMinter()](src/L1/Mock/SeigManager.sol#L267)

src/L1/Mock/SeigManager.sol#L263-L270


 - [ ] ID-175
[MarketPlace._putGemForSale(uint256,uint256,address)](src/L2/MarketPlace.sol#L104-L119) has external calls inside a loop: [require(bool,string)(IGemFactory(gemFactory).isTokenLocked(_tokenId) == false,Gem is already for sale or mining)](src/L2/MarketPlace.sol#L107)

src/L2/MarketPlace.sol#L104-L119


 - [ ] ID-176
[DepositManager._deposit(address,address,uint256,address)](src/L1/Mock/DepositManager.sol#L137-L150) has external calls inside a loop: [require(bool)(ISeigManager(_seigManager).onDeposit(layer2,account,amount))](src/L1/Mock/DepositManager.sol#L147)

src/L1/Mock/DepositManager.sol#L137-L150


 - [ ] ID-177
[SeigManager.stakeOf(address)](src/L1/Mock/SeigManager.sol#L537-L544) has external calls inside a loop: [layer2 = IILayer2Registry(_registry).layer2ByIndex(i)](src/L1/Mock/SeigManager.sol#L541)

src/L1/Mock/SeigManager.sol#L537-L544


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-178
Reentrancy in [L1WrappedStakedTON._requestWithdrawal(address,uint256,uint256)](src/L1/L1WrappedStakedTON.sol#L131-L156):
	External calls:
	- [require(bool,string)(IDepositManager(depositManager).requestWithdrawal(layer2Address,_amountToWithdraw),failed to request withdrawal from the deposit manager)](src/L1/L1WrappedStakedTON.sol#L140-L143)
	State variables written after the call(s):
	- [_burn(_to,_wstonAmount)](src/L1/L1WrappedStakedTON.sol#L152)
		- [_totalSupply += value](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L191)
		- [_totalSupply -= value](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L206)
	- [withdrawalRequests[_to].push(WithdrawalRequest({withdrawableBlockNumber:block.number + delay,amount:_amountToWithdraw,processed:false}))](src/L1/L1WrappedStakedTON.sol#L145-L149)

src/L1/L1WrappedStakedTON.sol#L131-L156


 - [ ] ID-179
Reentrancy in [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593):
	External calls:
	- [_safeMint(msg.sender,newGemId)](src/L2/GemFactory.sol#L586)
		- [retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L467-L480)
	State variables written after the call(s):
	- [_setTokenURI(newGemId,_tokenURI)](src/L2/GemFactory.sol#L589)
		- [_tokenURIs[tokenId] = _tokenURI](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L58)

src/L2/GemFactory.sol#L465-L593


 - [ ] ID-180
Reentrancy in [SeigManager.deployCoinage(address)](src/L1/Mock/SeigManager.sol#L292-L303):
	External calls:
	- [c = CoinageFactoryI(factory).deploy()](src/L1/Mock/SeigManager.sol#L295)
	State variables written after the call(s):
	- [_lastCommitBlock[layer2] = block.number](src/L1/Mock/SeigManager.sol#L296)

src/L1/Mock/SeigManager.sol#L292-L303


 - [ ] ID-181
Reentrancy in [WstonSwapPool.swapTONforWSTON(uint256)](src/L2/WstonSwapPool.sol#L112-L132):
	External calls:
	- [_safeTransferFrom(IERC20(ton),msg.sender,address(this),tonAmount)](src/L2/WstonSwapPool.sol#L122)
		- [sent = token.transferFrom(sender,recipient,amount)](src/L2/WstonSwapPool.sol#L141)
	- [_safeTransfer(IERC20(wston),msg.sender,wstonAmountToTransfer)](src/L2/WstonSwapPool.sol#L123)
		- [sent = token.transfer(recipient,amount)](src/L2/WstonSwapPool.sol#L146)
	State variables written after the call(s):
	- [tonReserve += tonAmount](src/L2/WstonSwapPool.sol#L126)
	- [wstonReserve -= wstonAmount](src/L2/WstonSwapPool.sol#L127)

src/L2/WstonSwapPool.sol#L112-L132


 - [ ] ID-182
Reentrancy in [SeigManager.initialize(address,address,address,address,uint256,address,uint256)](src/L1/Mock/SeigManager.sol#L158-L182):
	External calls:
	- [c = CoinageFactoryI(factory).deploy()](src/L1/Mock/SeigManager.sol#L176)
	State variables written after the call(s):
	- [_tot = RefactorCoinageSnapshotI(c)](src/L1/Mock/SeigManager.sol#L178)

src/L1/Mock/SeigManager.sol#L158-L182


 - [ ] ID-183
Reentrancy in [WstonSwapPool.addLiquidity(uint256,uint256)](src/L2/WstonSwapPool.sol#L48-L69):
	External calls:
	- [_safeTransferFrom(IERC20(ton),msg.sender,address(this),tonAmount)](src/L2/WstonSwapPool.sol#L54)
		- [sent = token.transferFrom(sender,recipient,amount)](src/L2/WstonSwapPool.sol#L141)
	- [_safeTransferFrom(IERC20(wston),msg.sender,address(this),wstonAmount)](src/L2/WstonSwapPool.sol#L55)
		- [sent = token.transferFrom(sender,recipient,amount)](src/L2/WstonSwapPool.sol#L141)
	State variables written after the call(s):
	- [lpAddresses.push(msg.sender)](src/L2/WstonSwapPool.sol#L58)
	- [lpShares[msg.sender] += shares](src/L2/WstonSwapPool.sol#L62)
	- [tonReserve += tonAmount](src/L2/WstonSwapPool.sol#L65)
	- [totalShares += shares](src/L2/WstonSwapPool.sol#L63)
	- [wstonReserve += wstonAmount](src/L2/WstonSwapPool.sol#L66)

src/L2/WstonSwapPool.sol#L48-L69


 - [ ] ID-184
Reentrancy in [L1WrappedStakedTON._depositAndGetWSTONTo(address,uint256)](src/L1/L1WrappedStakedTON.sol#L74-L119):
	External calls:
	- [require(bool,string)(IERC20(wton).transferFrom(_to,address(this),_amount),failed to transfer wton to this contract)](src/L1/L1WrappedStakedTON.sol#L82-L85)
	- [require(bool,string)(ICandidate(layer2Address).updateSeigniorage(),failed to update seigniorage)](src/L1/L1WrappedStakedTON.sol#L89)
	State variables written after the call(s):
	- [stakingIndex = updateStakingIndex()](src/L1/L1WrappedStakedTON.sol#L94)
		- [stakingIndex = _stakingIndex](src/L1/L1WrappedStakedTON.sol#L203)

src/L1/L1WrappedStakedTON.sol#L74-L119


 - [ ] ID-185
Reentrancy in [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325):
	External calls:
	- [_safeMint(msg.sender,newGemId)](src/L2/GemFactory.sol#L318)
		- [retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L467-L480)
	State variables written after the call(s):
	- [_setTokenURI(newGemId,)](src/L2/GemFactory.sol#L321)
		- [_tokenURIs[tokenId] = _tokenURI](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L58)

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-186
Reentrancy in [GemFactory.pickMinedGEM(uint256)](src/L2/GemFactory.sol#L371-L394):
	External calls:
	- [requestId = requestRandomness(0,0,CALLBACK_GAS_LIMIT)](src/L2/GemFactory.sol#L378)
		- [requestId = i_drbCoordinator.requestRandomWordDirectFunding{value: msg.value}(IDRBCoordinator.RandomWordsRequest({security:security,mode:mode,callbackGasLimit:callbackGasLimit}))](src/L2/Randomness/DRBConsumerBase.sol#L34-L42)
	State variables written after the call(s):
	- [requestCount ++](src/L2/GemFactory.sol#L386)
	- [s_requests[requestId].tokenId = _tokenId](src/L2/GemFactory.sol#L382)
	- [s_requests[requestId].requested = true](src/L2/GemFactory.sol#L383)
	- [s_requests[requestId].requester = msg.sender](src/L2/GemFactory.sol#L384)

src/L2/GemFactory.sol#L371-L394


 - [ ] ID-187
Reentrancy in [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757):
	External calls:
	- [_safeMint(msg.sender,newGemId)](src/L2/GemFactory.sol#L749)
		- [retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L467-L480)
	State variables written after the call(s):
	- [GEMIndexToOwner[newGemId] = msg.sender](src/L2/GemFactory.sol#L745)
	- [_setTokenURI(newGemId,_tokenURIs[i])](src/L2/GemFactory.sol#L750)
		- [_tokenURIs[tokenId] = _tokenURI](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L58)

src/L2/GemFactory.sol#L603-L757


 - [ ] ID-188
Reentrancy in [MarketPlace._putGemForSale(uint256,uint256,address)](src/L2/MarketPlace.sol#L104-L119):
	External calls:
	- [GemFactory(gemFactory).setIsLocked(_tokenId,true)](src/L2/MarketPlace.sol#L109)
	State variables written after the call(s):
	- [gemsForSale[_tokenId] = Sale({seller:_seller,price:_price,isActive:true})](src/L2/MarketPlace.sol#L111-L115)

src/L2/MarketPlace.sol#L104-L119


 - [ ] ID-189
Reentrancy in [SeigManager._increaseTot()](src/L1/Mock/SeigManager.sol#L698-L766):
	External calls:
	- [_tot.setFactor(_calcNewFactor(prevTotalSupply,nextTotalSupply,_tot.factor()))](src/L1/Mock/SeigManager.sol#L739)
	- [IWTON(_wton).mint(address(_powerton),powertonSeig)](src/L1/Mock/SeigManager.sol#L749)
	- [IPowerTON(_powerton).updateSeigniorage(powertonSeig)](src/L1/Mock/SeigManager.sol#L750)
	- [IWTON(_wton).mint(address(dao),daoSeig)](src/L1/Mock/SeigManager.sol#L755)
	State variables written after the call(s):
	- [accRelativeSeig = accRelativeSeig + relativeSeig](src/L1/Mock/SeigManager.sol#L760)

src/L1/Mock/SeigManager.sol#L698-L766


 - [ ] ID-190
Reentrancy in [WstonSwapPool.swapWSTONforTON(uint256)](src/L2/WstonSwapPool.sol#L90-L110):
	External calls:
	- [_safeTransferFrom(IERC20(wston),msg.sender,address(this),wstonAmount)](src/L2/WstonSwapPool.sol#L100)
		- [sent = token.transferFrom(sender,recipient,amount)](src/L2/WstonSwapPool.sol#L141)
	- [_safeTransfer(IERC20(ton),msg.sender,tonAmountToTransfer)](src/L2/WstonSwapPool.sol#L101)
		- [sent = token.transfer(recipient,amount)](src/L2/WstonSwapPool.sol#L146)
	State variables written after the call(s):
	- [tonReserve -= tonAmount](src/L2/WstonSwapPool.sol#L105)
	- [wstonReserve += wstonAmount](src/L2/WstonSwapPool.sol#L104)

src/L2/WstonSwapPool.sol#L90-L110


 - [ ] ID-191
Reentrancy in [L1WrappedStakedTON._depositAndGetWSTONTo(address,uint256)](src/L1/L1WrappedStakedTON.sol#L74-L119):
	External calls:
	- [require(bool,string)(IERC20(wton).transferFrom(_to,address(this),_amount),failed to transfer wton to this contract)](src/L1/L1WrappedStakedTON.sol#L82-L85)
	- [require(bool,string)(ICandidate(layer2Address).updateSeigniorage(),failed to update seigniorage)](src/L1/L1WrappedStakedTON.sol#L89)
	- [IERC20(wton).approve(depositManager,_amount)](src/L1/L1WrappedStakedTON.sol#L97)
	- [require(bool,string)(IDepositManager(depositManager).deposit(layer2Address,_amount),failed to stake)](src/L1/L1WrappedStakedTON.sol#L100-L106)
	State variables written after the call(s):
	- [_mint(_to,wstonAmount)](src/L1/L1WrappedStakedTON.sol#L113)
		- [_balances[from] = fromBalance - value](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L199)
		- [_balances[to] += value](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L211)
	- [_mint(_to,wstonAmount)](src/L1/L1WrappedStakedTON.sol#L113)
		- [_totalSupply += value](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L191)
		- [_totalSupply -= value](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L206)
	- [totalStakedAmount += _amount](src/L1/L1WrappedStakedTON.sol#L110)

src/L1/L1WrappedStakedTON.sol#L74-L119


 - [ ] ID-192
Reentrancy in [SeigManager.updateSeigniorage()](src/L1/Mock/SeigManager.sol#L404-L477):
	External calls:
	- [_increaseTot()](src/L1/Mock/SeigManager.sol#L420)
		- [_tot.setFactor(_calcNewFactor(prevTotalSupply,nextTotalSupply,_tot.factor()))](src/L1/Mock/SeigManager.sol#L739)
		- [IWTON(_wton).mint(address(_powerton),powertonSeig)](src/L1/Mock/SeigManager.sol#L749)
		- [IPowerTON(_powerton).updateSeigniorage(powertonSeig)](src/L1/Mock/SeigManager.sol#L750)
		- [IWTON(_wton).mint(address(dao),daoSeig)](src/L1/Mock/SeigManager.sol#L755)
	State variables written after the call(s):
	- [(nextTotalSupply,operatorSeigs) = _calcSeigsDistribution(msg.sender,coinage,prevTotalSupply,seigs,isCommissionRateNegative_,operator)](src/L1/Mock/SeigManager.sol#L443-L450)
		- [_commissionRates[layer2] = delayedCommissionRate[layer2]](src/L1/Mock/SeigManager.sol#L620)
	- [(nextTotalSupply,operatorSeigs) = _calcSeigsDistribution(msg.sender,coinage,prevTotalSupply,seigs,isCommissionRateNegative_,operator)](src/L1/Mock/SeigManager.sol#L443-L450)
		- [_isCommissionRateNegative[layer2] = delayedCommissionRateNegative[layer2]](src/L1/Mock/SeigManager.sol#L621)
	- [_lastCommitBlock[msg.sender] = block.number](src/L1/Mock/SeigManager.sol#L422)
	- [(nextTotalSupply,operatorSeigs) = _calcSeigsDistribution(msg.sender,coinage,prevTotalSupply,seigs,isCommissionRateNegative_,operator)](src/L1/Mock/SeigManager.sol#L443-L450)
		- [delayedCommissionBlock[layer2] = 0](src/L1/Mock/SeigManager.sol#L622)

src/L1/Mock/SeigManager.sol#L404-L477


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-193
Reentrancy in [SeigManager._increaseTot()](src/L1/Mock/SeigManager.sol#L698-L766):
	External calls:
	- [_tot.setFactor(_calcNewFactor(prevTotalSupply,nextTotalSupply,_tot.factor()))](src/L1/Mock/SeigManager.sol#L739)
	- [IWTON(_wton).mint(address(_powerton),powertonSeig)](src/L1/Mock/SeigManager.sol#L749)
	- [IPowerTON(_powerton).updateSeigniorage(powertonSeig)](src/L1/Mock/SeigManager.sol#L750)
	- [IWTON(_wton).mint(address(dao),daoSeig)](src/L1/Mock/SeigManager.sol#L755)
	Event emitted after the call(s):
	- [SeigGiven(msg.sender,maxSeig,stakedSeig,unstakedSeig,powertonSeig,daoSeig,relativeSeig)](src/L1/Mock/SeigManager.sol#L763)

src/L1/Mock/SeigManager.sol#L698-L766


 - [ ] ID-194
Reentrancy in [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757):
	External calls:
	- [_safeMint(msg.sender,newGemId)](src/L2/GemFactory.sol#L749)
		- [retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L467-L480)
	Event emitted after the call(s):
	- [Created(newGemId,_rarities[i],_colors[i],_value,_quadrants[i],_miningPeriod,_gemCooldownPeriod,_tokenURIs[i],msg.sender)](src/L2/GemFactory.sol#L752)
	- [MetadataUpdate(tokenId)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L59)
		- [_setTokenURI(newGemId,_tokenURIs[i])](src/L2/GemFactory.sol#L750)

src/L2/GemFactory.sol#L603-L757


 - [ ] ID-195
Reentrancy in [L1WrappedStakedTON._requestWithdrawal(address,uint256,uint256)](src/L1/L1WrappedStakedTON.sol#L131-L156):
	External calls:
	- [require(bool,string)(IDepositManager(depositManager).requestWithdrawal(layer2Address,_amountToWithdraw),failed to request withdrawal from the deposit manager)](src/L1/L1WrappedStakedTON.sol#L140-L143)
	Event emitted after the call(s):
	- [Transfer(from,to,value)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L215)
		- [_burn(_to,_wstonAmount)](src/L1/L1WrappedStakedTON.sol#L152)
	- [WithdrawalRequested(_to,_wstonAmount)](src/L1/L1WrappedStakedTON.sol#L154)

src/L1/L1WrappedStakedTON.sol#L131-L156


 - [ ] ID-196
Reentrancy in [GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428):
	External calls:
	- [require(bool,string)(ITreasury(treasury).transferTreasuryGEMto(msg.sender,s_requests[requestId].chosenTokenId),failed to transfer token)](src/L2/GemFactory.sol#L417)
	Event emitted after the call(s):
	- [GemMiningClaimed(_tokenId,msg.sender)](src/L2/GemFactory.sol#L422)

src/L2/GemFactory.sol#L396-L428


 - [ ] ID-197
Reentrancy in [DepositManager._deposit(address,address,uint256,address)](src/L1/Mock/DepositManager.sol#L137-L150):
	External calls:
	- [IERC20(_wton).safeTransferFrom(payer,address(this),amount)](src/L1/Mock/DepositManager.sol#L143)
	Event emitted after the call(s):
	- [Deposited(layer2,account,amount)](src/L1/Mock/DepositManager.sol#L145)

src/L1/Mock/DepositManager.sol#L137-L150


 - [ ] ID-198
Reentrancy in [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593):
	External calls:
	- [_safeMint(msg.sender,newGemId)](src/L2/GemFactory.sol#L586)
		- [retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L467-L480)
	Event emitted after the call(s):
	- [Created(newGemId,_rarity,_color,_value,_quadrants,_miningPeriod,_gemCooldownPeriod,_tokenURI,msg.sender)](src/L2/GemFactory.sol#L591)
	- [MetadataUpdate(tokenId)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L59)
		- [_setTokenURI(newGemId,_tokenURI)](src/L2/GemFactory.sol#L589)

src/L2/GemFactory.sol#L465-L593


 - [ ] ID-199
Reentrancy in [SeigManager.onWithdraw(address,address,uint256)](src/L1/Mock/SeigManager.sol#L371-L394):
	External calls:
	- [_tot.burnFrom(layer2,amount + totAmount)](src/L1/Mock/SeigManager.sol#L386)
	- [_coinages[layer2].burnFrom(account,amount)](src/L1/Mock/SeigManager.sol#L389)
	Event emitted after the call(s):
	- [UnstakeLog(amount,totAmount)](src/L1/Mock/SeigManager.sol#L391)

src/L1/Mock/SeigManager.sol#L371-L394


 - [ ] ID-200
Reentrancy in [SeigManager.updateSeigniorage()](src/L1/Mock/SeigManager.sol#L404-L477):
	External calls:
	- [_increaseTot()](src/L1/Mock/SeigManager.sol#L420)
		- [_tot.setFactor(_calcNewFactor(prevTotalSupply,nextTotalSupply,_tot.factor()))](src/L1/Mock/SeigManager.sol#L739)
		- [IWTON(_wton).mint(address(_powerton),powertonSeig)](src/L1/Mock/SeigManager.sol#L749)
		- [IPowerTON(_powerton).updateSeigniorage(powertonSeig)](src/L1/Mock/SeigManager.sol#L750)
		- [IWTON(_wton).mint(address(dao),daoSeig)](src/L1/Mock/SeigManager.sol#L755)
	Event emitted after the call(s):
	- [Comitted(msg.sender)](src/L1/Mock/SeigManager.sol#L431)

src/L1/Mock/SeigManager.sol#L404-L477


 - [ ] ID-201
Reentrancy in [SeigManager.updateSeigniorage()](src/L1/Mock/SeigManager.sol#L404-L477):
	External calls:
	- [_increaseTot()](src/L1/Mock/SeigManager.sol#L420)
		- [_tot.setFactor(_calcNewFactor(prevTotalSupply,nextTotalSupply,_tot.factor()))](src/L1/Mock/SeigManager.sol#L739)
		- [IWTON(_wton).mint(address(_powerton),powertonSeig)](src/L1/Mock/SeigManager.sol#L749)
		- [IPowerTON(_powerton).updateSeigniorage(powertonSeig)](src/L1/Mock/SeigManager.sol#L750)
		- [IWTON(_wton).mint(address(dao),daoSeig)](src/L1/Mock/SeigManager.sol#L755)
	- [coinage.setFactor(_calcNewFactor(prevTotalSupply,nextTotalSupply,coinage.factor()))](src/L1/Mock/SeigManager.sol#L454-L460)
	- [coinage.burnFrom(operator,operatorSeigs)](src/L1/Mock/SeigManager.sol#L464)
	- [coinage.mint(operator,operatorSeigs)](src/L1/Mock/SeigManager.sol#L466)
	- [MockToken(_wton).mint(address(_depositManager),seigs)](src/L1/Mock/SeigManager.sol#L470)
	Event emitted after the call(s):
	- [AddedSeigAtLayer(msg.sender,seigs,operatorSeigs,nextTotalSupply,prevTotalSupply)](src/L1/Mock/SeigManager.sol#L474)
	- [Comitted(msg.sender)](src/L1/Mock/SeigManager.sol#L473)
	- [Transferred(address(_depositManager),seigs)](src/L1/Mock/SeigManager.sol#L471)

src/L1/Mock/SeigManager.sol#L404-L477


 - [ ] ID-202
Reentrancy in [SeigManager.deployCoinage(address)](src/L1/Mock/SeigManager.sol#L292-L303):
	External calls:
	- [c = CoinageFactoryI(factory).deploy()](src/L1/Mock/SeigManager.sol#L295)
	Event emitted after the call(s):
	- [CoinageCreated(layer2,c)](src/L1/Mock/SeigManager.sol#L299)

src/L1/Mock/SeigManager.sol#L292-L303


 - [ ] ID-203
Reentrancy in [L1WrappedStakedTON._claimWithdrawal(address)](src/L1/L1WrappedStakedTON.sol#L166-L185):
	External calls:
	- [require(bool)(IDepositManager(depositManager).processRequest(layer2Address,false))](src/L1/L1WrappedStakedTON.sol#L179)
	- [IERC20(wton).safeTransfer(_to,amount)](src/L1/L1WrappedStakedTON.sol#L181)
	Event emitted after the call(s):
	- [WithdrawalProcessed(_to,amount)](src/L1/L1WrappedStakedTON.sol#L183)

src/L1/L1WrappedStakedTON.sol#L166-L185


 - [ ] ID-204
Reentrancy in [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325):
	External calls:
	- [_safeMint(msg.sender,newGemId)](src/L2/GemFactory.sol#L318)
		- [retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L467-L480)
	Event emitted after the call(s):
	- [GemForged(msg.sender,_tokenIds,newGemId,newRarity,forgedQuadrants,_color,forgedGemsValue)](src/L2/GemFactory.sol#L323)
	- [MetadataUpdate(tokenId)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L59)
		- [_setTokenURI(newGemId,)](src/L2/GemFactory.sol#L321)

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-205
Reentrancy in [GemFactory.meltGEM(uint256)](src/L2/GemFactory.sol#L430-L438):
	External calls:
	- [require(bool,string)(ITreasury(treasury).transferWSTON(msg.sender,amount),transfer failed)](src/L2/GemFactory.sol#L435)
	Event emitted after the call(s):
	- [GemMelted(_tokenId,msg.sender)](src/L2/GemFactory.sol#L437)

src/L2/GemFactory.sol#L430-L438


 - [ ] ID-206
Reentrancy in [DepositManager._processRequest(address,bool)](src/L1/Mock/DepositManager.sol#L263-L292):
	External calls:
	- [require(bool)(IWTON(_wton).swapToTONAndTransfer(msg.sender,amount))](src/L1/Mock/DepositManager.sol#L285)
	- [IERC20(_wton).safeTransfer(msg.sender,amount)](src/L1/Mock/DepositManager.sol#L287)
	Event emitted after the call(s):
	- [WithdrawalProcessed(layer2,msg.sender,amount)](src/L1/Mock/DepositManager.sol#L290)

src/L1/Mock/DepositManager.sol#L263-L292


 - [ ] ID-207
Reentrancy in [MarketPlace._putGemForSale(uint256,uint256,address)](src/L2/MarketPlace.sol#L104-L119):
	External calls:
	- [GemFactory(gemFactory).setIsLocked(_tokenId,true)](src/L2/MarketPlace.sol#L109)
	Event emitted after the call(s):
	- [GemForSale(_tokenId,_seller,_price)](src/L2/MarketPlace.sol#L117)

src/L2/MarketPlace.sol#L104-L119


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-208
[GemFactory.fulfillRandomWords(uint256,uint256)](src/L2/GemFactory.sol#L950-L967) uses timestamp for comparisons
	Dangerous comparisons:
	- [gemCount > 0](src/L2/GemFactory.sol#L960)

src/L2/GemFactory.sol#L950-L967


 - [ ] ID-209
[GemFactory.startMiningGEM(uint256)](src/L2/GemFactory.sol#L332-L354) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(Gems[_tokenId].gemCooldownPeriod <= block.timestamp,Gem cooldown period has not elapsed)](src/L2/GemFactory.sol#L338)
	- [require(bool,string)(! Gems[_tokenId].isLocked,Gem is listed for sale or already mining)](src/L2/GemFactory.sol#L340)
	- [require(bool,string)(Gems[_tokenId].rarity != Rarity.COMMON,rarity must be at least RARE)](src/L2/GemFactory.sol#L342)
	- [require(bool,string)(Gems[_tokenId].miningTry != 0,no mining power left for that GEM)](src/L2/GemFactory.sol#L344)

src/L2/GemFactory.sol#L332-L354


 - [ ] ID-210
[GemFactory._checkColor(uint256,uint256,uint8,uint8)](src/L2/GemFactory.sol#L859-L940) uses timestamp for comparisons
	Dangerous comparisons:
	- [_color1_0 == _color1_1 && _color2_0 == _color2_1 && _color1_0 == _color2_0](src/L2/GemFactory.sol#L870)
	- [colorValidated = (_color_0 == _color1_0 && _color_1 == _color1_1)](src/L2/GemFactory.sol#L871)
	- [_color1_0 == _color1_1 && _color2_0 == _color2_1](src/L2/GemFactory.sol#L875)
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_0))](src/L2/GemFactory.sol#L876)
	- [((_color1_0 != _color1_1 && _color2_0 == _color2_1) && (_color1_0 == _color2_0 || _color1_1 == _color2_0)) || ((_color1_0 == _color1_1 && _color2_0 != _color2_1) && (_color2_0 == _color1_0 || _color2_1 == _color1_0))](src/L2/GemFactory.sol#L881)
	- [_color1_0 != _color1_1](src/L2/GemFactory.sol#L882)
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color1_1) || (_color_1 == _color1_0 && _color_0 == _color1_1))](src/L2/GemFactory.sol#L883)
	- [colorValidated = ((_color_0 == _color2_0 && _color_1 == _color2_1) || (_color_1 == _color2_0 && _color_0 == _color2_1))](src/L2/GemFactory.sol#L886)
	- [((_color1_0 != _color1_1 && _color2_0 == _color2_1) && (_color1_0 != _color2_0 && _color1_1 != _color2_0)) || ((_color1_0 == _color1_1 && _color2_0 != _color2_1) && (_color1_0 != _color2_0 && _color1_0 != _color2_1))](src/L2/GemFactory.sol#L891)
	- [_color1_0 != _color1_1](src/L2/GemFactory.sol#L892)
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_1 == _color1_0 && _color_0 == _color2_0) || (_color_1 == _color1_1 && _color_0 == _color2_0))](src/L2/GemFactory.sol#L893-L896)
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_1 == _color1_0 && _color_0 == _color2_0) || (_color_1 == _color1_0 && _color_0 == _color2_1))](src/L2/GemFactory.sol#L899-L902)
	- [_color1_0 != _color1_1 && _color2_0 != _color2_1 && ((_color1_0 == _color2_0 && _color1_1 == _color2_1) || (_color1_0 == _color2_1 && _color1_1 == _color2_0))](src/L2/GemFactory.sol#L908)
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color1_1) || (_color_0 == _color1_1 && _color_1 == _color1_0))](src/L2/GemFactory.sol#L909)
	- [_color1_0 != _color1_1 && _color2_0 != _color2_1 && (_color1_0 == _color2_0 || _color1_0 == _color2_1 || _color1_1 == _color2_0 || _color1_1 == _color2_1)](src/L2/GemFactory.sol#L913)
	- [_color1_0 == _color2_0](src/L2/GemFactory.sol#L914)
	- [colorValidated = ((_color_0 == _color1_1 && _color_1 == _color2_1) || (_color_0 == _color2_1 && _color_1 == _color1_1))](src/L2/GemFactory.sol#L915)
	- [_color1_0 == _color2_1](src/L2/GemFactory.sol#L917)
	- [colorValidated = ((_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_1))](src/L2/GemFactory.sol#L918)
	- [(_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_1)](src/L2/GemFactory.sol#L919)
	- [_color1_1 == _color2_0](src/L2/GemFactory.sol#L920)
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_0 == _color2_1 && _color_1 == _color1_0))](src/L2/GemFactory.sol#L921)
	- [_color1_1 == _color2_1](src/L2/GemFactory.sol#L923)
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_0))](src/L2/GemFactory.sol#L924)
	- [_color1_0 != _color1_1 && _color2_0 != _color2_1 && _color1_0 != _color2_0 && _color1_1 != _color2_0 && _color1_0 != _color2_1 && _color1_1 != _color2_1](src/L2/GemFactory.sol#L929)
	- [colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color1_1 && _color_1 == _color2_1) || (_color_0 == _color2_0 && _color_1 == _color1_0) || (_color_0 == _color2_0 && _color_1 == _color1_1) || (_color_0 == _color2_1 && _color_1 == _color1_0) || (_color_0 == _color2_1 && _color_1 == _color1_1))](src/L2/GemFactory.sol#L930-L933)

src/L2/GemFactory.sol#L859-L940


 - [ ] ID-211
[GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(Gems[_tokenId].isLocked == true,Gems is not mining)](src/L2/GemFactory.sol#L402)

src/L2/GemFactory.sol#L396-L428


 - [ ] ID-212
[GemFactory.tokensOfOwner(address)](src/L2/GemFactory.sol#L1118-L1142) uses timestamp for comparisons
	Dangerous comparisons:
	- [gemId <= totalGems](src/L2/GemFactory.sol#L1133)

src/L2/GemFactory.sol#L1118-L1142


 - [ ] ID-213
[DRBCoordinatorMock.fulfillRandomness(uint256)](src/L2/Mock/DRBCoordinatorMock.sol#L76-L114) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(s_valuesAtRound[requestId].requestedTime > 0,No request found)](src/L2/Mock/DRBCoordinatorMock.sol#L78)
	- [require(bool,string)(! s_randomWordsFullfill[requestId].isFullfilled,Already fulfilled)](src/L2/Mock/DRBCoordinatorMock.sol#L81)

src/L2/Mock/DRBCoordinatorMock.sol#L76-L114


 - [ ] ID-214
[GemFactory.transferFrom(address,address,uint256)](src/L2/GemFactory.sol#L759-L775) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(! Gems[tokenId].isLocked,Gem is locked)](src/L2/GemFactory.sol#L763)

src/L2/GemFactory.sol#L759-L775


 - [ ] ID-215
[GemFactory.getGem(uint256)](src/L2/GemFactory.sol#L1108-L1111) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(_tokenId < Gems.length,Gem does not exist)](src/L2/GemFactory.sol#L1109)

src/L2/GemFactory.sol#L1108-L1111


 - [ ] ID-216
[GemFactory.getCooldownPeriod(GemFactoryStorage.Rarity)](src/L2/GemFactory.sol#L982-L990) uses timestamp for comparisons
	Dangerous comparisons:
	- [rarity == Rarity.COMMON](src/L2/GemFactory.sol#L983)
	- [rarity == Rarity.RARE](src/L2/GemFactory.sol#L984)
	- [rarity == Rarity.UNIQUE](src/L2/GemFactory.sol#L985)
	- [rarity == Rarity.EPIC](src/L2/GemFactory.sol#L986)
	- [rarity == Rarity.LEGENDARY](src/L2/GemFactory.sol#L987)
	- [rarity == Rarity.MYTHIC](src/L2/GemFactory.sol#L988)

src/L2/GemFactory.sol#L982-L990


 - [ ] ID-217
[GemFactory.countGemsByQuadrant(uint8,uint8,uint8,uint8)](src/L2/GemFactory.sol#L1079-L1105) uses timestamp for comparisons
	Dangerous comparisons:
	- [i < Gems.length](src/L2/GemFactory.sol#L1085)
	- [GemSumOfQuadrants < sumOfQuadrants && GEMIndexToOwner[i] == treasury && ! Gems[i].isLocked](src/L2/GemFactory.sol#L1087-L1089)

src/L2/GemFactory.sol#L1079-L1105


 - [ ] ID-218
[GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(Gems[_tokenId].isLocked == true,Gems is not mining)](src/L2/GemFactory.sol#L360)

src/L2/GemFactory.sol#L356-L369


 - [ ] ID-219
[GemFactory.pickMinedGEM(uint256)](src/L2/GemFactory.sol#L371-L394) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp > userMiningStartTime[msg.sender][_tokenId] + Gems[_tokenId].miningPeriod,mining period has not elapsed)](src/L2/GemFactory.sol#L373)
	- [require(bool,string)(Gems[_tokenId].isLocked == true,Gems is not mining)](src/L2/GemFactory.sol#L374)

src/L2/GemFactory.sol#L371-L394


 - [ ] ID-220
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(Gems[_tokenIds[i]].rarity == _rarity,wrong rarity Gems)](src/L2/GemFactory.sol#L240)
	- [require(bool,string)(colorValidated,this color can't be obtained)](src/L2/GemFactory.sol#L257)
	- [forgedQuadrants[0] == baseValue + 1 && forgedQuadrants[1] == baseValue + 1 && forgedQuadrants[2] == baseValue + 1 && forgedQuadrants[3] == baseValue + 1](src/L2/GemFactory.sol#L280-L283)
	- [require(bool)(newGemId == uint256(uint32(newGemId)))](src/L2/GemFactory.sol#L313)

src/L2/GemFactory.sol#L184-L325


 - [ ] ID-221
[GemFactory._setTokenURI(uint256,string)](src/L2/GemFactory.sol#L969-L972) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(msg.sender == ownerOf(tokenId) || isAdmin(msg.sender) == true,not allowed to set token URI)](src/L2/GemFactory.sol#L970)

src/L2/GemFactory.sol#L969-L972


 - [ ] ID-222
[GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])](src/L2/GemFactory.sol#L603-L757) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool)(newGemId == uint256(uint32(newGemId)))](src/L2/GemFactory.sol#L743)

src/L2/GemFactory.sol#L603-L757


 - [ ] ID-223
[GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)](src/L2/GemFactory.sol#L465-L593) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool)(newGemId == uint256(uint32(newGemId)))](src/L2/GemFactory.sol#L581)

src/L2/GemFactory.sol#L465-L593


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-224
[StorageSlot.tstore(StorageSlot.Bytes32SlotType,bytes32)](src/L2/Mock/StorageSlot.sol#L302-L307) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L304-L306)

src/L2/Mock/StorageSlot.sol#L302-L307


 - [ ] ID-225
[StorageSlot.getBooleanSlot(bytes32)](src/L2/Mock/StorageSlot.sol#L96-L103) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L100-L102)

src/L2/Mock/StorageSlot.sol#L96-L103


 - [ ] ID-226
[StorageSlot.tstore(StorageSlot.Uint256SlotType,uint256)](src/L2/Mock/StorageSlot.sol#L322-L327) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L324-L326)

src/L2/Mock/StorageSlot.sol#L322-L327


 - [ ] ID-227
[StorageSlot.getInt256Slot(bytes32)](src/L2/Mock/StorageSlot.sol#L132-L139) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L136-L138)

src/L2/Mock/StorageSlot.sol#L132-L139


 - [ ] ID-228
[StorageSlot.tload(StorageSlot.BooleanSlotType)](src/L2/Mock/StorageSlot.sol#L272-L277) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L274-L276)

src/L2/Mock/StorageSlot.sol#L272-L277


 - [ ] ID-229
[ProxyCoinage._fallback()](src/L1/Mock/proxy/ProxyCoinage.sol#L139-L169) uses assembly
	- [INLINE ASM](src/L1/Mock/proxy/ProxyCoinage.sol#L147-L168)

src/L1/Mock/proxy/ProxyCoinage.sol#L139-L169


 - [ ] ID-230
[StorageSlot.tstore(StorageSlot.Int256SlotType,int256)](src/L2/Mock/StorageSlot.sol#L342-L347) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L344-L346)

src/L2/Mock/StorageSlot.sol#L342-L347


 - [ ] ID-231
[StorageSlot.getStringSlot(string)](src/L2/Mock/StorageSlot.sol#L156-L163) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L160-L162)

src/L2/Mock/StorageSlot.sol#L156-L163


 - [ ] ID-232
[DepositManager._decodeDepositManagerOnApproveData(bytes)](src/L1/Mock/DepositManager.sol#L98-L106) uses assembly
	- [INLINE ASM](src/L1/Mock/DepositManager.sol#L103-L105)

src/L1/Mock/DepositManager.sol#L98-L106


 - [ ] ID-233
[Address._revert(bytes)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L146-L158) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L151-L154)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L146-L158


 - [ ] ID-234
[StorageSlot.getBytesSlot(bytes)](src/L2/Mock/StorageSlot.sol#L180-L187) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L184-L186)

src/L2/Mock/StorageSlot.sol#L180-L187


 - [ ] ID-235
[ProxyL1WrappedStakedTON._fallback()](src/proxy/ProxyL1WrappedStakedTON.sol#L124-L154) uses assembly
	- [INLINE ASM](src/proxy/ProxyL1WrappedStakedTON.sol#L132-L153)

src/proxy/ProxyL1WrappedStakedTON.sol#L124-L154


 - [ ] ID-236
[StorageSlot.tstore(StorageSlot.BooleanSlotType,bool)](src/L2/Mock/StorageSlot.sol#L282-L287) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L284-L286)

src/L2/Mock/StorageSlot.sol#L282-L287


 - [ ] ID-237
[StorageSlot.tload(StorageSlot.Uint256SlotType)](src/L2/Mock/StorageSlot.sol#L312-L317) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L314-L316)

src/L2/Mock/StorageSlot.sol#L312-L317


 - [ ] ID-238
[StorageSlot.getBytesSlot(bytes32)](src/L2/Mock/StorageSlot.sol#L168-L175) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L172-L174)

src/L2/Mock/StorageSlot.sol#L168-L175


 - [ ] ID-239
[StorageSlot.tload(StorageSlot.Bytes32SlotType)](src/L2/Mock/StorageSlot.sol#L292-L297) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L294-L296)

src/L2/Mock/StorageSlot.sol#L292-L297


 - [ ] ID-240
[ProxyGemFactory._fallback()](src/proxy/ProxyGemFactory.sol#L124-L154) uses assembly
	- [INLINE ASM](src/proxy/ProxyGemFactory.sol#L132-L153)

src/proxy/ProxyGemFactory.sol#L124-L154


 - [ ] ID-241
[ERC721._checkOnERC721Received(address,address,uint256,bytes)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L465-L482) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L476-L478)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L465-L482


 - [ ] ID-242
[StorageSlot.getUint256Slot(bytes32)](src/L2/Mock/StorageSlot.sol#L120-L127) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L124-L126)

src/L2/Mock/StorageSlot.sol#L120-L127


 - [ ] ID-243
[StorageSlot.getBytes32Slot(bytes32)](src/L2/Mock/StorageSlot.sol#L108-L115) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L112-L114)

src/L2/Mock/StorageSlot.sol#L108-L115


 - [ ] ID-244
[StorageSlot.tload(StorageSlot.AddressSlotType)](src/L2/Mock/StorageSlot.sol#L252-L257) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L254-L256)

src/L2/Mock/StorageSlot.sol#L252-L257


 - [ ] ID-245
[StorageSlot.getStringSlot(bytes32)](src/L2/Mock/StorageSlot.sol#L144-L151) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L148-L150)

src/L2/Mock/StorageSlot.sol#L144-L151


 - [ ] ID-246
[DRBCoordinatorMock._call(address,bytes,uint256)](src/L2/Mock/DRBCoordinatorMock.sol#L140-L180) uses assembly
	- [INLINE ASM](src/L2/Mock/DRBCoordinatorMock.sol#L145-L178)

src/L2/Mock/DRBCoordinatorMock.sol#L140-L180


 - [ ] ID-247
[GemFactory._checkOnERC721(address,address,uint256,bytes)](src/L2/GemFactory.sol#L787-L804) uses assembly
	- [INLINE ASM](src/L2/GemFactory.sol#L798-L800)

src/L2/GemFactory.sol#L787-L804


 - [ ] ID-248
[Math.mulDiv(uint256,uint256,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L130-L133)
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L154-L161)
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L167-L176)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L123-L202


 - [ ] ID-249
[StorageSlot.tload(StorageSlot.Int256SlotType)](src/L2/Mock/StorageSlot.sol#L332-L337) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L334-L336)

src/L2/Mock/StorageSlot.sol#L332-L337


 - [ ] ID-250
[Strings.toString(uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L24-L44) uses assembly
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L30-L32)
	- [INLINE ASM](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L36-L38)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L24-L44


 - [ ] ID-251
[StorageSlot.getAddressSlot(bytes32)](src/L2/Mock/StorageSlot.sol#L84-L91) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L88-L90)

src/L2/Mock/StorageSlot.sol#L84-L91


 - [ ] ID-252
[StorageSlot.tstore(StorageSlot.AddressSlotType,address)](src/L2/Mock/StorageSlot.sol#L262-L267) uses assembly
	- [INLINE ASM](src/L2/Mock/StorageSlot.sol#L264-L266)

src/L2/Mock/StorageSlot.sol#L262-L267


## boolean-equal
Impact: Informational
Confidence: High
 - [ ] ID-253
[GemFactory.pickMinedGEM(uint256)](src/L2/GemFactory.sol#L371-L394) compares to a boolean constant:
	-[require(bool,string)(Gems[_tokenId].isLocked == true,Gems is not mining)](src/L2/GemFactory.sol#L374)

src/L2/GemFactory.sol#L371-L394


 - [ ] ID-254
[L1WrappedStakedTON._claimWithdrawal(address)](src/L1/L1WrappedStakedTON.sol#L166-L185) compares to a boolean constant:
	-[require(bool,string)(request.processed == false,already processed)](src/L1/L1WrappedStakedTON.sol#L171)

src/L1/L1WrappedStakedTON.sol#L166-L185


 - [ ] ID-255
[GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428) compares to a boolean constant:
	-[require(bool,string)(userMiningToken[msg.sender][_tokenId] == true,user is not mining this Gem)](src/L2/GemFactory.sol#L400)

src/L2/GemFactory.sol#L396-L428


 - [ ] ID-256
[GemFactory._setTokenURI(uint256,string)](src/L2/GemFactory.sol#L969-L972) compares to a boolean constant:
	-[require(bool,string)(msg.sender == ownerOf(tokenId) || isAdmin(msg.sender) == true,not allowed to set token URI)](src/L2/GemFactory.sol#L970)

src/L2/GemFactory.sol#L969-L972


 - [ ] ID-257
[GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369) compares to a boolean constant:
	-[require(bool,string)(userMiningToken[msg.sender][_tokenId] == true,user is not mining this Gem)](src/L2/GemFactory.sol#L361)

src/L2/GemFactory.sol#L356-L369


 - [ ] ID-258
[GemFactory.cancelMining(uint256)](src/L2/GemFactory.sol#L356-L369) compares to a boolean constant:
	-[require(bool,string)(Gems[_tokenId].isLocked == true,Gems is not mining)](src/L2/GemFactory.sol#L360)

src/L2/GemFactory.sol#L356-L369


 - [ ] ID-259
[MarketPlace._putGemForSale(uint256,uint256,address)](src/L2/MarketPlace.sol#L104-L119) compares to a boolean constant:
	-[require(bool,string)(IGemFactory(gemFactory).isTokenLocked(_tokenId) == false,Gem is already for sale or mining)](src/L2/MarketPlace.sol#L107)

src/L2/MarketPlace.sol#L104-L119


 - [ ] ID-260
[GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428) compares to a boolean constant:
	-[require(bool,string)(s_requests[requestId].fulfilled == true,you need to call pickMinedGEM function first)](src/L2/GemFactory.sol#L405)

src/L2/GemFactory.sol#L396-L428


 - [ ] ID-261
[GemFactory.pickMinedGEM(uint256)](src/L2/GemFactory.sol#L371-L394) compares to a boolean constant:
	-[require(bool,string)(userMiningToken[ownerOf(_tokenId)][_tokenId] == true,gem not mining)](src/L2/GemFactory.sol#L375)

src/L2/GemFactory.sol#L371-L394


 - [ ] ID-262
[GemFactory.pickMinedGEM(uint256)](src/L2/GemFactory.sol#L371-L394) compares to a boolean constant:
	-[require(bool,string)(ownerOf(_tokenId) == msg.sender || isAdmin(msg.sender) == true,not GEM owner or not admin)](src/L2/GemFactory.sol#L372)

src/L2/GemFactory.sol#L371-L394


 - [ ] ID-263
[GemFactory.claimMinedGEM(uint256)](src/L2/GemFactory.sol#L396-L428) compares to a boolean constant:
	-[require(bool,string)(Gems[_tokenId].isLocked == true,Gems is not mining)](src/L2/GemFactory.sol#L402)

src/L2/GemFactory.sol#L396-L428


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-264
6 different versions of Solidity are used:
	- Version constraint ^0.8.20 is used by:
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/AccessControl.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/Ownable.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/IERC4906.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Context.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
		-[^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#L4)
	- Version constraint ^0.8.25 is used by:
		-[^0.8.25](src/L1/L1WrappedStakedTON.sol#L2)
		-[^0.8.25](src/L1/L1WrappedStakedTONFactory.sol#L2)
		-[^0.8.25](src/L1/L1WrappedStakedTONProxy.sol#L2)
		-[^0.8.25](src/L1/L1WrappedStakedTONStorage.sol#L2)
		-[^0.8.25](src/L1/Mock/MockToken.sol#L2)
		-[^0.8.25](src/L1/Mock/interfaces/IProxyAction.sol#L2)
		-[^0.8.25](src/L1/Mock/interfaces/IProxyEvent.sol#L2)
		-[^0.8.25](src/L2/GemFactory.sol#L2)
		-[^0.8.25](src/L2/GemFactoryProxy.sol#L2)
		-[^0.8.25](src/L2/GemFactoryStorage.sol#L2)
		-[^0.8.25](src/L2/MarketPlace.sol#L2)
		-[^0.8.25](src/L2/MarketPlaceStorage.sol#L2)
		-[^0.8.25](src/L2/Mock/IOVM_GasPriceOracle.sol#L2)
		-[^0.8.25](src/L2/Mock/OptimismL1Fees.sol#L2)
		-[^0.8.25](src/L2/Mock/ReentrancyGuardTransient.sol#L3)
		-[^0.8.25](src/L2/Mock/StorageSlot.sol#L5)
		-[^0.8.25](src/L2/Randomness/DRBConsumerBase.sol#L2)
		-[^0.8.25](src/L2/Treasury.sol#L2)
		-[^0.8.25](src/L2/WstonSwapPool.sol#L2)
		-[^0.8.25](src/common/AuthRoleGemFactory.sol#L2)
		-[^0.8.25](src/interfaces/ICRRRNGCoordinator.sol#L2)
		-[^0.8.25](src/interfaces/IDRBCoordinator.sol#L2)
		-[^0.8.25](src/interfaces/IDepositManager.sol#L2)
		-[^0.8.25](src/interfaces/IGemFactory.sol#L2)
		-[^0.8.25](src/interfaces/IMockL2WSTON.sol#L2)
		-[^0.8.25](src/interfaces/IProxyAction.sol#L2)
		-[^0.8.25](src/interfaces/IProxyEvent.sol#L2)
		-[^0.8.25](src/interfaces/ISeigManager.sol#L2)
		-[^0.8.25](src/libraries/DSMath.sol#L2)
		-[^0.8.25](src/proxy/ProxyGemFactory.sol#L2)
		-[^0.8.25](src/proxy/ProxyL1WrappedStakedTON.sol#L2)
		-[^0.8.25](src/proxy/ProxyStorage.sol#L2)
	- Version constraint ^0.8.4 is used by:
		-[^0.8.4](src/L1/Mock/Candidate.sol#L2)
		-[^0.8.4](src/L1/Mock/CandidateStorage.sol#L2)
		-[^0.8.4](src/L1/Mock/CoinageFactory.sol#L2)
		-[^0.8.4](src/L1/Mock/DepositManager.sol#L2)
		-[^0.8.4](src/L1/Mock/DepositManagerStorage.sol#L2)
		-[^0.8.4](src/L1/Mock/Layer2Registry.sol#L2)
		-[^0.8.4](src/L1/Mock/Layer2RegistryStorage.sol#L2)
		-[^0.8.4](src/L1/Mock/SeigManager.sol#L2)
		-[^0.8.4](src/L1/Mock/SeigManagerStorage.sol#L2)
		-[^0.8.4](src/L1/Mock/common/AccessRoleCommon.sol#L2)
		-[^0.8.4](src/L1/Mock/common/AccessibleCommon.sol#L2)
		-[^0.8.4](src/L1/Mock/common/AuthControlCoinage.sol#L2)
		-[^0.8.4](src/L1/Mock/common/AuthControlSeigManager.sol#L2)
		-[^0.8.4](src/L1/Mock/common/AuthRoleCoinage.sol#L2)
		-[^0.8.4](src/L1/Mock/common/AuthRoleSeigManager.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/AutoRefactorCoinageI.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/CoinageFactoryI.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/ICandidate.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/ICandidateFactory.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/IDAOAgendaManager.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/IDAOCommittee.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/IDAOVault.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/IRefactor.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/IStorageStateCommittee.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/IWTON.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/Layer2I.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/Layer2RegistryI.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/RefactorCoinageSnapshotI.sol#L2)
		-[^0.8.4](src/L1/Mock/interfaces/SeigManagerI.sol#L2)
		-[^0.8.4](src/L1/Mock/libraries/Agenda.sol#L2)
		-[^0.8.4](src/L1/Mock/libraries/DSMath.sol#L2)
		-[^0.8.4](src/L1/Mock/libraries/SArrays.sol#L2)
		-[^0.8.4](src/L1/Mock/proxy/ProxyCoinage.sol#L2)
		-[^0.8.4](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L2)
		-[^0.8.4](src/L1/Mock/proxy/RefactorCoinageSnapshotProxy.sol#L2)
		-[^0.8.4](src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L2)
		-[^0.8.4](src/common/AuthControlGemFactory.sol#L2)
	- Version constraint ^0.8.23 is used by:
		-[^0.8.23](src/L2/Mock/DRBCoordinatorMock.sol#L2)
	- Version constraint ^0.8.9 is used by:
		-[^0.8.9](src/L2/Mock/IL2StandardERC20.sol#L2)
		-[^0.8.9](src/L2/Mock/L2StandardERC20.sol#L2)
		-[^0.8.9](src/L2/Mock/MockTON.sol#L2)
		-[^0.8.9](src/interfaces/IL2StandardERC20.sol#L2)
	- Version constraint >0.5.0<0.9.0 is used by:
		-[>0.5.0<0.9.0](src/interfaces/IL1StandardBridge.sol#L2)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/AccessControl.sol#L4


## cyclomatic-complexity
Impact: Informational
Confidence: High
 - [ ] ID-265
[GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])](src/L2/GemFactory.sol#L184-L325) has a high cyclomatic complexity (16).

src/L2/GemFactory.sol#L184-L325


## dead-code
Impact: Informational
Confidence: Medium
 - [ ] ID-266
[MarketPlace._toRAY(uint256)](src/L2/MarketPlace.sol#L154-L156) is never used and should be removed

src/L2/MarketPlace.sol#L154-L156


 - [ ] ID-267
[DSMath.wdiv2(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L50-L52) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L50-L52


 - [ ] ID-268
[DSMath.wpow(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L72-L82) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L72-L82


 - [ ] ID-269
[DSMath.imin(int256,int256)](src/L1/Mock/libraries/DSMath.sol#L21-L23) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L21-L23


 - [ ] ID-270
[DSMath.wmul(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L31-L33) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L31-L33


 - [ ] ID-271
[RefactorCoinageSnapshot._toRAYFactored(uint256)](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L202-L204) is never used and should be removed

src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L202-L204


 - [ ] ID-272
[DSMath.wmul2(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L44-L46) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L44-L46


 - [ ] ID-273
[DSMath.rpow(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L84-L94) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L84-L94


 - [ ] ID-274
[DSMath.imax(int256,int256)](src/L1/Mock/libraries/DSMath.sol#L24-L26) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L24-L26


 - [ ] ID-275
[DSMath.sub(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L8-L10) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L8-L10


 - [ ] ID-276
[DSMath.wdiv(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L37-L39) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L37-L39


 - [ ] ID-277
[DSMath.max(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L18-L20) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L18-L20


 - [ ] ID-278
[DSMath.min(uint256,uint256)](src/L1/Mock/libraries/DSMath.sol#L15-L17) is never used and should be removed

src/L1/Mock/libraries/DSMath.sol#L15-L17


 - [ ] ID-279
[OptimismL1Fees._getOptimismL1UpperBoundDataFee(uint256)](src/L2/Mock/OptimismL1Fees.sol#L85-L94) is never used and should be removed

src/L2/Mock/OptimismL1Fees.sol#L85-L94


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-280
Version constraint ^0.8.4 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- DataLocationChangeInInternalOverride
	- NestedCalldataArrayAbiReencodingSizeValidation
	- SignedImmutables.
It is used by:
	- [^0.8.4](src/L1/Mock/Candidate.sol#L2)
	- [^0.8.4](src/L1/Mock/CandidateStorage.sol#L2)
	- [^0.8.4](src/L1/Mock/CoinageFactory.sol#L2)
	- [^0.8.4](src/L1/Mock/DepositManager.sol#L2)
	- [^0.8.4](src/L1/Mock/DepositManagerStorage.sol#L2)
	- [^0.8.4](src/L1/Mock/Layer2Registry.sol#L2)
	- [^0.8.4](src/L1/Mock/Layer2RegistryStorage.sol#L2)
	- [^0.8.4](src/L1/Mock/SeigManager.sol#L2)
	- [^0.8.4](src/L1/Mock/SeigManagerStorage.sol#L2)
	- [^0.8.4](src/L1/Mock/common/AccessRoleCommon.sol#L2)
	- [^0.8.4](src/L1/Mock/common/AccessibleCommon.sol#L2)
	- [^0.8.4](src/L1/Mock/common/AuthControlCoinage.sol#L2)
	- [^0.8.4](src/L1/Mock/common/AuthControlSeigManager.sol#L2)
	- [^0.8.4](src/L1/Mock/common/AuthRoleCoinage.sol#L2)
	- [^0.8.4](src/L1/Mock/common/AuthRoleSeigManager.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/AutoRefactorCoinageI.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/CoinageFactoryI.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/ICandidate.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/ICandidateFactory.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/IDAOAgendaManager.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/IDAOCommittee.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/IDAOVault.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/IRefactor.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/IStorageStateCommittee.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/IWTON.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/Layer2I.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/Layer2RegistryI.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/RefactorCoinageSnapshotI.sol#L2)
	- [^0.8.4](src/L1/Mock/interfaces/SeigManagerI.sol#L2)
	- [^0.8.4](src/L1/Mock/libraries/Agenda.sol#L2)
	- [^0.8.4](src/L1/Mock/libraries/DSMath.sol#L2)
	- [^0.8.4](src/L1/Mock/libraries/SArrays.sol#L2)
	- [^0.8.4](src/L1/Mock/proxy/ProxyCoinage.sol#L2)
	- [^0.8.4](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L2)
	- [^0.8.4](src/L1/Mock/proxy/RefactorCoinageSnapshotProxy.sol#L2)
	- [^0.8.4](src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L2)
	- [^0.8.4](src/common/AuthControlGemFactory.sol#L2)

src/L1/Mock/Candidate.sol#L2


 - [ ] ID-281
Version constraint ^0.8.9 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess
	- AbiReencodingHeadOverflowWithStaticArrayCleanup
	- DirtyBytesArrayToStorage
	- DataLocationChangeInInternalOverride
	- NestedCalldataArrayAbiReencodingSizeValidation.
It is used by:
	- [^0.8.9](src/L2/Mock/IL2StandardERC20.sol#L2)
	- [^0.8.9](src/L2/Mock/L2StandardERC20.sol#L2)
	- [^0.8.9](src/L2/Mock/MockTON.sol#L2)
	- [^0.8.9](src/interfaces/IL2StandardERC20.sol#L2)

src/L2/Mock/IL2StandardERC20.sol#L2


 - [ ] ID-282
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/AccessControl.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/Ownable.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/IERC4906.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#L3)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Context.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Strings.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol#L4)
	- [^0.8.20](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#L4)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/AccessControl.sol#L4


 - [ ] ID-283
Version constraint >0.5.0<0.9.0 is too complex.
It is used by:
	- [>0.5.0<0.9.0](src/interfaces/IL1StandardBridge.sol#L2)

src/interfaces/IL1StandardBridge.sol#L2


 - [ ] ID-284
Version constraint ^0.8.23 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
.
It is used by:
	- [^0.8.23](src/L2/Mock/DRBCoordinatorMock.sol#L2)

src/L2/Mock/DRBCoordinatorMock.sol#L2


 - [ ] ID-285
Version constraint ^0.8.25 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
.
It is used by:
	- [^0.8.25](src/L1/L1WrappedStakedTON.sol#L2)
	- [^0.8.25](src/L1/L1WrappedStakedTONFactory.sol#L2)
	- [^0.8.25](src/L1/L1WrappedStakedTONProxy.sol#L2)
	- [^0.8.25](src/L1/L1WrappedStakedTONStorage.sol#L2)
	- [^0.8.25](src/L1/Mock/MockToken.sol#L2)
	- [^0.8.25](src/L1/Mock/interfaces/IProxyAction.sol#L2)
	- [^0.8.25](src/L1/Mock/interfaces/IProxyEvent.sol#L2)
	- [^0.8.25](src/L2/GemFactory.sol#L2)
	- [^0.8.25](src/L2/GemFactoryProxy.sol#L2)
	- [^0.8.25](src/L2/GemFactoryStorage.sol#L2)
	- [^0.8.25](src/L2/MarketPlace.sol#L2)
	- [^0.8.25](src/L2/MarketPlaceStorage.sol#L2)
	- [^0.8.25](src/L2/Mock/IOVM_GasPriceOracle.sol#L2)
	- [^0.8.25](src/L2/Mock/OptimismL1Fees.sol#L2)
	- [^0.8.25](src/L2/Mock/ReentrancyGuardTransient.sol#L3)
	- [^0.8.25](src/L2/Mock/StorageSlot.sol#L5)
	- [^0.8.25](src/L2/Randomness/DRBConsumerBase.sol#L2)
	- [^0.8.25](src/L2/Treasury.sol#L2)
	- [^0.8.25](src/L2/WstonSwapPool.sol#L2)
	- [^0.8.25](src/common/AuthRoleGemFactory.sol#L2)
	- [^0.8.25](src/interfaces/ICRRRNGCoordinator.sol#L2)
	- [^0.8.25](src/interfaces/IDRBCoordinator.sol#L2)
	- [^0.8.25](src/interfaces/IDepositManager.sol#L2)
	- [^0.8.25](src/interfaces/IGemFactory.sol#L2)
	- [^0.8.25](src/interfaces/IMockL2WSTON.sol#L2)
	- [^0.8.25](src/interfaces/IProxyAction.sol#L2)
	- [^0.8.25](src/interfaces/IProxyEvent.sol#L2)
	- [^0.8.25](src/interfaces/ISeigManager.sol#L2)
	- [^0.8.25](src/libraries/DSMath.sol#L2)
	- [^0.8.25](src/proxy/ProxyGemFactory.sol#L2)
	- [^0.8.25](src/proxy/ProxyL1WrappedStakedTON.sol#L2)
	- [^0.8.25](src/proxy/ProxyStorage.sol#L2)

src/L1/L1WrappedStakedTON.sol#L2


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-286
Low level call in [Address.functionStaticCall(address,bytes)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L95-L98):
	- [(success,returndata) = target.staticcall(data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L96)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L95-L98


 - [ ] ID-287
Low level call in [Address.functionCallWithValue(address,bytes,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L83-L89):
	- [(success,returndata) = target.call{value: value}(data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L87)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L83-L89


 - [ ] ID-288
Low level call in [SafeERC20._callOptionalReturnBool(IERC20,bytes)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L110-L117):
	- [(success,returndata) = address(token).call(data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L115)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol#L110-L117


 - [ ] ID-289
Low level call in [Address.sendValue(address,uint256)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L41-L50):
	- [(success,None) = recipient.call{value: amount}()](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L46)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L41-L50


 - [ ] ID-290
Low level call in [Address.functionDelegateCall(address,bytes)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L104-L107):
	- [(success,returndata) = target.delegatecall(data)](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L105)

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/Address.sol#L104-L107


## missing-inheritance
Impact: Informational
Confidence: High
 - [ ] ID-291
[SeigManager](src/L1/Mock/SeigManager.sol#L88-L838) should inherit from [IIISeigManager](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L14-L16)

src/L1/Mock/SeigManager.sol#L88-L838


 - [ ] ID-292
[RefactorCoinageSnapshot](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L30-L347) should inherit from [AutoRefactorCoinageI](src/L1/Mock/interfaces/AutoRefactorCoinageI.sol#L4-L15)

src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L30-L347


 - [ ] ID-293
[L1WrappedStakedTON](src/L1/L1WrappedStakedTON.sol#L19-L245) should inherit from [ICandidate](src/L1/L1WrappedStakedTON.sol#L14-L16)

src/L1/L1WrappedStakedTON.sol#L19-L245


 - [ ] ID-294
[Candidate](src/L1/Mock/Candidate.sol#L30-L203) should inherit from [ICandidate](src/L1/L1WrappedStakedTON.sol#L14-L16)

src/L1/Mock/Candidate.sol#L30-L203


 - [ ] ID-295
[DepositManager](src/L1/Mock/DepositManager.sol#L33-L356) should inherit from [IOnApprove](src/L1/Mock/DepositManager.sol#L11-L13)

src/L1/Mock/DepositManager.sol#L33-L356


 - [ ] ID-296
[DepositManager](src/L1/Mock/DepositManager.sol#L33-L356) should inherit from [IDepositManager](src/interfaces/IDepositManager.sol#L5-L11)

src/L1/Mock/DepositManager.sol#L33-L356


 - [ ] ID-297
[GemFactory](src/L2/GemFactory.sol#L28-L1148) should inherit from [IGemFactory](src/interfaces/IGemFactory.sol#L6-L42)

src/L2/GemFactory.sol#L28-L1148


 - [ ] ID-298
[RefactorCoinageSnapshot](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L30-L347) should inherit from [IIISeigManager](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L14-L16)

src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L30-L347


 - [ ] ID-299
[GemFactory](src/L2/GemFactory.sol#L28-L1148) should inherit from [ITON](src/L1/Mock/SeigManager.sol#L41-L44)

src/L2/GemFactory.sol#L28-L1148


 - [ ] ID-300
[RefactorCoinageSnapshot](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L30-L347) should inherit from [IIAutoRefactorCoinage](src/L1/Mock/CoinageFactory.sol#L9-L16)

src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L30-L347


 - [ ] ID-301
[Treasury](src/L2/Treasury.sol#L12-L137) should inherit from [ITreasury](src/L2/GemFactory.sol#L18-L21)

src/L2/Treasury.sol#L12-L137


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-302
Variable [GemFactoryStorage.MythicGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L83) is not in mixedCase

src/L2/GemFactoryStorage.sol#L83


 - [ ] ID-303
Parameter [GemFactory.setGemsValue(uint256,uint256,uint256,uint256,uint256,uint256)._EpicGemsValue](src/L2/GemFactory.sol#L160) is not in mixedCase

src/L2/GemFactory.sol#L160


 - [ ] ID-304
Parameter [Candidate.initialize(address,bool,string,address,address)._memo](src/L1/Mock/Candidate.sol#L56) is not in mixedCase

src/L1/Mock/Candidate.sol#L56


 - [ ] ID-305
Parameter [ProxyCoinage.setSelectorImplementations2(bytes4[],address)._selectors](src/L1/Mock/proxy/ProxyCoinage.sol#L63) is not in mixedCase

src/L1/Mock/proxy/ProxyCoinage.sol#L63


 - [ ] ID-306
Parameter [GemFactory.setGemsValue(uint256,uint256,uint256,uint256,uint256,uint256)._MythicGemsValue](src/L2/GemFactory.sol#L162) is not in mixedCase

src/L2/GemFactory.sol#L162


 - [ ] ID-307
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._LegendaryGemsValue](src/L2/GemFactory.sol#L91) is not in mixedCase

src/L2/GemFactory.sol#L91


 - [ ] ID-308
Parameter [ProxyL1WrappedStakedTON.setAliveImplementation2(address,bool)._alive](src/proxy/ProxyL1WrappedStakedTON.sol#L52) is not in mixedCase

src/proxy/ProxyL1WrappedStakedTON.sol#L52


 - [ ] ID-309
Parameter [ProxyGemFactory.setAliveImplementation2(address,bool)._alive](src/proxy/ProxyGemFactory.sol#L52) is not in mixedCase

src/proxy/ProxyGemFactory.sol#L52


 - [ ] ID-310
Parameter [GemFactory.addBackgroundColor(string)._backgroundColor](src/L2/GemFactory.sol#L837) is not in mixedCase

src/L2/GemFactory.sol#L837


 - [ ] ID-311
Variable [GemFactoryStorage.UniqueGemsValue](src/L2/GemFactoryStorage.sol#L73) is not in mixedCase

src/L2/GemFactoryStorage.sol#L73


 - [ ] ID-312
Parameter [Candidate.castVote(uint256,uint256,string)._vote](src/L1/Mock/Candidate.sol#L125) is not in mixedCase

src/L1/Mock/Candidate.sol#L125


 - [ ] ID-313
Parameter [ProxyCoinage.setProxyPause(bool)._pause](src/L1/Mock/proxy/ProxyCoinage.sol#L28) is not in mixedCase

src/L1/Mock/proxy/ProxyCoinage.sol#L28


 - [ ] ID-314
Parameter [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._rarity](src/L2/GemFactory.sol#L466) is not in mixedCase

src/L2/GemFactory.sol#L466


 - [ ] ID-315
Variable [GemFactoryStorage.RareGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L79) is not in mixedCase

src/L2/GemFactoryStorage.sol#L79


 - [ ] ID-316
Parameter [Treasury.createPreminedGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._tokenURIs](src/L2/Treasury.sol#L93) is not in mixedCase

src/L2/Treasury.sol#L93


 - [ ] ID-317
Parameter [GemFactory.startMiningGEM(uint256)._tokenId](src/L2/GemFactory.sol#L332) is not in mixedCase

src/L2/GemFactory.sol#L332


 - [ ] ID-318
Parameter [GemFactory.setminingTrys(uint256,uint256,uint256,uint256,uint256,uint256)._EpicminingTry](src/L2/GemFactory.sol#L144) is not in mixedCase

src/L2/GemFactory.sol#L144


 - [ ] ID-319
Variable [GemFactoryStorage.MythicminingTry](src/L2/GemFactoryStorage.sol#L69) is not in mixedCase

src/L2/GemFactoryStorage.sol#L69


 - [ ] ID-320
Parameter [Treasury.createPreminedGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._quadrants](src/L2/Treasury.sol#L92) is not in mixedCase

src/L2/Treasury.sol#L92


 - [ ] ID-321
Contract [IOVM_GasPriceOracle](src/L2/Mock/IOVM_GasPriceOracle.sol#L4-L53) is not in CapWords

src/L2/Mock/IOVM_GasPriceOracle.sol#L4-L53


 - [ ] ID-322
Parameter [MarketPlace.initialize(address,address,uint256,address,address)._ton](src/L2/MarketPlace.sol#L41) is not in mixedCase

src/L2/MarketPlace.sol#L41


 - [ ] ID-323
Parameter [L2StandardERC20.mint(address,uint256)._to](src/L2/Mock/L2StandardERC20.sol#L46) is not in mixedCase

src/L2/Mock/L2StandardERC20.sol#L46


 - [ ] ID-324
Parameter [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._tokenURI](src/L2/GemFactory.sol#L469) is not in mixedCase

src/L2/GemFactory.sol#L469


 - [ ] ID-325
Parameter [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])._tokenIds](src/L2/GemFactory.sol#L185) is not in mixedCase

src/L2/GemFactory.sol#L185


 - [ ] ID-326
Parameter [ProxyGemFactory.implementation2(uint256)._index](src/proxy/ProxyGemFactory.sol#L86) is not in mixedCase

src/proxy/ProxyGemFactory.sol#L86


 - [ ] ID-327
Parameter [L1WrappedStakedTON.depositAndGetWSTON(uint256)._amount](src/L1/L1WrappedStakedTON.sol#L62) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L62


 - [ ] ID-328
Parameter [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._color](src/L2/GemFactory.sol#L467) is not in mixedCase

src/L2/GemFactory.sol#L467


 - [ ] ID-329
Parameter [L1WrappedStakedTONFactory.createWSTONToken(address,address,address,string,string)._seigManager](src/L1/L1WrappedStakedTONFactory.sol#L20) is not in mixedCase

src/L1/L1WrappedStakedTONFactory.sol#L20


 - [ ] ID-330
Parameter [MarketPlace.setStakingIndex(uint256)._stakingIndex](src/L2/MarketPlace.sol#L94) is not in mixedCase

src/L2/MarketPlace.sol#L94


 - [ ] ID-331
Parameter [MockTON.mint(address,uint256)._amount](src/L2/Mock/MockTON.sol#L46) is not in mixedCase

src/L2/Mock/MockTON.sol#L46


 - [ ] ID-332
Parameter [GemFactory.setGemsMiningPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._CommonGemsMiningPeriod](src/L2/GemFactory.sol#L109) is not in mixedCase

src/L2/GemFactory.sol#L109


 - [ ] ID-333
Parameter [GemFactory.tokensOfOwner(address)._owner](src/L2/GemFactory.sol#L1118) is not in mixedCase

src/L2/GemFactory.sol#L1118


 - [ ] ID-334
Parameter [GemFactory.setGemsMiningPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._UniqueGemsMiningPeriod](src/L2/GemFactory.sol#L111) is not in mixedCase

src/L2/GemFactory.sol#L111


 - [ ] ID-335
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._MythicGemsValue](src/L2/GemFactory.sol#L92) is not in mixedCase

src/L2/GemFactory.sol#L92


 - [ ] ID-336
Variable [GemFactoryStorage.CommonGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L85) is not in mixedCase

src/L2/GemFactoryStorage.sol#L85


 - [ ] ID-337
Parameter [GemFactory.pickMinedGEM(uint256)._tokenId](src/L2/GemFactory.sol#L371) is not in mixedCase

src/L2/GemFactory.sol#L371


 - [ ] ID-338
Parameter [GemFactory.isTokenLocked(uint256)._tokenId](src/L2/GemFactory.sol#L1065) is not in mixedCase

src/L2/GemFactory.sol#L1065


 - [ ] ID-339
Parameter [GemFactory.burnTokens(address,uint256[])._from](src/L2/GemFactory.sol#L451) is not in mixedCase

src/L2/GemFactory.sol#L451


 - [ ] ID-340
Parameter [GemFactory.setminingTrys(uint256,uint256,uint256,uint256,uint256,uint256)._LegendaryminingTry](src/L2/GemFactory.sol#L145) is not in mixedCase

src/L2/GemFactory.sol#L145


 - [ ] ID-341
Parameter [MockToken.mint(address,uint256)._to](src/L1/Mock/MockToken.sol#L16) is not in mixedCase

src/L1/Mock/MockToken.sol#L16


 - [ ] ID-342
Parameter [Treasury.createPreminedGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._rarity](src/L2/Treasury.sol#L76) is not in mixedCase

src/L2/Treasury.sol#L76


 - [ ] ID-343
Parameter [Candidate.initialize(address,bool,string,address,address)._seigManager](src/L1/Mock/Candidate.sol#L58) is not in mixedCase

src/L1/Mock/Candidate.sol#L58


 - [ ] ID-344
Parameter [GemFactory.setminingTrys(uint256,uint256,uint256,uint256,uint256,uint256)._CommonminingTry](src/L2/GemFactory.sol#L141) is not in mixedCase

src/L2/GemFactory.sol#L141


 - [ ] ID-345
Parameter [GemFactory.createGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._quadrants](src/L2/GemFactory.sol#L468) is not in mixedCase

src/L2/GemFactory.sol#L468


 - [ ] ID-346
Parameter [GemFactory.setGemsCooldownPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._LegendaryGemsCooldownPeriod](src/L2/GemFactory.sol#L129) is not in mixedCase

src/L2/GemFactory.sol#L129


 - [ ] ID-347
Parameter [Treasury.transferTreasuryGEMto(address,uint256)._to](src/L2/Treasury.sol#L103) is not in mixedCase

src/L2/Treasury.sol#L103


 - [ ] ID-348
Parameter [L1WrappedStakedTON.setDepositManagerAddress(address)._depositManager](src/L1/L1WrappedStakedTON.sol#L214) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L214


 - [ ] ID-349
Parameter [Treasury.createPreminedGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._rarities](src/L2/Treasury.sol#L90) is not in mixedCase

src/L2/Treasury.sol#L90


 - [ ] ID-350
Parameter [ProxyGemFactory.setProxyPause(bool)._pause](src/proxy/ProxyGemFactory.sol#L27) is not in mixedCase

src/proxy/ProxyGemFactory.sol#L27


 - [ ] ID-351
Parameter [DRBCoordinatorMock.requestRandomWordDirectFunding(IDRBCoordinator.RandomWordsRequest)._request](src/L2/Mock/DRBCoordinatorMock.sol#L61) is not in mixedCase

src/L2/Mock/DRBCoordinatorMock.sol#L61


 - [ ] ID-352
Parameter [GemFactory.cancelMining(uint256)._tokenId](src/L2/GemFactory.sol#L356) is not in mixedCase

src/L2/GemFactory.sol#L356


 - [ ] ID-353
Parameter [ProxyGemFactory.setSelectorImplementations2(bytes4[],address)._imp](src/proxy/ProxyGemFactory.sol#L60) is not in mixedCase

src/proxy/ProxyGemFactory.sol#L60


 - [ ] ID-354
Parameter [GemFactory.setGemsMiningPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._RareGemsMiningPeriod](src/L2/GemFactory.sol#L110) is not in mixedCase

src/L2/GemFactory.sol#L110


 - [ ] ID-355
Parameter [GemFactory.setminingTrys(uint256,uint256,uint256,uint256,uint256,uint256)._RareminingTry](src/L2/GemFactory.sol#L142) is not in mixedCase

src/L2/GemFactory.sol#L142


 - [ ] ID-356
Parameter [MarketPlace.initialize(address,address,uint256,address,address)._gemfactory](src/L2/MarketPlace.sol#L38) is not in mixedCase

src/L2/MarketPlace.sol#L38


 - [ ] ID-357
Parameter [Treasury.transferTreasuryGEMto(address,uint256)._tokenId](src/L2/Treasury.sol#L103) is not in mixedCase

src/L2/Treasury.sol#L103


 - [ ] ID-358
Parameter [Treasury.createPreminedGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._tokenURI](src/L2/Treasury.sol#L79) is not in mixedCase

src/L2/Treasury.sol#L79


 - [ ] ID-359
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._UniqueGemsValue](src/L2/GemFactory.sol#L89) is not in mixedCase

src/L2/GemFactory.sol#L89


 - [ ] ID-360
Variable [GemFactoryStorage.EpicGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L88) is not in mixedCase

src/L2/GemFactoryStorage.sol#L88


 - [ ] ID-361
Parameter [Treasury.createPreminedGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._colors](src/L2/Treasury.sol#L91) is not in mixedCase

src/L2/Treasury.sol#L91


 - [ ] ID-362
Variable [GemFactoryStorage.s_requests](src/L2/GemFactoryStorage.sol#L59) is not in mixedCase

src/L2/GemFactoryStorage.sol#L59


 - [ ] ID-363
Parameter [Candidate.initialize(address,bool,string,address,address)._isLayer2Candidate](src/L1/Mock/Candidate.sol#L55) is not in mixedCase

src/L1/Mock/Candidate.sol#L55


 - [ ] ID-364
Parameter [Candidate.castVote(uint256,uint256,string)._comment](src/L1/Mock/Candidate.sol#L126) is not in mixedCase

src/L1/Mock/Candidate.sol#L126


 - [ ] ID-365
Parameter [Treasury.createPreminedGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._color](src/L2/Treasury.sol#L77) is not in mixedCase

src/L2/Treasury.sol#L77


 - [ ] ID-366
Parameter [Candidate.initialize(address,bool,string,address,address)._candidate](src/L1/Mock/Candidate.sol#L54) is not in mixedCase

src/L1/Mock/Candidate.sol#L54


 - [ ] ID-367
Parameter [Candidate.setMemo(string)._memo](src/L1/Mock/Candidate.sol#L88) is not in mixedCase

src/L1/Mock/Candidate.sol#L88


 - [ ] ID-368
Parameter [MarketPlace.buyGem(uint256,bool)._tokenId](src/L2/MarketPlace.sol#L60) is not in mixedCase

src/L2/MarketPlace.sol#L60


 - [ ] ID-369
Parameter [GemFactory.setminingTrys(uint256,uint256,uint256,uint256,uint256,uint256)._UniqueminingTry](src/L2/GemFactory.sol#L143) is not in mixedCase

src/L2/GemFactory.sol#L143


 - [ ] ID-370
Parameter [ProxyGemFactory.setSelectorImplementations2(bytes4[],address)._selectors](src/proxy/ProxyGemFactory.sol#L59) is not in mixedCase

src/proxy/ProxyGemFactory.sol#L59


 - [ ] ID-371
Parameter [L1WrappedStakedTON.claimWithdrawalTo(address)._to](src/L1/L1WrappedStakedTON.sol#L158) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L158


 - [ ] ID-372
Parameter [GemFactory.adminTransferGEM(address,uint256)._to](src/L2/GemFactory.sol#L811) is not in mixedCase

src/L2/GemFactory.sol#L811


 - [ ] ID-373
Parameter [GemFactory.claimMinedGEM(uint256)._tokenId](src/L2/GemFactory.sol#L396) is not in mixedCase

src/L2/GemFactory.sol#L396


 - [ ] ID-374
Parameter [GemFactory.addColor(string)._color](src/L2/GemFactory.sol#L828) is not in mixedCase

src/L2/GemFactory.sol#L828


 - [ ] ID-375
Parameter [ProxyL1WrappedStakedTON.getSelectorImplementation2(bytes4)._selector](src/proxy/ProxyL1WrappedStakedTON.sol#L93) is not in mixedCase

src/proxy/ProxyL1WrappedStakedTON.sol#L93


 - [ ] ID-376
Parameter [GemFactory.setIsLocked(uint256,bool)._tokenId](src/L2/GemFactory.sol#L824) is not in mixedCase

src/L2/GemFactory.sol#L824


 - [ ] ID-377
Parameter [Treasury.transferWSTON(address,uint256)._to](src/L2/Treasury.sol#L66) is not in mixedCase

src/L2/Treasury.sol#L66


 - [ ] ID-378
Parameter [L2StandardERC20.burn(address,uint256)._amount](src/L2/Mock/L2StandardERC20.sol#L53) is not in mixedCase

src/L2/Mock/L2StandardERC20.sol#L53


 - [ ] ID-379
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._CommonGemsValue](src/L2/GemFactory.sol#L87) is not in mixedCase

src/L2/GemFactory.sol#L87


 - [ ] ID-380
Variable [GemFactoryStorage.EpicGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L81) is not in mixedCase

src/L2/GemFactoryStorage.sol#L81


 - [ ] ID-381
Parameter [GemFactory.setIsLocked(uint256,bool)._isLocked](src/L2/GemFactory.sol#L824) is not in mixedCase

src/L2/GemFactory.sol#L824


 - [ ] ID-382
Parameter [MarketPlace.buyGem(uint256,bool)._paymentMethod](src/L2/MarketPlace.sol#L60) is not in mixedCase

src/L2/MarketPlace.sol#L60


 - [ ] ID-383
Parameter [MockTON.supportsInterface(bytes4)._interfaceId](src/L2/Mock/MockTON.sol#L33) is not in mixedCase

src/L2/Mock/MockTON.sol#L33


 - [ ] ID-384
Parameter [GemFactory.setGemsCooldownPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._RareGemsCooldownPeriod](src/L2/GemFactory.sol#L126) is not in mixedCase

src/L2/GemFactory.sol#L126


 - [ ] ID-385
Parameter [GemFactory.burnToken(address,uint256)._from](src/L2/GemFactory.sol#L440) is not in mixedCase

src/L2/GemFactory.sol#L440


 - [ ] ID-386
Parameter [L2StandardERC20.burn(address,uint256)._from](src/L2/Mock/L2StandardERC20.sol#L53) is not in mixedCase

src/L2/Mock/L2StandardERC20.sol#L53


 - [ ] ID-387
Parameter [GemFactory.setTokenURI(uint256,string)._tokenURI](src/L2/GemFactory.sol#L850) is not in mixedCase

src/L2/GemFactory.sol#L850


 - [ ] ID-388
Parameter [Candidate.castVote(uint256,uint256,string)._agendaID](src/L1/Mock/Candidate.sol#L124) is not in mixedCase

src/L1/Mock/Candidate.sol#L124


 - [ ] ID-389
Parameter [MarketPlace.setDiscountRate(uint256)._tonFeesRate](src/L2/MarketPlace.sol#L87) is not in mixedCase

src/L2/MarketPlace.sol#L87


 - [ ] ID-390
Parameter [Treasury.createPreminedGEM(GemFactoryStorage.Rarity,uint8[2],uint8[4],string)._quadrants](src/L2/Treasury.sol#L78) is not in mixedCase

src/L2/Treasury.sol#L78


 - [ ] ID-391
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._treasury](src/L2/GemFactory.sol#L86) is not in mixedCase

src/L2/GemFactory.sol#L86


 - [ ] ID-392
Parameter [GemFactory.setGemsMiningPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._LegendaryGemsMiningPeriod](src/L2/GemFactory.sol#L113) is not in mixedCase

src/L2/GemFactory.sol#L113


 - [ ] ID-393
Variable [GemFactoryStorage.Gems](src/L2/GemFactoryStorage.sol#L38) is not in mixedCase

src/L2/GemFactoryStorage.sol#L38


 - [ ] ID-394
Parameter [L1WrappedStakedTON.setSeigManagerAddress(address)._seigManager](src/L1/L1WrappedStakedTON.sol#L218) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L218


 - [ ] ID-395
Parameter [GemFactory.setNumberOfSolidColors(uint8)._numberOfSolidColors](src/L2/GemFactory.sol#L846) is not in mixedCase

src/L2/GemFactory.sol#L846


 - [ ] ID-396
Parameter [MockTON.burn(address,uint256)._amount](src/L2/Mock/MockTON.sol#L53) is not in mixedCase

src/L2/Mock/MockTON.sol#L53


 - [ ] ID-397
Function [SeigManager.DEFAULT_FACTOR()](src/L1/Mock/SeigManager.sol#L790) is not in mixedCase

src/L1/Mock/SeigManager.sol#L790


 - [ ] ID-398
Variable [GemFactoryStorage.RareminingTry](src/L2/GemFactoryStorage.sol#L65) is not in mixedCase

src/L2/GemFactoryStorage.sol#L65


 - [ ] ID-399
Parameter [GemFactory.setminingTrys(uint256,uint256,uint256,uint256,uint256,uint256)._MythicminingTry](src/L2/GemFactory.sol#L146) is not in mixedCase

src/L2/GemFactory.sol#L146


 - [ ] ID-400
Parameter [GemFactory.setGemsValue(uint256,uint256,uint256,uint256,uint256,uint256)._LegendaryGemsValue](src/L2/GemFactory.sol#L161) is not in mixedCase

src/L2/GemFactory.sol#L161


 - [ ] ID-401
Parameter [GemFactory.burnToken(address,uint256)._tokenId](src/L2/GemFactory.sol#L440) is not in mixedCase

src/L2/GemFactory.sol#L440


 - [ ] ID-402
Parameter [L1WrappedStakedTONFactory.createWSTONToken(address,address,address,string,string)._layer2Address](src/L1/L1WrappedStakedTONFactory.sol#L18) is not in mixedCase

src/L1/L1WrappedStakedTONFactory.sol#L18


 - [ ] ID-403
Parameter [ProxyGemFactory.getSelectorImplementation2(bytes4)._selector](src/proxy/ProxyGemFactory.sol#L93) is not in mixedCase

src/proxy/ProxyGemFactory.sol#L93


 - [ ] ID-404
Variable [GemFactoryStorage.CommonGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L78) is not in mixedCase

src/L2/GemFactoryStorage.sol#L78


 - [ ] ID-405
Parameter [ProxyL1WrappedStakedTON.implementation2(uint256)._index](src/proxy/ProxyL1WrappedStakedTON.sol#L86) is not in mixedCase

src/proxy/ProxyL1WrappedStakedTON.sol#L86


 - [ ] ID-406
Parameter [Candidate.setCommittee(address)._committee](src/L1/Mock/Candidate.sol#L81) is not in mixedCase

src/L1/Mock/Candidate.sol#L81


 - [ ] ID-407
Parameter [MarketPlace.initialize(address,address,uint256,address,address)._wston](src/L2/MarketPlace.sol#L40) is not in mixedCase

src/L2/MarketPlace.sol#L40


 - [ ] ID-408
Parameter [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])._color](src/L2/GemFactory.sol#L187) is not in mixedCase

src/L2/GemFactory.sol#L187


 - [ ] ID-409
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._wston](src/L2/GemFactory.sol#L84) is not in mixedCase

src/L2/GemFactory.sol#L84


 - [ ] ID-410
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._EpicGemsValue](src/L2/GemFactory.sol#L90) is not in mixedCase

src/L2/GemFactory.sol#L90


 - [ ] ID-411
Parameter [ProxyCoinage.setImplementation2(address,uint256,bool)._index](src/L1/Mock/proxy/ProxyCoinage.sol#L48) is not in mixedCase

src/L1/Mock/proxy/ProxyCoinage.sol#L48


 - [ ] ID-412
Parameter [ProxyCoinage.setAliveImplementation2(address,bool)._alive](src/L1/Mock/proxy/ProxyCoinage.sol#L55) is not in mixedCase

src/L1/Mock/proxy/ProxyCoinage.sol#L55


 - [ ] ID-413
Parameter [ProxyCoinage.setSelectorImplementations2(bytes4[],address)._imp](src/L1/Mock/proxy/ProxyCoinage.sol#L64) is not in mixedCase

src/L1/Mock/proxy/ProxyCoinage.sol#L64


 - [ ] ID-414
Parameter [GemFactory.getRandomRequest(uint256)._requestId](src/L2/GemFactory.sol#L1069) is not in mixedCase

src/L2/GemFactory.sol#L1069


 - [ ] ID-415
Parameter [GemFactory.setGemsValue(uint256,uint256,uint256,uint256,uint256,uint256)._CommonGemsValue](src/L2/GemFactory.sol#L157) is not in mixedCase

src/L2/GemFactory.sol#L157


 - [ ] ID-416
Variable [GemFactoryStorage.RareGemsValue](src/L2/GemFactoryStorage.sol#L72) is not in mixedCase

src/L2/GemFactoryStorage.sol#L72


 - [ ] ID-417
Parameter [L1WrappedStakedTON.requestWithdrawalTo(address,uint256)._to](src/L1/L1WrappedStakedTON.sol#L126) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L126


 - [ ] ID-418
Variable [GemFactoryStorage.UniqueGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L80) is not in mixedCase

src/L2/GemFactoryStorage.sol#L80


 - [ ] ID-419
Parameter [ProxyL1WrappedStakedTON.setSelectorImplementations2(bytes4[],address)._imp](src/proxy/ProxyL1WrappedStakedTON.sol#L60) is not in mixedCase

src/proxy/ProxyL1WrappedStakedTON.sol#L60


 - [ ] ID-420
Parameter [DRBCoordinatorMock.estimateDirectFundingPrice(uint256,IDRBCoordinator.RandomWordsRequest)._request](src/L2/Mock/DRBCoordinatorMock.sol#L124) is not in mixedCase

src/L2/Mock/DRBCoordinatorMock.sol#L124


 - [ ] ID-421
Parameter [GemFactory.meltGEM(uint256)._tokenId](src/L2/GemFactory.sol#L430) is not in mixedCase

src/L2/GemFactory.sol#L430


 - [ ] ID-422
Function [IERC20Permit.DOMAIN_SEPARATOR()](lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol#L89) is not in mixedCase

lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol#L89


 - [ ] ID-423
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._RareGemsValue](src/L2/GemFactory.sol#L88) is not in mixedCase

src/L2/GemFactory.sol#L88


 - [ ] ID-424
Parameter [GemFactory.setGemsCooldownPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._EpicGemsCooldownPeriod](src/L2/GemFactory.sol#L128) is not in mixedCase

src/L2/GemFactory.sol#L128


 - [ ] ID-425
Parameter [L1WrappedStakedTONFactory.createWSTONToken(address,address,address,string,string)._name](src/L1/L1WrappedStakedTONFactory.sol#L21) is not in mixedCase

src/L1/L1WrappedStakedTONFactory.sol#L21


 - [ ] ID-426
Parameter [GemFactory.setGemsCooldownPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._MythicGemsCooldownPeriod](src/L2/GemFactory.sol#L130) is not in mixedCase

src/L2/GemFactory.sol#L130


 - [ ] ID-427
Parameter [GemFactory.burnTokens(address,uint256[])._tokenIds](src/L2/GemFactory.sol#L451) is not in mixedCase

src/L2/GemFactory.sol#L451


 - [ ] ID-428
Parameter [ProxyL1WrappedStakedTON.setSelectorImplementations2(bytes4[],address)._selectors](src/proxy/ProxyL1WrappedStakedTON.sol#L59) is not in mixedCase

src/proxy/ProxyL1WrappedStakedTON.sol#L59


 - [ ] ID-429
Parameter [ProxyGemFactory.setImplementation2(address,uint256,bool)._index](src/proxy/ProxyGemFactory.sol#L43) is not in mixedCase

src/proxy/ProxyGemFactory.sol#L43


 - [ ] ID-430
Parameter [Candidate.setSeigManager(address)._seigManager](src/L1/Mock/Candidate.sol#L74) is not in mixedCase

src/L1/Mock/Candidate.sol#L74


 - [ ] ID-431
Parameter [RefactorCoinageSnapshot.applyFactor(IRefactor.Balance)._balance](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L249) is not in mixedCase

src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L249


 - [ ] ID-432
Parameter [MarketPlace.putGemForSale(uint256,uint256)._tokenId](src/L2/MarketPlace.sol#L69) is not in mixedCase

src/L2/MarketPlace.sol#L69


 - [ ] ID-433
Parameter [GemFactory.forgeTokens(uint256[],GemFactoryStorage.Rarity,uint8[2])._rarity](src/L2/GemFactory.sol#L186) is not in mixedCase

src/L2/GemFactory.sol#L186


 - [ ] ID-434
Parameter [ProxyL1WrappedStakedTON.setProxyPause(bool)._pause](src/proxy/ProxyL1WrappedStakedTON.sol#L27) is not in mixedCase

src/proxy/ProxyL1WrappedStakedTON.sol#L27


 - [ ] ID-435
Function [SeigManagerI.DEFAULT_FACTOR()](src/L1/Mock/interfaces/SeigManagerI.sol#L20) is not in mixedCase

src/L1/Mock/interfaces/SeigManagerI.sol#L20


 - [ ] ID-436
Variable [OptimismL1Fees.s_l1FeeCalculationMode](src/L2/Mock/OptimismL1Fees.sol#L30) is not in mixedCase

src/L2/Mock/OptimismL1Fees.sol#L30


 - [ ] ID-437
Parameter [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._colors](src/L2/GemFactory.sol#L605) is not in mixedCase

src/L2/GemFactory.sol#L605


 - [ ] ID-438
Parameter [Treasury.setGemFactory(address)._gemFactory](src/L2/Treasury.sol#L46) is not in mixedCase

src/L2/Treasury.sol#L46


 - [ ] ID-439
Parameter [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._tokenURIs](src/L2/GemFactory.sol#L607) is not in mixedCase

src/L2/GemFactory.sol#L607


 - [ ] ID-440
Parameter [ProxyGemFactory.setImplementation2(address,uint256,bool)._alive](src/proxy/ProxyGemFactory.sol#L44) is not in mixedCase

src/proxy/ProxyGemFactory.sol#L44


 - [ ] ID-441
Variable [GemFactoryStorage.UniqueminingTry](src/L2/GemFactoryStorage.sol#L66) is not in mixedCase

src/L2/GemFactoryStorage.sol#L66


 - [ ] ID-442
Parameter [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._rarities](src/L2/GemFactory.sol#L604) is not in mixedCase

src/L2/GemFactory.sol#L604


 - [ ] ID-443
Variable [GemFactoryStorage.LegendaryGemsValue](src/L2/GemFactoryStorage.sol#L75) is not in mixedCase

src/L2/GemFactoryStorage.sol#L75


 - [ ] ID-444
Parameter [Candidate.stakedOf(address)._account](src/L1/Mock/Candidate.sol#L180) is not in mixedCase

src/L1/Mock/Candidate.sol#L180


 - [ ] ID-445
Variable [GemFactoryStorage.CommonGemsValue](src/L2/GemFactoryStorage.sol#L71) is not in mixedCase

src/L2/GemFactoryStorage.sol#L71


 - [ ] ID-446
Parameter [L1WrappedStakedTON.depositAndGetWSTONTo(address,uint256)._to](src/L1/L1WrappedStakedTON.sol#L68) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L68


 - [ ] ID-447
Parameter [L1WrappedStakedTON.requestWithdrawal(uint256)._wstonAmount](src/L1/L1WrappedStakedTON.sol#L121) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L121


 - [ ] ID-448
Parameter [L2StandardERC20.mint(address,uint256)._amount](src/L2/Mock/L2StandardERC20.sol#L46) is not in mixedCase

src/L2/Mock/L2StandardERC20.sol#L46


 - [ ] ID-449
Parameter [GemFactory.setGemsCooldownPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._UniqueGemsCooldownPeriod](src/L2/GemFactory.sol#L127) is not in mixedCase

src/L2/GemFactory.sol#L127


 - [ ] ID-450
Parameter [ProxyCoinage.getSelectorImplementation2(bytes4)._selector](src/L1/Mock/proxy/ProxyCoinage.sol#L100) is not in mixedCase

src/L1/Mock/proxy/ProxyCoinage.sol#L100


 - [ ] ID-451
Parameter [L1WrappedStakedTONFactory.createWSTONToken(address,address,address,string,string)._depositManager](src/L1/L1WrappedStakedTONFactory.sol#L19) is not in mixedCase

src/L1/L1WrappedStakedTONFactory.sol#L19


 - [ ] ID-452
Parameter [Candidate.changeMember(uint256)._memberIndex](src/L1/Mock/Candidate.sol#L105) is not in mixedCase

src/L1/Mock/Candidate.sol#L105


 - [ ] ID-453
Parameter [L1WrappedStakedTON.depositAndGetWSTONTo(address,uint256)._amount](src/L1/L1WrappedStakedTON.sol#L69) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L69


 - [ ] ID-454
Variable [OptimismL1Fees.s_l1FeeCoefficient](src/L2/Mock/OptimismL1Fees.sol#L33) is not in mixedCase

src/L2/Mock/OptimismL1Fees.sol#L33


 - [ ] ID-455
Function [IOVM_GasPriceOracle.DECIMALS()](src/L2/Mock/IOVM_GasPriceOracle.sol#L15) is not in mixedCase

src/L2/Mock/IOVM_GasPriceOracle.sol#L15


 - [ ] ID-456
Parameter [GemFactory.createGEMPool(GemFactoryStorage.Rarity[],uint8[2][],uint8[4][],string[])._quadrants](src/L2/GemFactory.sol#L606) is not in mixedCase

src/L2/GemFactory.sol#L606


 - [ ] ID-457
Parameter [IDAOCommittee.castVote(uint256,uint256,string)._AgendaID](src/L1/Mock/interfaces/IDAOCommittee.sol#L42) is not in mixedCase

src/L1/Mock/interfaces/IDAOCommittee.sol#L42


 - [ ] ID-458
Parameter [MarketPlace.putGemForSale(uint256,uint256)._price](src/L2/MarketPlace.sol#L69) is not in mixedCase

src/L2/MarketPlace.sol#L69


 - [ ] ID-459
Variable [GemFactoryStorage.RareGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L86) is not in mixedCase

src/L2/GemFactoryStorage.sol#L86


 - [ ] ID-460
Parameter [GemFactory.setMarketPlaceAddress(address)._marketplace](src/L2/GemFactory.sol#L816) is not in mixedCase

src/L2/GemFactory.sol#L816


 - [ ] ID-461
Parameter [GemFactory.initialize(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)._ton](src/L2/GemFactory.sol#L85) is not in mixedCase

src/L2/GemFactory.sol#L85


 - [ ] ID-462
Parameter [IDAOCommittee.executeAgenda(uint256)._AgendaID](src/L1/Mock/interfaces/IDAOCommittee.sol#L44) is not in mixedCase

src/L1/Mock/interfaces/IDAOCommittee.sol#L44


 - [ ] ID-463
Variable [GemFactoryStorage.EpicGemsValue](src/L2/GemFactoryStorage.sol#L74) is not in mixedCase

src/L2/GemFactoryStorage.sol#L74


 - [ ] ID-464
Variable [GemFactoryStorage.LegendaryminingTry](src/L2/GemFactoryStorage.sol#L68) is not in mixedCase

src/L2/GemFactoryStorage.sol#L68


 - [ ] ID-465
Variable [MarketPlaceStorage._treasury](src/L2/MarketPlaceStorage.sol#L18) is not in mixedCase

src/L2/MarketPlaceStorage.sol#L18


 - [ ] ID-466
Variable [GemFactoryStorage.UniqueGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L87) is not in mixedCase

src/L2/GemFactoryStorage.sol#L87


 - [ ] ID-467
Parameter [Treasury.transferWSTON(address,uint256)._amount](src/L2/Treasury.sol#L66) is not in mixedCase

src/L2/Treasury.sol#L66


 - [ ] ID-468
Variable [GemFactoryStorage.LegendaryGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L89) is not in mixedCase

src/L2/GemFactoryStorage.sol#L89


 - [ ] ID-469
Parameter [GemFactory.balanceOf(address)._owner](src/L2/GemFactory.sol#L992) is not in mixedCase

src/L2/GemFactory.sol#L992


 - [ ] ID-470
Variable [GemFactoryStorage.GEMIndexToOwner](src/L2/GemFactoryStorage.sol#L49) is not in mixedCase

src/L2/GemFactoryStorage.sol#L49


 - [ ] ID-471
Variable [GemFactoryStorage.MythicGemsValue](src/L2/GemFactoryStorage.sol#L76) is not in mixedCase

src/L2/GemFactoryStorage.sol#L76


 - [ ] ID-472
Parameter [L1WrappedStakedTONFactory.createWSTONToken(address,address,address,string,string)._symbol](src/L1/L1WrappedStakedTONFactory.sol#L22) is not in mixedCase

src/L1/L1WrappedStakedTONFactory.sol#L22


 - [ ] ID-473
Variable [GemFactoryStorage.MythicGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L90) is not in mixedCase

src/L2/GemFactoryStorage.sol#L90


 - [ ] ID-474
Variable [GemFactoryStorage.CommonminingTry](src/L2/GemFactoryStorage.sol#L64) is not in mixedCase

src/L2/GemFactoryStorage.sol#L64


 - [ ] ID-475
Variable [GemFactoryStorage.LegendaryGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L82) is not in mixedCase

src/L2/GemFactoryStorage.sol#L82


 - [ ] ID-476
Parameter [DRBCoordinatorMock.calculateDirectFundingPrice(IDRBCoordinator.RandomWordsRequest)._request](src/L2/Mock/DRBCoordinatorMock.sol#L117) is not in mixedCase

src/L2/Mock/DRBCoordinatorMock.sol#L117


 - [ ] ID-477
Parameter [GemFactory.setGemsValue(uint256,uint256,uint256,uint256,uint256,uint256)._RareGemsValue](src/L2/GemFactory.sol#L158) is not in mixedCase

src/L2/GemFactory.sol#L158


 - [ ] ID-478
Variable [RefactorCoinageSnapshotStorage._allowances](src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L18) is not in mixedCase

src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L18


 - [ ] ID-479
Parameter [ProxyL1WrappedStakedTON.setImplementation2(address,uint256,bool)._alive](src/proxy/ProxyL1WrappedStakedTON.sol#L44) is not in mixedCase

src/proxy/ProxyL1WrappedStakedTON.sol#L44


 - [ ] ID-480
Parameter [GemFactory.setGemsValue(uint256,uint256,uint256,uint256,uint256,uint256)._UniqueGemsValue](src/L2/GemFactory.sol#L159) is not in mixedCase

src/L2/GemFactory.sol#L159


 - [ ] ID-481
Variable [GemFactoryStorage.EpicminingTry](src/L2/GemFactoryStorage.sol#L67) is not in mixedCase

src/L2/GemFactoryStorage.sol#L67


 - [ ] ID-482
Parameter [L2StandardERC20.supportsInterface(bytes4)._interfaceId](src/L2/Mock/L2StandardERC20.sol#L33) is not in mixedCase

src/L2/Mock/L2StandardERC20.sol#L33


 - [ ] ID-483
Parameter [GemFactory.setGemsMiningPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._MythicGemsMiningPeriod](src/L2/GemFactory.sol#L114) is not in mixedCase

src/L2/GemFactory.sol#L114


 - [ ] ID-484
Parameter [MockTON.mint(address,uint256)._to](src/L2/Mock/MockTON.sol#L46) is not in mixedCase

src/L2/Mock/MockTON.sol#L46


 - [ ] ID-485
Parameter [MarketPlace.initialize(address,address,uint256,address,address)._tonFeesRate](src/L2/MarketPlace.sol#L39) is not in mixedCase

src/L2/MarketPlace.sol#L39


 - [ ] ID-486
Parameter [GemFactory.setGemsMiningPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._EpicGemsMiningPeriod](src/L2/GemFactory.sol#L112) is not in mixedCase

src/L2/GemFactory.sol#L112


 - [ ] ID-487
Parameter [ProxyL1WrappedStakedTON.setImplementation2(address,uint256,bool)._index](src/proxy/ProxyL1WrappedStakedTON.sol#L43) is not in mixedCase

src/proxy/ProxyL1WrappedStakedTON.sol#L43


 - [ ] ID-488
Parameter [ProxyCoinage.setImplementation2(address,uint256,bool)._alive](src/L1/Mock/proxy/ProxyCoinage.sol#L49) is not in mixedCase

src/L1/Mock/proxy/ProxyCoinage.sol#L49


 - [ ] ID-489
Parameter [GemFactory.getCustomColor(uint8)._index](src/L2/GemFactory.sol#L1073) is not in mixedCase

src/L2/GemFactory.sol#L1073


 - [ ] ID-490
Parameter [L1WrappedStakedTON.getDepositWstonAmount(uint256)._amount](src/L1/L1WrappedStakedTON.sol#L208) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L208


 - [ ] ID-491
Parameter [GemFactory.setGemsCooldownPeriods(uint256,uint256,uint256,uint256,uint256,uint256)._CommonGemsCooldownPeriod](src/L2/GemFactory.sol#L125) is not in mixedCase

src/L2/GemFactory.sol#L125


 - [ ] ID-492
Parameter [ProxyCoinage.implementation2(uint256)._index](src/L1/Mock/proxy/ProxyCoinage.sol#L94) is not in mixedCase

src/L1/Mock/proxy/ProxyCoinage.sol#L94


 - [ ] ID-493
Parameter [MockTON.burn(address,uint256)._from](src/L2/Mock/MockTON.sol#L53) is not in mixedCase

src/L2/Mock/MockTON.sol#L53


 - [ ] ID-494
Parameter [GemFactory.adminTransferGEM(address,uint256)._tokenId](src/L2/GemFactory.sol#L811) is not in mixedCase

src/L2/GemFactory.sol#L811


 - [ ] ID-495
Parameter [GemFactory.getGem(uint256)._tokenId](src/L2/GemFactory.sol#L1108) is not in mixedCase

src/L2/GemFactory.sol#L1108


 - [ ] ID-496
Parameter [RefactorCoinageSnapshot.setSeigManager(address)._seigManager](src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L78) is not in mixedCase

src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#L78


 - [ ] ID-497
Parameter [Candidate.initialize(address,bool,string,address,address)._committee](src/L1/Mock/Candidate.sol#L57) is not in mixedCase

src/L1/Mock/Candidate.sol#L57


 - [ ] ID-498
Parameter [L1WrappedStakedTON.requestWithdrawalTo(address,uint256)._wstonAmount](src/L1/L1WrappedStakedTON.sol#L126) is not in mixedCase

src/L1/L1WrappedStakedTON.sol#L126


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-499
[SeigManager.totalSupplyOfTon()](src/L1/Mock/SeigManager.sol#L819-L822) uses literals with too many digits:
	- [tos = 50000000000000000000000000000000000 - 178111666909855730000000000000000](src/L1/Mock/SeigManager.sol#L821)

src/L1/Mock/SeigManager.sol#L819-L822


 - [ ] ID-500
[MockToken.constructor(string,string,uint8)](src/L1/Mock/MockToken.sol#L8-L10) uses literals with too many digits:
	- [_mint(msg.sender,10000000 * 10 ** uint256(decimals_))](src/L1/Mock/MockToken.sol#L9)

src/L1/Mock/MockToken.sol#L8-L10


## unused-import
Impact: Informational
Confidence: High
 - [ ] ID-501
The following unused import(s) in src/L1/Mock/proxy/RefactorCoinageSnapshot.sol should be removed:
	-import { AutoRefactorCoinageI } from "../interfaces/AutoRefactorCoinageI.sol"; (src/L1/Mock/proxy/RefactorCoinageSnapshot.sol#5)

 - [ ] ID-502
The following unused import(s) in src/proxy/ProxyL1WrappedStakedTON.sol should be removed:
	-import {Address} from "@openzeppelin/contracts/utils/Address.sol"; (src/proxy/ProxyL1WrappedStakedTON.sol#9)

 - [ ] ID-503
The following unused import(s) in src/L1/Mock/SeigManager.sol should be removed:
	-import { IRefactor } from "./interfaces/IRefactor.sol"; (src/L1/Mock/SeigManager.sol#4)

 - [ ] ID-504
The following unused import(s) in src/L1/Mock/Candidate.sol should be removed:
	-import { Layer2RegistryI } from "./interfaces/Layer2RegistryI.sol"; (src/L1/Mock/Candidate.sol#9)

	-import "@openzeppelin/contracts/access/Ownable.sol"; (src/L1/Mock/Candidate.sol#4)

	-import { ICandidate } from "./interfaces/ICandidate.sol"; (src/L1/Mock/Candidate.sol#7)

 - [ ] ID-505
The following unused import(s) in src/proxy/ProxyGemFactory.sol should be removed:
	-import {Address} from "@openzeppelin/contracts/utils/Address.sol"; (src/proxy/ProxyGemFactory.sol#9)

 - [ ] ID-506
The following unused import(s) in src/L1/Mock/proxy/ProxyCoinage.sol should be removed:
	-import {Address} from "@openzeppelin/contracts/utils/Address.sol"; (src/L1/Mock/proxy/ProxyCoinage.sol#6)

## unused-state
Impact: Informational
Confidence: High
 - [ ] ID-507
[L1WrappedStakedTONStorage.paused](src/L1/L1WrappedStakedTONStorage.sol#L13) is never used in [L1WrappedStakedTONProxy](src/L1/L1WrappedStakedTONProxy.sol#L11-L14)

src/L1/L1WrappedStakedTONStorage.sol#L13


 - [ ] ID-508
[L1WrappedStakedTONStorage.withdrawalRequestIndex](src/L1/L1WrappedStakedTONStorage.sol#L26) is never used in [L1WrappedStakedTONProxy](src/L1/L1WrappedStakedTONProxy.sol#L11-L14)

src/L1/L1WrappedStakedTONStorage.sol#L26


## cache-array-length
Impact: Optimization
Confidence: High
 - [ ] ID-509
Loop condition [i < Gems.length](src/L2/GemFactory.sol#L1085) should use cached array length instead of referencing `length` member of the storage array.
 
src/L2/GemFactory.sol#L1085


## constable-states
Impact: Optimization
Confidence: High
 - [ ] ID-510
[GemFactoryStorage.EpicGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L88) should be constant 

src/L2/GemFactoryStorage.sol#L88


 - [ ] ID-511
[L1WrappedStakedTONStorage.seigManager](src/L1/L1WrappedStakedTONStorage.sol#L18) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L18


 - [ ] ID-512
[GemFactoryStorage.requestCount](src/L2/GemFactoryStorage.sol#L94) should be constant 

src/L2/GemFactoryStorage.sol#L94


 - [ ] ID-513
[GemFactoryStorage.ton](src/L2/GemFactoryStorage.sol#L101) should be constant 

src/L2/GemFactoryStorage.sol#L101


 - [ ] ID-514
[L1WrappedStakedTONStorage.totalStakedAmount](src/L1/L1WrappedStakedTONStorage.sol#L20) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L20


 - [ ] ID-515
[L1WrappedStakedTONStorage.paused](src/L1/L1WrappedStakedTONStorage.sol#L13) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L13


 - [ ] ID-516
[GemFactoryStorage.LegendaryGemsValue](src/L2/GemFactoryStorage.sol#L75) should be constant 

src/L2/GemFactoryStorage.sol#L75


 - [ ] ID-517
[GemFactoryStorage.UniqueminingTry](src/L2/GemFactoryStorage.sol#L66) should be constant 

src/L2/GemFactoryStorage.sol#L66


 - [ ] ID-518
[GemFactoryStorage.numberOfSolidColors](src/L2/GemFactoryStorage.sol#L97) should be constant 

src/L2/GemFactoryStorage.sol#L97


 - [ ] ID-519
[GemFactoryStorage.treasury](src/L2/GemFactoryStorage.sol#L102) should be constant 

src/L2/GemFactoryStorage.sol#L102


 - [ ] ID-520
[GemFactoryStorage.wston](src/L2/GemFactoryStorage.sol#L100) should be constant 

src/L2/GemFactoryStorage.sol#L100


 - [ ] ID-521
[GemFactoryStorage.drbcoordinator](src/L2/GemFactoryStorage.sol#L104) should be constant 

src/L2/GemFactoryStorage.sol#L104


 - [ ] ID-522
[GemFactoryStorage.EpicGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L81) should be constant 

src/L2/GemFactoryStorage.sol#L81


 - [ ] ID-523
[ProxyStorage.pauseProxy](src/proxy/ProxyStorage.sol#L5) should be constant 

src/proxy/ProxyStorage.sol#L5


 - [ ] ID-524
[L1WrappedStakedTONStorage.totalWstonMinted](src/L1/L1WrappedStakedTONStorage.sol#L21) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L21


 - [ ] ID-525
[DepositManagerStorage.oldDepositManager](src/L1/Mock/DepositManagerStorage.sol#L14) should be constant 

src/L1/Mock/DepositManagerStorage.sol#L14


 - [ ] ID-526
[GemFactoryStorage.UniqueGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L80) should be constant 

src/L2/GemFactoryStorage.sol#L80


 - [ ] ID-527
[GemFactoryStorage.customColorsCount](src/L2/GemFactoryStorage.sol#L40) should be constant 

src/L2/GemFactoryStorage.sol#L40


 - [ ] ID-528
[Treasury.paused](src/L2/Treasury.sol#L20) should be constant 

src/L2/Treasury.sol#L20


 - [ ] ID-529
[GemFactoryStorage.customBackgroundColorsCount](src/L2/GemFactoryStorage.sol#L44) should be constant 

src/L2/GemFactoryStorage.sol#L44


 - [ ] ID-530
[GemFactoryStorage.CommonGemsValue](src/L2/GemFactoryStorage.sol#L71) should be constant 

src/L2/GemFactoryStorage.sol#L71


 - [ ] ID-531
[RefactorCoinageSnapshotStorage.lastSnapshotId](src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L30) should be constant 

src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L30


 - [ ] ID-532
[RefactorCoinageSnapshotStorage.symbol](src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L16) should be constant 

src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L16


 - [ ] ID-533
[L1WrappedStakedTONStorage.wton](src/L1/L1WrappedStakedTONStorage.sol#L16) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L16


 - [ ] ID-534
[GemFactoryStorage.CommonminingTry](src/L2/GemFactoryStorage.sol#L64) should be constant 

src/L2/GemFactoryStorage.sol#L64


 - [ ] ID-535
[GemFactoryStorage.LegendaryGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L82) should be constant 

src/L2/GemFactoryStorage.sol#L82


 - [ ] ID-536
[L1WrappedStakedTONStorage.stakingIndex](src/L1/L1WrappedStakedTONStorage.sol#L22) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L22


 - [ ] ID-537
[GemFactoryStorage.marketplace](src/L2/GemFactoryStorage.sol#L103) should be constant 

src/L2/GemFactoryStorage.sol#L103


 - [ ] ID-538
[GemFactoryStorage.MythicminingTry](src/L2/GemFactoryStorage.sol#L69) should be constant 

src/L2/GemFactoryStorage.sol#L69


 - [ ] ID-539
[RefactorCoinageSnapshotStorage.name](src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L15) should be constant 

src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L15


 - [ ] ID-540
[GemFactoryStorage.UniqueGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L87) should be constant 

src/L2/GemFactoryStorage.sol#L87


 - [ ] ID-541
[RefactorCoinageSnapshotStorage.seigManager](src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L12) should be constant 

src/L1/Mock/proxy/RefactorCoinageSnapshotStorage.sol#L12


 - [ ] ID-542
[GemFactoryStorage.RareGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L79) should be constant 

src/L2/GemFactoryStorage.sol#L79


 - [ ] ID-543
[GemFactoryStorage.MythicGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L83) should be constant 

src/L2/GemFactoryStorage.sol#L83


 - [ ] ID-544
[L1WrappedStakedTONStorage.depositManager](src/L1/L1WrappedStakedTONStorage.sol#L17) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L17


 - [ ] ID-545
[GemFactoryStorage.RareminingTry](src/L2/GemFactoryStorage.sol#L65) should be constant 

src/L2/GemFactoryStorage.sol#L65


 - [ ] ID-546
[GemFactoryStorage.EpicGemsValue](src/L2/GemFactoryStorage.sol#L74) should be constant 

src/L2/GemFactoryStorage.sol#L74


 - [ ] ID-547
[GemFactoryStorage.UniqueGemsValue](src/L2/GemFactoryStorage.sol#L73) should be constant 

src/L2/GemFactoryStorage.sol#L73


 - [ ] ID-548
[GemFactoryStorage.RareGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L86) should be constant 

src/L2/GemFactoryStorage.sol#L86


 - [ ] ID-549
[GemFactoryStorage.MythicGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L90) should be constant 

src/L2/GemFactoryStorage.sol#L90


 - [ ] ID-550
[L1WrappedStakedTONStorage.lastSeigBlock](src/L1/L1WrappedStakedTONStorage.sol#L23) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L23


 - [ ] ID-551
[GemFactoryStorage.CommonGemsMiningPeriod](src/L2/GemFactoryStorage.sol#L78) should be constant 

src/L2/GemFactoryStorage.sol#L78


 - [ ] ID-552
[GemFactoryStorage.RareGemsValue](src/L2/GemFactoryStorage.sol#L72) should be constant 

src/L2/GemFactoryStorage.sol#L72


 - [ ] ID-553
[GemFactoryStorage.MythicGemsValue](src/L2/GemFactoryStorage.sol#L76) should be constant 

src/L2/GemFactoryStorage.sol#L76


 - [ ] ID-554
[GemFactoryStorage.LegendaryGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L89) should be constant 

src/L2/GemFactoryStorage.sol#L89


 - [ ] ID-555
[L1WrappedStakedTONStorage.layer2Address](src/L1/L1WrappedStakedTONStorage.sol#L15) should be constant 

src/L1/L1WrappedStakedTONStorage.sol#L15


 - [ ] ID-556
[GemFactoryStorage.EpicminingTry](src/L2/GemFactoryStorage.sol#L67) should be constant 

src/L2/GemFactoryStorage.sol#L67


 - [ ] ID-557
[GemFactoryStorage.CommonGemsCooldownPeriod](src/L2/GemFactoryStorage.sol#L85) should be constant 

src/L2/GemFactoryStorage.sol#L85


 - [ ] ID-558
[MarketPlaceStorage.paused](src/L2/MarketPlaceStorage.sol#L27) should be constant 

src/L2/MarketPlaceStorage.sol#L27


 - [ ] ID-559
[GemFactoryStorage.LegendaryminingTry](src/L2/GemFactoryStorage.sol#L68) should be constant 

src/L2/GemFactoryStorage.sol#L68


 - [ ] ID-560
[GemFactoryStorage.paused](src/L2/GemFactoryStorage.sol#L61) should be constant 

src/L2/GemFactoryStorage.sol#L61


## immutable-states
Impact: Optimization
Confidence: High
 - [ ] ID-561
[DRBCoordinatorMock.s_calldataSizeBytes](src/L2/Mock/DRBCoordinatorMock.sol#L39) should be immutable 

src/L2/Mock/DRBCoordinatorMock.sol#L39


 - [ ] ID-562
[DRBCoordinatorMock.s_avgL2GasUsed](src/L2/Mock/DRBCoordinatorMock.sol#L36) should be immutable 

src/L2/Mock/DRBCoordinatorMock.sol#L36


 - [ ] ID-563
[Treasury.wston](src/L2/Treasury.sol#L17) should be immutable 

src/L2/Treasury.sol#L17


 - [ ] ID-564
[WstonSwapPool.treasury](src/L2/WstonSwapPool.sol#L15) should be immutable 

src/L2/WstonSwapPool.sol#L15


 - [ ] ID-565
[L2StandardERC20.l2Bridge](src/L2/Mock/L2StandardERC20.sol#L9) should be immutable 

src/L2/Mock/L2StandardERC20.sol#L9


 - [ ] ID-566
[DRBCoordinatorMock.s_flatFee](src/L2/Mock/DRBCoordinatorMock.sol#L38) should be immutable 

src/L2/Mock/DRBCoordinatorMock.sol#L38


 - [ ] ID-567
[Treasury.ton](src/L2/Treasury.sol#L18) should be immutable 

src/L2/Treasury.sol#L18


 - [ ] ID-568
[WstonSwapPool.wston](src/L2/WstonSwapPool.sol#L14) should be immutable 

src/L2/WstonSwapPool.sol#L14


 - [ ] ID-569
[MockTON.l1Token](src/L2/Mock/MockTON.sol#L8) should be immutable 

src/L2/Mock/MockTON.sol#L8


 - [ ] ID-570
[WstonSwapPool.feeRate](src/L2/WstonSwapPool.sol#L20) should be immutable 

src/L2/WstonSwapPool.sol#L20


 - [ ] ID-571
[WstonSwapPool.ton](src/L2/WstonSwapPool.sol#L13) should be immutable 

src/L2/WstonSwapPool.sol#L13


 - [ ] ID-572
[L1WrappedStakedTONStorage.wton](src/L1/L1WrappedStakedTONStorage.sol#L16) should be immutable 

src/L1/L1WrappedStakedTONStorage.sol#L16


 - [ ] ID-573
[MockTON.l2Bridge](src/L2/Mock/MockTON.sol#L9) should be immutable 

src/L2/Mock/MockTON.sol#L9


 - [ ] ID-574
[GemFactoryStorage.drbcoordinator](src/L2/GemFactoryStorage.sol#L104) should be immutable 

src/L2/GemFactoryStorage.sol#L104


 - [ ] ID-575
[L2StandardERC20.l1Token](src/L2/Mock/L2StandardERC20.sol#L8) should be immutable 

src/L2/Mock/L2StandardERC20.sol#L8


 - [ ] ID-576
[DRBCoordinatorMock.s_premiumPercentage](src/L2/Mock/DRBCoordinatorMock.sol#L37) should be immutable 

src/L2/Mock/DRBCoordinatorMock.sol#L37


 - [ ] ID-577
[L1WrappedStakedTONStorage.layer2Address](src/L1/L1WrappedStakedTONStorage.sol#L15) should be immutable 

src/L1/L1WrappedStakedTONStorage.sol#L15


 - [ ] ID-578
[L1WrappedStakedTONFactory.l1wton](src/L1/L1WrappedStakedTONFactory.sol#L9) should be immutable 

src/L1/L1WrappedStakedTONFactory.sol#L9


