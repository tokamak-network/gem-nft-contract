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
        uint8 RareminingTry;
        uint8 UniqueminingTry;
        uint8 EpicminingTry;
        uint8 LegendaryminingTry;
        uint8 MythicminingTry;
        uint32 RareGemsCooldownPeriod;
        uint32 UniqueGemsCooldownPeriod;
        uint32 EpicGemsCooldownPeriod;
        uint32 LegendaryGemsCooldownPeriod;
        uint32 MythicGemsCooldownPeriod;
    }

    // EVENTS
    event ColorValidated(uint8 color0, uint8 color1);

    // ERRORS
    error NotValidColor();
    error WrongNumberOfGemToBeForged();
    error AddressZero();
    error NotGemOwner();
    error GemIsLocked();
    error WrongRarity();

    /**
     * @notice Forges new tokens from existing gems.
     * @dev This function combines multiple gems into a new gem of higher rarity.
     * @param Gems The storage array of gems.
     * @param GEMIndexToOwner Mapping from gem index to owner address.
     * @param ownershipTokenCount Mapping from owner address to the number of gems owned.
     * @param msgSender The address of the sender initiating the forge.
     * @param _tokenIds An array of token IDs to be forged.
     * @param _rarity The rarity of the gems to be forged.
     * @param _color The color attributes for the new gem.
     * @param params The parameters for forging, including values and periods.
     * @return newGemId The ID of the newly forged gem.
     * @return forgedQuadrants The quadrant attributes of the forged gem.
     * @return newRarity The new rarity of the forged gem.
     * @return forgedGemsValue The value of the forged gem.
     * @return forgedGemsCooldownDueDate The cooldown period of the forged gem.
     * @return forgedGemsminingTry The number of mining attempts for the forged gem.
     */
    function forgeTokens(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address msgSender,
        uint256[] memory _tokenIds,
        GemFactoryStorage.Rarity _rarity,
        uint8[2] memory _color,
        ForgeParams memory params
    ) internal returns (uint256 newGemId, uint8[4] memory forgedQuadrants, GemFactoryStorage.Rarity newRarity, uint256 forgedGemsValue, uint256 forgedGemsCooldownDueDate, uint8 forgedGemsminingTry) {
         // Ensure the sender's address is not zero
        if(msgSender == address(0)) {
            revert AddressZero();
        }
        uint32 forgedGemsCooldownPeriod;

        // Determine the properties of the new GEM based on the desired rarity
        if (_rarity == GemFactoryStorage.Rarity.COMMON) {
            if(_tokenIds.length != 2) {
                revert WrongNumberOfGemToBeForged();
            }
            forgedGemsValue = params.RareGemsValue;
            forgedGemsminingTry = params.RareminingTry;
            forgedGemsCooldownPeriod = params.RareGemsCooldownPeriod;
        } else if (_rarity == GemFactoryStorage.Rarity.RARE) {
            if(_tokenIds.length != 3) {
                revert WrongNumberOfGemToBeForged();
            }
            forgedGemsValue = params.UniqueGemsValue;
            forgedGemsminingTry = params.UniqueminingTry;
            forgedGemsCooldownPeriod = params.UniqueGemsCooldownPeriod;
        } else if (_rarity == GemFactoryStorage.Rarity.UNIQUE) {
            if(_tokenIds.length != 4) {
                revert WrongNumberOfGemToBeForged();
            }
            forgedGemsValue = params.EpicGemsValue;
            forgedGemsminingTry = params.EpicminingTry;
            forgedGemsCooldownPeriod = params.EpicGemsCooldownPeriod;
        } else if (_rarity == GemFactoryStorage.Rarity.EPIC) {
            if(_tokenIds.length != 5) {
                revert WrongNumberOfGemToBeForged();
            }
            forgedGemsValue = params.LegendaryGemsValue;
            forgedGemsminingTry = params.LegendaryminingTry;
            forgedGemsCooldownPeriod = params.LegendaryGemsCooldownPeriod;
        } else if (_rarity == GemFactoryStorage.Rarity.LEGENDARY) {
            if(_tokenIds.length != 6) {
                revert WrongNumberOfGemToBeForged();
            }
            forgedGemsValue = params.MythicGemsValue;
            forgedGemsminingTry = params.MythicminingTry;
            forgedGemsCooldownPeriod = params.MythicGemsCooldownPeriod;
        } else {
            revert("wrong rarity");
        }

        // Initialize variables for quadrant summation and color validation
        uint8[4] memory sumOfQuadrants;
        bool colorValidated = false;

        // Iterate over each token to validate ownership, lock status, and rarity
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(GEMIndexToOwner[_tokenIds[i]] != msgSender) {
                revert NotGemOwner();
            }
            if(isTokenLocked(Gems, _tokenIds[i])) {
                revert GemIsLocked();
            }
            if(Gems[_tokenIds[i]].rarity != _rarity) {
                revert WrongRarity();
            }

            // Sum the quadrants of the tokens
            sumOfQuadrants[0] += Gems[_tokenIds[i]].quadrants[0];
            sumOfQuadrants[1] += Gems[_tokenIds[i]].quadrants[1];
            sumOfQuadrants[2] += Gems[_tokenIds[i]].quadrants[2];
            sumOfQuadrants[3] += Gems[_tokenIds[i]].quadrants[3];

            // Validate the color of the tokens
            for (uint256 j = 0; j < _tokenIds.length; j++) {
                if (!colorValidated) {
                    colorValidated = _checkColor(Gems, _tokenIds[i], _tokenIds[j], _color[0], _color[1]);
                    if (colorValidated) {
                        emit ColorValidated(_color[0], _color[1]);
                    }
                }
            }
        }
        // Ensure the color is valid
        if(!colorValidated) {
            revert NotValidColor();
        }

        // Calculate the new quadrants for the forged GEM
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
        // Adjust quadrants if they all exceed the base value by 1
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

        // Determine the new rarity of the forged GEM
        newRarity = GemFactoryStorage.Rarity(uint8(_rarity) + 1);

        // determining the cooldown due date
        forgedGemsCooldownDueDate = block.timestamp + forgedGemsCooldownPeriod;
        
        // Create the new GEM and add it to the storage
        GemFactoryStorage.Gem memory _Gem = GemFactoryStorage.Gem({
            tokenId: 0,
            rarity: newRarity,
            quadrants: forgedQuadrants,
            color: _color,
            value: forgedGemsValue,
            gemCooldownDueDate: forgedGemsCooldownDueDate,
            miningTry: forgedGemsminingTry,
            isLocked: false,
            tokenURI: "",
            randomRequestId: 0
        });
        Gems.push(_Gem);
        newGemId = Gems.length - 1;
        Gems[newGemId].tokenId = newGemId;

        // Ensure the new GEM ID is valid and updating GEM storage
        require(newGemId == uint256(uint32(newGemId)));
        GEMIndexToOwner[newGemId] = msgSender;
        ownershipTokenCount[msgSender]++;

        // Return the properties of the newly forged GEM
        return (newGemId, forgedQuadrants, newRarity, forgedGemsValue, forgedGemsCooldownDueDate, forgedGemsminingTry);
    }

    /**
     * @notice Checks if two gems can produce the specified color.
     * two same solids (ex: [1,1] + [1,1]): the new token color can only be [1,1].
     * two different solids (ex: [1,1] + [2,2]): the new token color can be either [1,2] or [2,1].
     * one solid and one gradient & one gradient color is the same as the solid color (ex: [1,1] + [2,1]): the new token color can be [2,1].
     * one solid and one gradient & solid different from both gradients (ex: [1,1] + [3,2]): the new token color can be either [3,1] or [2,1] or [1,3] or [1,2].
     * two same gradients (ex: [1,2] + [1+2]): the new color can be either [1,2] or [2,1].
     * two different gradients (ex: [1,2] + [3,4]): the new color can be either [1,3] or [1,4] or [2,3] or [2,4] or [3,1] or [4,1] or [3,2] or [4,2].
     * @dev This function compares the colors of two gems to determine if they can produce the desired color.
     * @param Gems The storage array of gems.
     * @param tokenA The ID of the first gem.
     * @param tokenB The ID of the second gem.
     * @param _color_0 The first component of the desired color.
     * @param _color_1 The second component of the desired color.
     * @return colorValidated A boolean indicating if the color can be obtained.
     */
    function _checkColor(
        GemFactoryStorage.Gem[] storage Gems,
        uint256 tokenA,
        uint256 tokenB,
        uint8 _color_0,
        uint8 _color_1
    ) internal view returns (bool colorValidated) {
        colorValidated = false;
        // Ensure the tokens are different
        if (tokenA != tokenB) {
            // Retrieve colors of the two tokens
            uint8[2] memory _color1 = Gems[tokenA].color;
            uint8 _color1_0 = _color1[0];
            uint8 _color1_1 = _color1[1];
            uint8[2] memory _color2 = Gems[tokenB].color;
            uint8 _color2_0 = _color2[0];
            uint8 _color2_1 = _color2[1];

            // Check if both tokens have identical colors and match the desired color
            if (_color1_0 == _color1_1 && _color2_0 == _color2_1 && _color1_0 == _color2_0) {
                colorValidated = (_color_0 == _color1_0 && _color_1 == _color1_1);
                return colorValidated;
            }
            // Check if both tokens have identical colors but different from each other
            if (_color1_0 == _color1_1 && _color2_0 == _color2_1) {
                colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color2_0 && _color_1 == _color1_0));
                return colorValidated;
            }
            // Check if one token has identical colors and the other has one matching color
            if (((_color1_0 != _color1_1 && _color2_0 == _color2_1) && (_color1_0 == _color2_0 || _color1_1 == _color2_0)) || ((_color1_0 == _color1_1 && _color2_0 != _color2_1) && (_color2_0 == _color1_0 || _color2_1 == _color1_0))) {
                if (_color1_0 != _color1_1) {
                    colorValidated = ((_color_0 == _color1_0 && _color_1 == _color1_1) || (_color_1 == _color1_0 && _color_0 == _color1_1));
                    return colorValidated;
                } else {
                    colorValidated = ((_color_0 == _color2_0 && _color_1 == _color2_1) || (_color_1 == _color2_0 && _color_0 == _color2_1));
                    return colorValidated;
                }
            }
            // Check if one token has identical colors and the other has no matching colors
            if (((_color1_0 != _color1_1 && _color2_0 == _color2_1) && (_color1_0 != _color2_0 && _color1_1 != _color2_0)) || ((_color1_0 == _color1_1 && _color2_0 != _color2_1) && (_color1_0 != _color2_0 && _color1_0 != _color2_1))) {
                if (_color1_0 != _color1_1) {
                    colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_1 == _color1_0 && _color_0 == _color2_0) || (_color_1 == _color1_1 && _color_0 == _color2_0));
                    return colorValidated;
                } else {
                    colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_1 == _color1_0 && _color_0 == _color2_0) || (_color_1 == _color1_0 && _color_0 == _color2_1));
                    return colorValidated;
                }
            }
            // Check if both tokens have different colors but match each other
            if (_color1_0 != _color1_1 && _color2_0 != _color2_1 && ((_color1_0 == _color2_0 && _color1_1 == _color2_1) || (_color1_0 == _color2_1 && _color1_1 == _color2_0))) {
                colorValidated = ((_color_0 == _color1_0 && _color_1 == _color1_1) || (_color_0 == _color1_1 && _color_1 == _color1_0));
                return colorValidated;
            }
            // Check if both tokens have different colors with at least one matching color
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
            // Check if both tokens have completely different colors
            if (_color1_0 != _color1_1 && _color2_0 != _color2_1 && _color1_0 != _color2_0 && _color1_1 != _color2_0 && _color1_0 != _color2_1 && _color1_1 != _color2_1) {
                colorValidated = ((_color_0 == _color1_0 && _color_1 == _color2_0) || (_color_0 == _color1_0 && _color_1 == _color2_1) || (_color_0 == _color1_1 && _color_1 == _color2_0) || (_color_0 == _color1_1 && _color_1 == _color2_1) || (_color_0 == _color2_0 && _color_1 == _color1_0) || (_color_0 == _color2_0 && _color_1 == _color1_1) || (_color_0 == _color2_1 && _color_1 == _color1_0) || (_color_0 == _color2_1 && _color_1 == _color1_1));
                return colorValidated;
            }
        } else {
            // Return false if the tokens are the same
            return colorValidated;
        }
    }

    /**
     * @notice Checks if a gem token is locked.
     * @dev This function checks the `isLocked` status of a gem.
     * @param Gems The storage array of gems.
     * @param tokenId The ID of the gem to check.
     * @return A boolean indicating if the gem is locked.
     */
    function isTokenLocked(GemFactoryStorage.Gem[] storage Gems, uint256 tokenId) internal view returns (bool) {
        return Gems[tokenId].isLocked;
    }
}

