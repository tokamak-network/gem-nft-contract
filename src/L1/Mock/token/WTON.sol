// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

// import { DSMath } from "../../../node_modules/coinage-token/contracts/lib/DSMath.sol";

import { ISeigManager } from "../../../interfaces/ISeigManager.sol";
import { ERC20OnApprove } from "./ERC20OnApprove.sol";
import { OnApprove } from "./OnApprove.sol";
import { TON } from "./TON.sol";


contract WTON is ReentrancyGuard, Ownable, ERC20, ERC20Burnable, OnApprove, ERC20OnApprove {
    using SafeERC20 for ERC20;

  TON public ton;

  event WtonMinted();
  event DepositManagerOnApproveData(address layer2);

  constructor (TON _ton) ERC20("Wrapped TON", "WTON") Ownable(msg.sender) {
    ton = _ton;
  }

    function decimals() public view virtual override returns (uint8) {
      return 27;
  }

    function mint(address _to, uint256 _amount) external returns(bool) {
        _mint(_to, _amount);
        emit WtonMinted();
        return true;
    }

  //////////////////////
  // TON Approve callback
  //////////////////////

  function onApprove(
    address owner,
    address /*spender*/,
    uint256 tonAmount,
    bytes calldata data
  ) external override returns (bool) {
    require(msg.sender == address(ton), "WTON: only accept TON approve callback");

    // swap owner's TON to WTON
    _swapFromTON(owner, owner, tonAmount);

    uint256 wtonAmount = _toRAY(tonAmount);
    (address depositManager, address layer2) = _decodeTONApproveData(data);

    // approve WTON to DepositManager
    _approve(owner, depositManager, wtonAmount);

    // call DepositManager.onApprove to deposit WTON
    bytes memory depositManagerOnApproveData = _encodeDepositManagerOnApproveData(layer2);
    emit DepositManagerOnApproveData(layer2);
    _callOnApprove(owner, depositManager, wtonAmount, depositManagerOnApproveData);

    return true;
  }

  /**
   * @dev data is 64 bytes of 2 addresses in left-padded 32 bytes
   */
  function _decodeTONApproveData(
    bytes memory data
  ) internal pure returns (address depositManager, address layer2) {
    require(data.length == 0x40);

    assembly {
      depositManager := mload(add(data, 0x20))
      layer2 := mload(add(data, 0x40))
    }
  }

  function _encodeDepositManagerOnApproveData(
    address layer2
  ) internal pure returns (bytes memory data) {
    data = new bytes(0x20);

    assembly {
      mstore(add(data, 0x20), layer2)
    }
  }


  //////////////////////
  // Override ERC20 functions
  //////////////////////

  function burnFrom(address account, uint256 amount) public override {
      _burn(account, amount);
  }

  //////////////////////
  // Swap functions
  //////////////////////

  /**
   * @dev swap WTON to TON
   */
  function swapToTON(uint256 wtonAmount) public nonReentrant returns (bool) {
    return _swapToTON(msg.sender, msg.sender, wtonAmount);
  }

  /**
   * @dev swap TON to WTON
   */
  function swapFromTON(uint256 tonAmount) public nonReentrant returns (bool) {
    return _swapFromTON(msg.sender, msg.sender, tonAmount);
  }

  /**
   * @dev swap WTON to TON, and transfer TON
   * NOTE: TON's transfer event's `from` argument is not `msg.sender` but `WTON` address.
   */
  function swapToTONAndTransfer(address to, uint256 wtonAmount) public nonReentrant returns (bool) {
    return _swapToTON(to, msg.sender, wtonAmount);
  }

  /**
   * @dev swap TON to WTON, and transfer WTON
   */
  function swapFromTONAndTransfer(address to, uint256 tonAmount) public nonReentrant returns (bool) {
    return _swapFromTON(msg.sender, to, tonAmount);
  }

  //////////////////////
  // Internal functions
  //////////////////////

  function _swapToTON(address tonAccount, address wtonAccount, uint256 wtonAmount) internal returns (bool) {
    _burn(wtonAccount, wtonAmount);

    // mint TON if WTON contract has not enough TON to transfer
    uint256 tonAmount = _toWAD(wtonAmount);
    uint256 tonBalance = ton.balanceOf(address(this));
    if (tonBalance < tonAmount) {
      ton.mint(address(this), tonAmount - tonBalance);
    }

    ton.transfer(tonAccount, tonAmount);
    return true;
  }

  function _swapFromTON(address tonAccount, address wtonAccount, uint256 tonAmount) internal returns (bool) {
    _mint(wtonAccount, _toRAY(tonAmount));
    ton.transferFrom(tonAccount, address(this), tonAmount);
    return true;
  }

  /**
   * @dev transform WAD to RAY
   */
  function _toRAY(uint256 v) internal pure returns (uint256) {
    return v * 10 ** 9;
  }

  /**
   * @dev transform RAY to WAD
   */
  function _toWAD(uint256 v) internal pure returns (uint256) {
    return v / 10 ** 9;
  }
}