// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../proxy/ProxyStorage.sol";
import "./GemFactoryStorage.sol";
import { ForgeLibrary } from "../libraries/ForgeLibrary.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/**
 * @title GemFactoryForging
 * @author TOKAMAK OPAL TEAM
 * @notice additionnal implementation of GemFactory (should be set as an implementation within GemFactoryProxy). 
 * @dev this additionnal implementation mananges the forging feature.
 * @dev Since this contract have a proxy index different from 0, users can not interact with these functions directly from the explorer. 
 * However, please note that this contract is deployed and operational
 */
contract GemFactoryForging is ProxyStorage, GemFactoryStorage, ERC721URIStorageUpgradeable {

    /**
     * @notice Modifier to ensure the contract is not paused
     */
    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }

    using ForgeLibrary for GemFactoryStorage.Gem[];

     /**
     * @notice function that allow users to forge their gems. Gems must have the same rarity. 
     * Users can choose the color the forged gem will have if it respects specific conditions. 
     * old gems are burnt while the new forged gem is minted.
     * @param _tokenIds array of tokens to be forged. Must respect some length depending on the rarity chosen
     * @param _rarity to check if the rarity of each token selected is the same
     * @param _color color desired of the forged gem
     */
    function forgeTokens(
        uint256[] memory _tokenIds,
        Rarity _rarity,
        uint8[2] memory _color
    ) external whenNotPaused returns (uint256 newGemId) {

        // Define ForgeParams struct with predefined values for various GEM types
        ForgeLibrary.ForgeParams memory params = ForgeLibrary.ForgeParams({
            RareGemsValue: RareGemsValue,
            UniqueGemsValue: UniqueGemsValue,
            EpicGemsValue: EpicGemsValue,
            LegendaryGemsValue: LegendaryGemsValue,
            MythicGemsValue: MythicGemsValue,
            RareminingTry: RareminingTry,
            UniqueminingTry: UniqueminingTry,
            EpicminingTry: EpicminingTry,
            LegendaryminingTry: LegendaryminingTry,
            MythicminingTry: MythicminingTry,
            RareGemsCooldownPeriod: RareGemsCooldownPeriod,
            UniqueGemsCooldownPeriod: UniqueGemsCooldownPeriod,
            EpicGemsCooldownPeriod: EpicGemsCooldownPeriod,
            LegendaryGemsCooldownPeriod: LegendaryGemsCooldownPeriod,
            MythicGemsCooldownPeriod: MythicGemsCooldownPeriod
        });

        // check if the color wished exists
        require(bytes(colorName[_color[0]][_color[1]]).length > 0, "this color does not exist");

        // Initialize variables for forged GEM properties
        uint8[4] memory forgedQuadrants;
        Rarity newRarity;
        uint256 forgedGemsCooldownDueDate;
        uint8 forgedGemsminingTry;
        uint256 forgedGemsValue;
        BackgroundColor memory _backgroundColor = getBackgroundColor(_color[0], _color[1], Rarity(uint8(_rarity) + 1));

        // Call the forgeTokens function from Gems contract
        (newGemId, forgedQuadrants, newRarity, forgedGemsValue, forgedGemsCooldownDueDate, forgedGemsminingTry) = Gems.forgeTokens(
            GEMIndexToOwner,
            ownershipTokenCount,
            msg.sender,
            _tokenIds,
            _rarity,
            _color,
            _backgroundColor,
            params
        );

        // Emit an event for the forged GEM
        emit GemForged(msg.sender, _tokenIds, newGemId, newRarity, forgedQuadrants, _color, _backgroundColor, forgedGemsValue);

        // Burn the old tokens
        burnTokens(msg.sender, _tokenIds);

        // Mint the new token
        _safeMint(msg.sender, newGemId);
        _setTokenURI(newGemId, ""); // Set empty URI for the new token

        // Emit another event for the created GEM
        emit Created(newGemId, newRarity, _color, _backgroundColor, forgedGemsminingTry, forgedGemsValue, forgedQuadrants, forgedGemsCooldownDueDate, "", msg.sender);

        return newGemId;
    }

        /**
     * @notice Burns tokens internally.
     * @param _from Address from which tokens are burned.
     * @param _tokenIds Array of token IDs to burn.
     */
    function burnTokens(address _from, uint256[] memory _tokenIds) internal {
        for(uint256 i = 0; i < _tokenIds.length; ++i) {
            // delete GEM from the Gems array and every other ownership/approve storage
            delete Gems[_tokenIds[i]];
            ownershipTokenCount[_from]--;
            delete GEMIndexToOwner[_tokenIds[i]];
            // ERC721 burn function
            _burn(_tokenIds[i]);
        }
    }

    /**
     * @notice computes the background color based on the color and rarity of the GEM
     * @param _index1 The first index of the color.
     * @param _index2 The second index of the color.
     * @param _rarity the rarity of the Gem for which we want to determine the background color
     * @return the background color associated
     */
    function getBackgroundColor(uint8 _index1, uint8 _index2, Rarity _rarity) internal view returns(BackgroundColor memory) {
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
        if(_rarity == Rarity.COMMON) {
            // the background for COMMON gems is predefined
            r_background = [25, 25];
            g_background = [26, 26];
            b_background = [34, 34];
            blur_background = 0;
        }
        else if(_rarity == Rarity.RARE) {
            dropShadow = false;
            blur_background = 0;
            if(sumOfcolor_r > sumOfcolor_g)  {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [127, 127];
                    if(sumOfcolor_g > sumOfcolor_b) {
                        // case r > g > b
                        b_background = [90, 90];
                        // g is a random value between 110 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 10);
                        g_background = [110 + middleValue, 110 + middleValue];
                    }
                    else {
                        // case r > b >= g
                        g_background = [90, 90];
                        // b is a random value between 110 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 10);
                        b_background = [110 + middleValue, 110 + middleValue];
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
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 10);
                        r_background = [110 + middleValue, 110 + middleValue];
                    }
                    else {
                        // case b > g >= r
                        r_background = [90, 90];
                        // g is a random value between 110 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 10);
                        g_background = [110 + middleValue, 110 + middleValue];
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
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 10);
                        r_background = [110 + middleValue, 110 + middleValue];
                    }
                    else {
                        // case g > b >= r
                        r_background = [90, 90];
                        // b is a random value between 110 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 10);
                        b_background = [110 + middleValue, 110 + middleValue];
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
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 10);
                        g_background = [110 + middleValue, 110 + middleValue];
                    }
                    else {
                        // case b > r >= g
                        g_background = [90, 90];
                        // r is a random value between 110 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 10);
                        r_background = [110 + middleValue, 110 + middleValue];
                    }
                }
            }

        }
        else if(_rarity == Rarity.UNIQUE) {
            dropShadow = false;
            blur_background = 0;
            if(sumOfcolor_r > sumOfcolor_g)  {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [150, 150];
                    if(sumOfcolor_g > sumOfcolor_b) {
                        // case r > g > b
                        b_background = [50, 50];
                        // g is a random value between 80 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        g_background = [80 + middleValue, 80 + middleValue];
                    }
                    else {
                        // case r > b >= g
                        g_background = [50, 50];
                        // b is a random value between 80 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        b_background = [80 + middleValue, 80 + middleValue];
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
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        r_background = [80 + middleValue, 80 + middleValue];
                    }
                    else {
                        // case b > g >= r
                        r_background = [50, 50];
                        // g is a random value between 80 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        g_background = [80 + middleValue, 80 + middleValue];
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
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        r_background = [80 + middleValue, 80 + middleValue];
                    }
                    else {
                        // case g > b >= r
                        r_background = [50, 50];
                        // b is a random value between 80 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        b_background = [80 + middleValue, 80 + middleValue];
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
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        g_background = [80 + middleValue, 80 + middleValue];
                    }
                    else {
                        // case b > r >= g
                        g_background = [50, 50];
                        // r is a random value between 80 and 120
                        uint8 middleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        r_background = [80 + middleValue, 80 + middleValue];
                    }
                }
            }
        }
        else if(_rarity == Rarity.EPIC) {
            dropShadow = false;
            blur_background = 0;

            if(sumOfcolor_r > sumOfcolor_g)  {
                if(sumOfcolor_r > sumOfcolor_b) {
                    r_background = [150, 100];
                    if(sumOfcolor_g > sumOfcolor_b) {
                        // case r > g > b
                        b_background = [50, 0];
                        // g1 is a random value between 80 and 120 g2 is a random value between 40 and 60
                        uint8 firstmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        uint8 secondmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 20);
                        g_background = [80 + firstmiddleValue, 40 + secondmiddleValue];
                    }
                    else {
                        // case r > b >= g
                        g_background = [50, 0];
                        // b is a random value between 80 and 120
                        uint8 firstmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        uint8 secondmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 20);
                        b_background = [80 + firstmiddleValue, 40 + secondmiddleValue];
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
                        uint8 firstmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        uint8 secondmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 20);
                        r_background = [80 + firstmiddleValue, 40 + secondmiddleValue];
                    }
                    else {
                        // case b > g >= r
                        r_background = [50, 0];
                        // g is a random value between 80 and 120
                        uint8 firstmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        uint8 secondmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 20);
                        g_background = [80 + firstmiddleValue, 40 + secondmiddleValue];
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
                        uint8 firstmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        uint8 secondmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 20);
                        r_background = [80 + firstmiddleValue, 40 + secondmiddleValue];
                    }
                    else {
                        // case g > b >= r
                        r_background = [50, 0];
                        // b is a random value between 80 and 120
                        uint8 firstmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        uint8 secondmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 20);
                        b_background = [80 + firstmiddleValue, 40 + secondmiddleValue];
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
                        uint8 firstmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        uint8 secondmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 20);
                        g_background = [80 + firstmiddleValue, 40 + secondmiddleValue];
                    }
                    else {
                        // case b > r >= g
                        g_background = [50, 0];
                        // r is a random value between 80 and 120
                        uint8 firstmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 40);
                        uint8 secondmiddleValue = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 20);
                        r_background = [80 + firstmiddleValue, 40 + secondmiddleValue];
                    }
                }
            }
        }
        else if(_rarity == Rarity.LEGENDARY) {
            dropShadow = true;
            blur_background = 25;
            r_background = r_color;
            g_background = g_color;
            b_background = b_color;

        }
        else if(_rarity == Rarity.MYTHIC) {
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
        BackgroundColor memory backgroundColor = BackgroundColor({
            r: r_background,
            g: g_background,
            b: b_background,
            blur: blur_background,
            dropShadow: dropShadow
        });
        return backgroundColor;
    }
}
