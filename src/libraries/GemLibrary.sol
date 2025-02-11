// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../L2/GemFactoryStorage.sol";

library GemLibrary {
    /**
     * @notice Creates a new gem and assigns it to the specified owner.
     * @dev This function adds a new gem to the Gems array and updates the ownership mappings.
     * @param Gems The storage array of gems.
     * @param GEMIndexToOwner Mapping from gem index to owner address.
     * @param ownershipTokenCount Mapping from owner address to the number of gems owned.
     * @param owner The address of the gem owner.
     * @param rarity The rarity of the gem.
     * @param color The color attributes of the gem.
     * @param backgroundColor The background color of the gem.
     * @param quadrants The quadrant attributes of the gem.
     * @param value The value of the gem.
     * @param gemCooldownPeriod The cooldown period for the gem.
     * @param miningTry The number of mining attempts for the gem.
     * @param tokenURI The URI for the gem's metadata.
     * @return The ID of the newly created gem.
     */
    function createGem(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address owner,
        GemFactoryStorage.Rarity rarity,
        uint8[2] memory color,
        GemFactoryStorage.BackgroundColor memory backgroundColor,
        uint8[4] memory quadrants,
        uint256 value,
        uint256 gemCooldownPeriod,
        uint8 miningTry,
        string memory tokenURI
    ) internal returns (uint256) {
        GemFactoryStorage.Gem memory newGem = GemFactoryStorage.Gem({
            tokenId: 0,
            rarity: rarity,
            quadrants: quadrants,
            color: color,
            backgroundColor: backgroundColor,
            value: value,
            gemCooldownDueDate: gemCooldownPeriod,
            miningTry: miningTry,
            isLocked: false,
            tokenURI: tokenURI,
            randomRequestId: 0
        });

        Gems.push(newGem);
        uint256 newGemId = Gems.length - 1;
        Gems[newGemId].tokenId = newGemId;

        GEMIndexToOwner[newGemId] = owner;
        ownershipTokenCount[owner]++;

        return newGemId;
    }

    /**
     * @notice Burns a gem, removing it from the storage and updating ownership.
     * @dev This function deletes the gem from the Gems array and updates the ownership mappings.
     * @param Gems The storage array of gems.
     * @param GEMIndexToOwner Mapping from gem index to owner address.
     * @param ownershipTokenCount Mapping from owner address to the number of gems owned.
     * @param owner The address of the gem owner.
     * @param tokenId The ID of the gem to be burned.
     */
    function burnGem(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address owner,
        uint256 tokenId
    ) internal {
        delete Gems[tokenId];
        ownershipTokenCount[owner]--;
        delete GEMIndexToOwner[tokenId];
    }

    /**
     * @notice Burns multiple gems, removing them from the storage and updating ownership.
     * @dev This function iterates over the provided token IDs and burns each gem.
     * @param Gems The storage array of gems.
     * @param GEMIndexToOwner Mapping from gem index to owner address.
     * @param ownershipTokenCount Mapping from owner address to the number of gems owned.
     * @param owner The address of the gem owner.
     * @param tokenIds An array of gem IDs to be burned.
     */
    function burnGems(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address owner,
        uint256[] memory tokenIds
    ) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burnGem(Gems, GEMIndexToOwner, ownershipTokenCount, owner, tokenIds[i]);
        }
    }

    /**
     * @notice computes the background color based on the color and rarity of the GEM
     * @param _index1 The first index of the color.
     * @param _index2 The second index of the color.
     * @param _rarity the rarity of the Gem for which we want to determine the background color
     * @return the background color associated
     */
    function getBackgroundColor(
        uint8 _index1, 
        uint8 _index2, 
        GemFactoryStorage.Rarity _rarity,
        GemFactoryStorage.Color[] storage colors,
        mapping(uint8 => mapping(uint8 => uint256)) storage colorIndexInTheColorArray
    ) public view returns(GemFactoryStorage.BackgroundColor memory) {
        // memory storage initialization
        uint8[2] memory r_background;
        uint8[2] memory g_background;
        uint8[2] memory b_background;
        uint8 blur_background;
        bool dropShadow;
        uint256 colorIndex = colorIndexInTheColorArray[_index1][_index2];
        uint8[2] memory r_color = colors[colorIndex].r; 
        uint8[2] memory g_color = colors[colorIndex].g; 
        uint8[2] memory b_color = colors[colorIndex].b; 
        uint16 sumOfcolor_r = uint16(r_color[0]) + uint16(r_color[1]);
        uint16 sumOfcolor_g = uint16(g_color[0]) + uint16(g_color[1]);
        uint16 sumOfcolor_b = uint16(b_color[0]) + uint16(b_color[1]);

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));

        if(_rarity == GemFactoryStorage.Rarity.COMMON) {
            // the background for COMMON gems is predefined
            r_background = [25, 25];
            g_background = [26, 26];
            b_background = [34, 34];
            blur_background = 0;
        }
        else if(_rarity == GemFactoryStorage.Rarity.RARE) {
            dropShadow = false;
            blur_background = 0;
            if(sumOfcolor_r > sumOfcolor_g)  {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [127, 127];
                    if(sumOfcolor_g > sumOfcolor_b) {
                        // case r > g > b
                        b_background = [90, 90];
                        // g is a random value between 110 and 120
                        g_background = [110 + uint8(randomSeed % 10), 110 + uint8(randomSeed % 10)];
                    }
                    else {
                        // case r > b >= g
                        g_background = [90, 90];
                        // b is a random value between 110 and 120
                        b_background = [110 + uint8(randomSeed % 10), 110 + uint8(randomSeed % 10)];
                    }
                }
                else if(sumOfcolor_r == sumOfcolor_b) {
                    r_background = [127, 127];
                    g_background = [90, 90];
                    b_background = [127, 127];
                }
                else {
                    b_background = [127, 127];
                    if(sumOfcolor_r > sumOfcolor_g) {
                        // case  b > r > g
                        g_background = [90, 90];
                        // r is a random value between 110 and 120
                        r_background = [110 + uint8(randomSeed % 10), 110 + uint8(randomSeed % 10)];
                    }
                    else {
                        // case b > g >= r
                        r_background = [90, 90];
                        // g is a random value between 110 and 120
                        g_background = [110 + uint8(randomSeed % 10), 110 + uint8(randomSeed % 10)];
                    }
                }
            }
            else if(sumOfcolor_r == sumOfcolor_g) {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [127, 127];
                    g_background = [127, 127];
                    b_background = [90, 90];
                }
                else {
                    r_background = [90, 90];
                    g_background = [90, 90];
                    b_background = [127, 127];
                }
            }
            else {
                // case g > r
                if(sumOfcolor_g > sumOfcolor_b) {
                    g_background = [127, 127];
                    if(sumOfcolor_r > sumOfcolor_b) {
                        // case g > r > b
                        b_background = [90, 90];
                        // r is a random value between 110 and 120
                        r_background = [110 + uint8(randomSeed % 10), 110 + uint8(randomSeed % 10)];
                    }
                    else {
                        // case g > b >= r
                        r_background = [90, 90];
                        // b is a random value between 110 and 120
                        b_background = [110 + uint8(randomSeed % 10), 110 + uint8(randomSeed % 10)];
                    }
                }
                else if(sumOfcolor_g == sumOfcolor_b) {
                    r_background = [90, 90];
                    g_background = [127, 127];
                    b_background = [127, 127];
                }
                else {
                    b_background = [127, 127];
                    if(sumOfcolor_g > sumOfcolor_r) {
                        // case b > g > r
                        r_background = [90, 90];
                        // g is a random value between 110 and 120
                        g_background = [110 + uint8(randomSeed % 10), 110 + uint8(randomSeed % 10)];
                    }
                    else {
                        // case b > r >= g
                        g_background = [90, 90];
                        // r is a random value between 110 and 120
                        r_background = [110 + uint8(randomSeed % 10), 110 + uint8(randomSeed % 10)];
                    }
                }
            }

        }
        else if(_rarity == GemFactoryStorage.Rarity.UNIQUE) {
            dropShadow = false;
            blur_background = 0;
            if(sumOfcolor_r > sumOfcolor_g)  {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [150, 150];
                    if(sumOfcolor_g > sumOfcolor_b) {
                        // case r > g > b
                        b_background = [50, 50];
                        // g is a random value between 80 and 120
                        g_background = [80 + uint8(randomSeed % 40), 80 + uint8(randomSeed % 40)];
                    }
                    else {
                        // case r > b >= g
                        g_background = [50, 50];
                        // b is a random value between 80 and 120
                        b_background = [80 + uint8(randomSeed % 40), 80 + uint8(randomSeed % 40)];
                    }
                }
                else if(sumOfcolor_r == sumOfcolor_b) {
                    r_background = [150, 150];
                    g_background = [50, 50];
                    b_background = [150, 150];
                }
                else {
                    b_background = [150, 150];
                    if(sumOfcolor_r > sumOfcolor_g) {
                        // case  b > r > g
                        g_background = [50, 50];
                        // r is a random value between 80 and 120
                        r_background = [80 + uint8(randomSeed % 40), 80 + uint8(randomSeed % 40)];
                    }
                    else {
                        // case b > g >= r
                        r_background = [50, 50];
                        // g is a random value between 80 and 120
                        g_background = [80 + uint8(randomSeed % 40), 80 + uint8(randomSeed % 40)];
                    }
                }
            }
            else if(sumOfcolor_r == sumOfcolor_g) {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [150, 150];
                    g_background = [150, 150];
                    b_background = [50, 50];
                }
                else {
                    r_background = [50, 50];
                    g_background = [50, 50];
                    b_background = [150, 150];
                }
            }
            else {
                // case g > r
                if(sumOfcolor_g > sumOfcolor_b) {
                    g_background = [150, 150];
                    if(sumOfcolor_r > sumOfcolor_b) {
                        // case g > r > b
                        b_background = [50, 50];
                        // r is a random value between 80 and 120
                        r_background = [80 + uint8(randomSeed % 40), 80 + uint8(randomSeed % 40)];
                    }
                    else {
                        // case g > b >= r
                        r_background = [50, 50];
                        // b is a random value between 80 and 120
                        b_background = [80 + uint8(randomSeed % 40), 80 + uint8(randomSeed % 40)];
                    }
                }
                else if(sumOfcolor_g == sumOfcolor_b) {
                    r_background = [50, 50];
                    g_background = [150, 150];
                    b_background = [150, 150];
                }
                else {
                    b_background = [150, 150];
                    if(sumOfcolor_g > sumOfcolor_r) {
                        // case b > g > r
                        r_background = [50, 50];
                        // g is a random value between 80 and 120
                        g_background = [80 + uint8(randomSeed % 40), 80 + uint8(randomSeed % 40)];
                    }
                    else {
                        // case b > r >= g
                        g_background = [50, 50];
                        // r is a random value between 80 and 120
                        r_background = [80 + uint8(randomSeed % 40), 80 + uint8(randomSeed % 40)];
                    }
                }
            }
        }
        else if(_rarity == GemFactoryStorage.Rarity.EPIC) {
            dropShadow = false;
            blur_background = 0;

            if(sumOfcolor_r > sumOfcolor_g)  {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [150, 100];
                    if(sumOfcolor_g > sumOfcolor_b) {
                        // case r > g > b
                        b_background = [50, 0];
                        // g1 is a random value between 80 and 120 g2 is a random value between 40 and 60
                        g_background = [80 + uint8(randomSeed % 40), 40 + uint8(randomSeed % 20)];
                    }
                    else {
                        // case r > b >= g
                        g_background = [50, 0];
                        // b is a random value between 80 and 120
                        b_background = [80 + uint8(randomSeed % 40), 40 + uint8(randomSeed % 20)];
                    }
                }
                else if(sumOfcolor_r == sumOfcolor_b) {
                    r_background = [150, 100];
                    g_background = [50, 0];
                    b_background = [150, 100];
                }
                else {
                    b_background = [150, 100];
                    if(sumOfcolor_r > sumOfcolor_g) {
                        // case  b > r > g
                        g_background = [50, 0];
                        // r is a random value between 80 and 120
                        r_background = [80 + uint8(randomSeed % 40), 40 + uint8(randomSeed % 20)];
                    }
                    else {
                        // case b > g >= r
                        r_background = [50, 0];
                        // g is a random value between 80 and 120
                        g_background = [80 + uint8(randomSeed % 40), 40 + uint8(randomSeed % 40)];
                    }
                }
            }
            else if(sumOfcolor_r == sumOfcolor_g) {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [150, 100];
                    g_background = [150, 100];
                    b_background = [50, 0];
                }
                else {
                    r_background = [50, 0];
                    g_background = [50, 0];
                    b_background = [150, 100];
                }
            }
            else {
                // case g > r
                if(sumOfcolor_g > sumOfcolor_b) {
                    g_background = [150, 100];
                    if(sumOfcolor_r > sumOfcolor_b) {
                        // case g > r > b
                        b_background = [50, 0];
                        // r is a random value between 80 and 120
                        r_background = [80 + uint8(randomSeed % 40), 40 + uint8(randomSeed % 20)];
                    }
                    else {
                        // case g > b >= r
                        r_background = [50, 0];
                        // b is a random value between 80 and 120
                        b_background = [80 + uint8(randomSeed % 40), 40 + uint8(randomSeed % 20)];
                    }
                }
                else if(sumOfcolor_g == sumOfcolor_b) {
                    r_background = [50, 0];
                    g_background = [150, 100];
                    b_background = [150, 100];
                }
                else {
                    b_background = [150, 100];
                    if(sumOfcolor_g > sumOfcolor_r) {
                        // case b > g > r
                        r_background = [50, 0];
                        // g is a random value between 80 and 120
                        g_background = [80 + uint8(randomSeed % 40), 40 + uint8(randomSeed % 20)];
                    }
                    else {
                        // case b > r >= g
                        g_background = [50, 0];
                        // r is a random value between 80 and 120
                        r_background = [80 + uint8(randomSeed % 40), 40 + uint8(randomSeed % 20)];
                    }
                }
            }
        }
        else if(_rarity == GemFactoryStorage.Rarity.LEGENDARY) {
            dropShadow = true;
            blur_background = 25;
            r_background = r_color;
            g_background = g_color;
            b_background = b_color;

        }
        else if(_rarity == GemFactoryStorage.Rarity.MYTHIC) {
            dropShadow = true;
            blur_background = 40;
            uint8 firstOrSecondColor = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 2);
            uint8 secondColor_r = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 255);
            uint8 secondColor_g = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, secondColor_r))) % 255);
            uint8 secondColor_b = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, secondColor_g))) % 255);
            r_background = [r_color[firstOrSecondColor], secondColor_r];
            g_background = [g_color[firstOrSecondColor], secondColor_g];
            b_background = [b_color[firstOrSecondColor], secondColor_b];

        }
        GemFactoryStorage.BackgroundColor memory backgroundColor = GemFactoryStorage.BackgroundColor({
            r: r_background,
            g: g_background,
            b: b_background,
            blur: blur_background,
            dropShadow: dropShadow
        });
        return backgroundColor;
    } 

    function checkQuadrants(uint8[4] memory _quadrants, GemFactoryStorage.Rarity _rarity) external pure returns(bool) {
        uint8 sumOfQuadrants = _quadrants[0] + _quadrants[1] + _quadrants[2] + _quadrants[3];
        if(_rarity == GemFactoryStorage.Rarity.COMMON) {
            // Validate quadrant values for COMMON rarity
            if (_quadrants[0] != 1 && _quadrants[0] != 2) revert GemFactoryStorage.NewGemInvalidQuadrant(0, 1, 2);
            if (_quadrants[1] != 1 && _quadrants[1] != 2) revert GemFactoryStorage.NewGemInvalidQuadrant(1, 1, 2);
            if (_quadrants[2] != 1 && _quadrants[2] != 2) revert GemFactoryStorage.NewGemInvalidQuadrant(2, 1, 2);
            if (_quadrants[3] != 1 && _quadrants[3] != 2) revert GemFactoryStorage.NewGemInvalidQuadrant(3, 1, 2);
            if (sumOfQuadrants >= 8) revert GemFactoryStorage.SumOfQuadrantsTooHigh(sumOfQuadrants, "COMMON");
        }
        else if(_rarity == GemFactoryStorage.Rarity.RARE) {
            // Validate quadrant values for RARE rarity
            if (_quadrants[0] != 2 && _quadrants[0] != 3) revert GemFactoryStorage.NewGemInvalidQuadrant(0, 2, 3);
            if (_quadrants[1] != 2 && _quadrants[1] != 3) revert GemFactoryStorage.NewGemInvalidQuadrant(1, 2, 3);
            if (_quadrants[2] != 2 && _quadrants[2] != 3) revert GemFactoryStorage.NewGemInvalidQuadrant(2, 2, 3);
            if (_quadrants[3] != 2 && _quadrants[3] != 3) revert GemFactoryStorage.NewGemInvalidQuadrant(3, 2, 3);
            if (sumOfQuadrants >= 12) revert GemFactoryStorage.SumOfQuadrantsTooHigh(sumOfQuadrants, "RARE");
        }
        else if(_rarity == GemFactoryStorage.Rarity.UNIQUE) {
            if (_quadrants[0] != 3 && _quadrants[0] != 4) revert GemFactoryStorage.NewGemInvalidQuadrant(0, 3, 4);
            if (_quadrants[1] != 3 && _quadrants[1] != 4) revert GemFactoryStorage.NewGemInvalidQuadrant(1, 3, 4);
            if (_quadrants[2] != 3 && _quadrants[2] != 4) revert GemFactoryStorage.NewGemInvalidQuadrant(2, 3, 4);
            if (_quadrants[3] != 3 && _quadrants[3] != 4) revert GemFactoryStorage.NewGemInvalidQuadrant(3, 3, 4);
            if (sumOfQuadrants >= 16) revert GemFactoryStorage.SumOfQuadrantsTooHigh(sumOfQuadrants, "UNIQUE");
        }
        else if(_rarity == GemFactoryStorage.Rarity.EPIC) {
            if (_quadrants[0] != 4 && _quadrants[0] != 5) revert GemFactoryStorage.NewGemInvalidQuadrant(0, 4, 5);
            if (_quadrants[1] != 4 && _quadrants[1] != 5) revert GemFactoryStorage.NewGemInvalidQuadrant(1, 4, 5);
            if (_quadrants[2] != 4 && _quadrants[2] != 5) revert GemFactoryStorage.NewGemInvalidQuadrant(2, 4, 5);
            if (_quadrants[3] != 4 && _quadrants[3] != 5) revert GemFactoryStorage.NewGemInvalidQuadrant(3, 4, 5);
            if (sumOfQuadrants >= 20) revert GemFactoryStorage.SumOfQuadrantsTooHigh(sumOfQuadrants, "EPIC");
        }
        else if(_rarity == GemFactoryStorage.Rarity.LEGENDARY) {
            if (_quadrants[0] != 5 && _quadrants[0] != 6) revert GemFactoryStorage.NewGemInvalidQuadrant(0, 5, 6);
            if (_quadrants[1] != 5 && _quadrants[1] != 6) revert GemFactoryStorage.NewGemInvalidQuadrant(1, 5, 6);
            if (_quadrants[2] != 5 && _quadrants[2] != 6) revert GemFactoryStorage.NewGemInvalidQuadrant(2, 5, 6);
            if (_quadrants[3] != 5 && _quadrants[3] != 6) revert GemFactoryStorage.NewGemInvalidQuadrant(3, 5, 6);
            if (sumOfQuadrants >= 24) revert GemFactoryStorage.SumOfQuadrantsTooHigh(sumOfQuadrants, "LEGENDARY");
        }
        else if(_rarity == GemFactoryStorage.Rarity.MYTHIC) {
            // Validate quadrant values for MYTHIC rarity
            if (_quadrants[0] != 6 || _quadrants[1] != 6 || _quadrants[2] != 6 || _quadrants[3] != 6) {
                revert GemFactoryStorage.NewGemInvalidQuadrant(0, 6, 6);
            }   
        }
        else {
            revert GemFactoryStorage.WrongRarity();
        }
        return true;
    }
}
