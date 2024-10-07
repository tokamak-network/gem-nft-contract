// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../L2/GemFactoryStorage.sol";

library ForgeLibrary {
    struct ForgeParams {
        uint256 RareGemsValue;
        uint256 UniqueGemsValue;
        uint256 EpicGemsValue;
        uint256 LegendaryGemsValue;
        uint256 MythicGemsValue;
        uint256 RareGemsMiningPeriod;
        uint256 UniqueGemsMiningPeriod;
        uint256 EpicGemsMiningPeriod;
        uint256 LegendaryGemsMiningPeriod;
        uint256 MythicGemsMiningPeriod;
        uint256 RareminingTry;
        uint256 UniqueminingTry;
        uint256 EpicminingTry;
        uint256 LegendaryminingTry;
        uint256 MythicminingTry;
        uint256 RareGemsCooldownPeriod;
        uint256 UniqueGemsCooldownPeriod;
        uint256 EpicGemsCooldownPeriod;
        uint256 LegendaryGemsCooldownPeriod;
        uint256 MythicGemsCooldownPeriod;
    }

    event ColorValidated(uint8 color0, uint8 color1);

    function forgeTokens(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address msgSender,
        uint256[] memory _tokenIds,
        GemFactoryStorage.Rarity _rarity,
        uint8[2] memory _color,
        ForgeParams memory params
    ) internal returns (uint256 newGemId, uint8[4] memory forgedQuadrants, GemFactoryStorage.Rarity newRarity, uint256 forgedGemsValue, uint256 forgedGemsMiningPeriod, uint256 forgedGemsCooldownPeriod, uint256 forgedGemsminingTry) {
        require(msgSender != address(0), "zero address");

        if (_rarity == GemFactoryStorage.Rarity.COMMON) {
            require(_tokenIds.length == 2, "wrong number of Gems to be forged");
            forgedGemsValue = params.RareGemsValue;
            forgedGemsMiningPeriod = params.RareGemsMiningPeriod;
            forgedGemsminingTry = params.RareminingTry;
            forgedGemsCooldownPeriod = params.RareGemsCooldownPeriod;
        } else if (_rarity == GemFactoryStorage.Rarity.RARE) {
            require(_tokenIds.length == 3, "wrong number of Gems to be forged");
            forgedGemsValue = params.UniqueGemsValue;
            forgedGemsMiningPeriod = params.UniqueGemsMiningPeriod;
            forgedGemsminingTry = params.UniqueminingTry;
            forgedGemsCooldownPeriod = params.UniqueGemsCooldownPeriod;
        } else if (_rarity == GemFactoryStorage.Rarity.UNIQUE) {
            require(_tokenIds.length == 4, "wrong number of Gems to be forged");
            forgedGemsValue = params.EpicGemsValue;
            forgedGemsMiningPeriod = params.EpicGemsMiningPeriod;
            forgedGemsminingTry = params.EpicminingTry;
            forgedGemsCooldownPeriod = params.EpicGemsCooldownPeriod;
        } else if (_rarity == GemFactoryStorage.Rarity.EPIC) {
            require(_tokenIds.length == 5, "wrong number of Gems to be forged");
            forgedGemsValue = params.LegendaryGemsValue;
            forgedGemsMiningPeriod = params.LegendaryGemsMiningPeriod;
            forgedGemsminingTry = params.LegendaryminingTry;
            forgedGemsCooldownPeriod = params.LegendaryGemsCooldownPeriod;
        } else if (_rarity == GemFactoryStorage.Rarity.LEGENDARY) {
            require(_tokenIds.length == 6, "wrong number of Gems to be forged");
            forgedGemsValue = params.MythicGemsValue;
            forgedGemsMiningPeriod = params.MythicGemsMiningPeriod;
            forgedGemsminingTry = params.MythicminingTry;
            forgedGemsCooldownPeriod = params.MythicGemsCooldownPeriod;
        } else {
            revert("wrong rarity");
        }

        uint8[4] memory sumOfQuadrants;
        bool colorValidated = false;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(GEMIndexToOwner[_tokenIds[i]] == msgSender, "not owner");
            require(!isTokenLocked(Gems, _tokenIds[i]), "Gem is for sale or is mining");
            require(Gems[_tokenIds[i]].rarity == _rarity, "wrong rarity Gems");

            sumOfQuadrants[0] += Gems[_tokenIds[i]].quadrants[0];
            sumOfQuadrants[1] += Gems[_tokenIds[i]].quadrants[1];
            sumOfQuadrants[2] += Gems[_tokenIds[i]].quadrants[2];
            sumOfQuadrants[3] += Gems[_tokenIds[i]].quadrants[3];

            for (uint256 j = 0; j < _tokenIds.length; j++) {
                if (!colorValidated) {
                    colorValidated = _checkColor(Gems, _tokenIds[i], _tokenIds[j], _color[0], _color[1]);
                    if (colorValidated) {
                        emit ColorValidated(_color[0], _color[1]);
                    }
                }
            }
        }
        require(colorValidated, "this color can't be obtained");

        sumOfQuadrants[0] %= 2;
        sumOfQuadrants[1] %= 2;
        sumOfQuadrants[2] %= 2;
        sumOfQuadrants[3] %= 2;

        uint8 baseValue;
        if (_rarity == GemFactoryStorage.Rarity.COMMON) baseValue = 2;
        else if (_rarity == GemFactoryStorage.Rarity.RARE) baseValue = 3;
        else if (_rarity == GemFactoryStorage.Rarity.UNIQUE) baseValue = 4;
        else if (_rarity == GemFactoryStorage.Rarity.EPIC) baseValue = 5;
        else if (_rarity == GemFactoryStorage.Rarity.LEGENDARY) baseValue = 6;

        for (uint8 i = 0; i < 4; i++) {
            forgedQuadrants[i] = baseValue + sumOfQuadrants[i];
        }

        if (
            forgedQuadrants[0] == baseValue + 1 &&
            forgedQuadrants[1] == baseValue + 1 &&
            forgedQuadrants[2] == baseValue + 1 &&
            forgedQuadrants[3] == baseValue + 1
        ) {
            forgedQuadrants[0] = baseValue;
            forgedQuadrants[1] = baseValue;
            forgedQuadrants[2] = baseValue;
            forgedQuadrants[3] = baseValue;
        }

        newRarity = GemFactoryStorage.Rarity(uint8(_rarity) + 1);

        GemFactoryStorage.Gem memory _Gem = GemFactoryStorage.Gem({
            tokenId: 0,
            rarity: newRarity,
            quadrants: forgedQuadrants,
            color: _color,
            value: forgedGemsValue,
            miningPeriod: forgedGemsMiningPeriod,
            gemCooldownPeriod: block.timestamp + forgedGemsCooldownPeriod,
            miningTry: forgedGemsminingTry,
            isLocked: false,
            tokenURI: "",
            randomRequestId: 0
        });
        Gems.push(_Gem);
        newGemId = Gems.length - 1;
        Gems[newGemId].tokenId = newGemId;

        require(newGemId == uint256(uint32(newGemId)));
        GEMIndexToOwner[newGemId] = msgSender;
        ownershipTokenCount[msgSender]++;

        return (newGemId, forgedQuadrants, newRarity, forgedGemsValue, forgedGemsMiningPeriod, forgedGemsCooldownPeriod, forgedGemsminingTry);
    }

    function _checkColor(
        GemFactoryStorage.Gem[] storage Gems,
        uint256 tokenA,
        uint256 tokenB,
        uint8 _color_0,
        uint8 _color_1
    ) internal view returns (bool colorValidated) {
        colorValidated = false;
        if (tokenA != tokenB) {
            uint8[2] memory _color1 = Gems[tokenA].color;
            uint8 _color1_0 = _color1[0];
            uint8 _color1_1 = _color1[1];
            uint8[2] memory _color2 = Gems[tokenB].color;
            uint8 _color2_0 = _color2[0];
            uint8 _color2_1 = _color2[1];

                        if (_color1_0 == _color1_1 && _color2_0 == _color2_1 && _color1_0 == _color2_0) {
                colorValidated = (_color_0 == _color1_0 && _color_1 == _color1_1);
                return colorValidated;
            }
            if (_color1_0 == _color1_1 && _color2_0 == _color2_1) {
                colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_0));
                return colorValidated;
            }
            if (((_color1_0 != _color1_1 && _color2_0 == _color2_1) && (_color1_0 == _color2_0 || _color1_1 == _color2_0)) || ((_color1_0 == _color1_1 && _color2_0 != _color2_1) && (_color2_0 == _color1_0 || _color2_1 == _color1_0))) {
                if (_color1_0 != _color1_1) {
                    colorValidated = ((_color_0 == _color1_0 && _color_1 == _color1_1) || (_color_1 == _color1_0 && _color_0 == _color1_1));
                    return colorValidated;
                } else {
                    colorValidated = ((_color_0 == _color2_0 && _color_1 == _color2_1) || (_color_1 == _color2_0 && _color_0 == _color2_1));
                    return colorValidated;
                }
            }
            if (((_color1_0 != _color1_1 && _color2_0 == _color2_1) && (_color1_0 != _color2_0 && _color1_1 != _color2_0)) || ((_color1_0 == _color1_1 && _color2_0 != _color2_1) && (_color1_0 != _color2_0 && _color1_0 != _color2_1))) {
                if (_color1_0 != _color1_1) {
                    colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_1 == _color1_0 && _color_0 == _color2_0) || (_color_1 == _color1_1 && _color_0 == _color2_0));
                    return colorValidated;
                } else {
                    colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_1 == _color1_0 && _color_0 == _color2_0) || (_color_1 == _color1_0 && _color_0 == _color2_1));
                    return colorValidated;
                }
            }
            if (_color1_0 != _color1_1 && _color2_0 != _color2_1 && ((_color1_0 == _color2_0 && _color1_1 == _color2_1) || (_color1_0 == _color2_1 && _color1_1 == _color2_0))) {
                colorValidated = ((_color_0 == _color1_0 && _color_1 == _color1_1) || (_color_0 == _color1_1 && _color_1 == _color1_0));
                return colorValidated;
            }
            if (_color1_0 != _color1_1 && _color2_0 != _color2_1 && (_color1_0 == _color2_0 || _color1_0 == _color2_1 || _color1_1 == _color2_0 || _color1_1 == _color2_1)) {
                if (_color1_0 == _color2_0) {
                    colorValidated = ((_color_0 == _color1_1 && _color_1 == _color2_1) || (_color_0 == _color2_1 && _color_1 == _color1_1));
                    return colorValidated;
                } else if (_color1_0 == _color2_1) {
                    colorValidated = ((_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_1));
                    return colorValidated;
                } else if (_color1_1 == _color2_0) {
                    colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_0 == _color2_1 && _color_1 == _color1_0));
                    return colorValidated;
                } else if (_color1_1 == _color2_1) {
                    colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_0));
                    return colorValidated;
                }
            }
            if (_color1_0 != _color1_1 && _color2_0 != _color2_1 && _color1_0 != _color2_0 && _color1_1 != _color2_0 && _color1_0 != _color2_1 && _color1_1 != _color2_1) {
                colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color1_1 && _color_1 == _color2_1) || (_color_0 == _color2_0 && _color_1 == _color1_0) || (_color_0 == _color2_0 && _color_1 == _color1_1) || (_color_0 == _color2_1 && _color_1 == _color1_0) || (_color_0 == _color2_1 && _color_1 == _color1_1));
                return colorValidated;
            }
        } else {
            return colorValidated;
        }
    }

    function isTokenLocked(GemFactoryStorage.Gem[] storage Gems, uint256 tokenId) internal view returns (bool) {
        return Gems[tokenId].isLocked;
    }
}

