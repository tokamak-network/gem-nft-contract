// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IMockL2WSTON.sol";

contract MockL2WSTON is ERC20, IMockL2WSTON {

    struct DepositTracker {
        uint256 stakingIndex;
        uint256 depositTime;
    }

    uint8 private _decimals;
    address public l2Bridge;
    address public l1Token;

    modifier onlyL2Bridge() {
        require(msg.sender == l2Bridge, "Only L2 Bridge can mint and burn");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint8 decimals_) ERC20(_name, _symbol) {
        _setupDecimals(decimals_);
        _mint(msg.sender, 1000000 * 10**uint256(decimals_)); // Mint 1,000,000 tokens to the deployer
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        bytes4 firstSupportedInterface = bytes4(keccak256("supportsInterface(bytes4)")); // ERC165
        bytes4 secondSupportedInterface = IMockL2WSTON.l1Token.selector ^
            IMockL2WSTON.mint.selector ^
            IMockL2WSTON.burn.selector;
        return _interfaceId == firstSupportedInterface || _interfaceId == secondSupportedInterface;
    }

    function mint(address _to, uint256 _amount) public virtual onlyL2Bridge {
        _mint(_to, _amount);

        emit Mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public virtual onlyL2Bridge {
        _burn(_from, _amount);

        emit Burn(_from, _amount);
    }

    function decodeStakingIndex(bytes memory data) public pure returns (DepositTracker memory) {
        DepositTracker memory depositTracker = abi.decode(data, (DepositTracker));
        return depositTracker;
    }


    //---------------------------------------------------------------------------------------
    //------------------------------INTERNAL/VIEW FUNCTIONS----------------------------------
    //---------------------------------------------------------------------------------------



    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}