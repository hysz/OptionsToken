// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "../libs/LibOption.sol";
import "./MixinState.sol";
import "./MixinTokenState.sol";
import "./MixinTether.sol";


contract MixinOptions is
    MixinState,
    MixinTokenState,
    MixinTether
{

    ///// OPTION MECHANICS /////

    function _collateralizeOption(
        bytes32 optionId,
        LibOption.Option memory option,
        uint256 amount
    )
        internal
    {
        // sanity checks
        _assertOptionIdMatchesOption(optionId, option);

        // 
        uint256 maxAmountAllowed = _computeAmountToBeFullyCollateralized();
        uint256 amountToDeposit = amount <= maxAmountAllowed ? amount : maxAmountAllowed;
        _depositAsset(option.makerAsset, amountToDeposit, msg.sender);
    }

    function _exerciseOption(
        bytes32 optionId,
        LibOption.Option memory option
    )
        internal
    {
        // sanity checks
        _assertOptionIdMatchesOption(optionId, option);
        _assertOptionNotTethered(optionId);
        _assertOptionFullyCollateralized(optionId, option);
        (bytes32 makerTokenId, bytes32 takerTokenId) = _getTokensFromOptionId(optionId);
        _assertTokenOwner(takerTokenId, msg.sender);
        _assertOptionIsOpen(optionId);

        // perform transfers
        transferFrom(ownerByTokenId[takerTokenId], ownerByTokenId[makerTokenId], option.takerAsset, option.takerAmount);
        transferTo(ownerByTokenId[takerTokenId], option.makerAsset, option.makerAmount);

        // update option state
        _setOptionStateToExercised(optionId);
    }

    // when tethered the options cannot be exercised
    function _tether(bytes32 leftOptionId, bytes32 rightOptionId)
        internal
    {
        _assertOptionOwner(leftOptionId, msg.sender);
        _assertOptionOwner(rightOptionId, msg.sender);
        _assertOptionNotTethered(leftOptionId);
        _assertOptionNotTethered(rightOptionId);

        tetherByOptionId[leftOptionId] = rightOptionId;
        tetherByOptionId[rightOptionId] = leftOptionId;
    }

     // can untether in two cases:
    // 1. Both are fully collateralized
    // 2. The options are expired
    function _untether(
        bytes32 leftOptionId,
        LibOption.Option memory leftOption,
        bytes32 rightOptionId,
        LibOption.Option memory rightOption
    )
        internal
    {
    
    }

    function _assertOptionNotTethered(bytes32 optionId)
        internal
    {
        require(
            tetherByOptionId[optionId] == 0,
            "OPTION_IS_TETHERED"
        );
    }

    

    function _computeAmountToBeFullyCollateralized(bytes32 optionId, LibOption.Option memory option)
        internal
        pure
    {
        return option.makerAmount - collateralByOptionId[optionId];
    }

    ///// CONVENIENCE FUNCTIONS FOR MANAGING & QUERYING STATE /////

    function _getOptionState(bytes32 optionId) internal pure {
        return optionStateById[optionId];
    }

    ///// ASSERTIONS /////

    function _assertOptionIdMatchesOption(bytes32 optionId, LibOption.Option memory option) internal pure {

    }
}