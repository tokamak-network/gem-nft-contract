// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {GemFactoryStorage} from "./GemFactoryStorage.sol";

/**
 * @title GemFactory
 * @dev GemFactory handles the creation of GEMs. It allows for admin to premine GEMs for the treasury contract.
 * it also allows for users to mine forge and melt GEMs.
 */
contract GemFactory is GemFactoryStorage {
    function _createGEM(
        Rarity _rarity,
        string memory _color,
        uint256 _value,
        bytes4 _quadrants,
        address _owner
    ) internal returns (uint256) {
        Gem memory _Gem = Gem({
            tokenId: 0,
            rarity: _rarity,
            quadrants: _quadrants,
            color: _color,
            value: _value,
            owner: address(0)
        });
        Gems.push(_Gem);
        uint256 newGemId = Gems.length - 1;

        // safe check on the token Id created
        require(newGemId == uint256(uint32(newGemId)));
        _Gem.tokenId = uint32(newGemId);
        GEMIndexToOwner[newGemId] = _owner;
        ownershipTokenCount[_owner]++;

        emit Created(newGemId, _rarity, _quadrants, _color, _value, _owner);
        return newGemId;
    }

    function _transferGEM(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        ownershipTokenCount[_to]++;
        GEMIndexToOwner[_tokenId] = _to;
        ownershipTokenCount[_from]--;
        delete gemAllowedToAddress[_tokenId];
        delete GEMIndexToApproved[_tokenId];
    }
}
