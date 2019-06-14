// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "../libs/LibOption.sol";
import "../libs/LibSafeMath.sol";
import "./MixinState.sol";
import "./MixinTokenState.sol";
import "./MixinOptionState.sol";
import "./MixinAssets.sol";


contract MixinOptionMechanics is
    MixinState,
    MixinTokenState,
    MixinOptionState,
    MixinAssets
{

    using LibSafeMath for uint256;

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
        _assertOptionStateIsOpen(optionId, option);

        // check that we won't deposit too much
        require(
            amount <= _computeAmountToBeFullyCollateralized(optionId, option),
            "CANNOT_OVERCOLLATERALIZE_OPTION"
        );

        // deposit & record collateral
        _depositAsset(
            option.makerAsset,
            msg.sender,
            amount
        );
        collateralByOptionId[optionId] = collateralByOptionId[optionId]._add(amount);
    }

    function _exerciseOption(
        bytes32 optionId,
        LibOption.Option memory option
    )
        internal
    {
        // sanity checks
        _assertOptionIdMatchesOption(optionId, option);
        _assertOptionStateIsOpen(optionId, option);
        _assertOptionFullyCollateralized(optionId, option);
        (bytes32 makerTokenId, bytes32 takerTokenId) = LibToken._getTokensFromOptionId(optionId);
        _assertTokenOwner(takerTokenId, msg.sender);
        _assertOptionNotTethered(optionId);

        // perform transfers
        _transferAsset(
            option.takerAsset,              // asset
            ownerByTokenId[takerTokenId],   // from
            ownerByTokenId[makerTokenId],   // to
            option.takerAmount              // amount
        );
        _withdrawAsset(
            option.makerAsset,              // asset
            ownerByTokenId[takerTokenId],   // to
            option.makerAmount              // amount
        );

        // record that the option is no longer collateralized
        collateralByOptionId[optionId] = collateralByOptionId[optionId]._sub(option.makerAmount);

        // update option state
        _setOptionState(optionId, LibOption.OptionState.EXERCISED);
    }

    function _cancelOption(bytes32 optionId, LibOption.Option memory option)
        internal
    {
        // sanity checks
        _assertOptionIdMatchesOption(optionId, option);
        _assertOptionStateIsOpen(optionId, option);
        _assertHoldsBothTokens(optionId, msg.sender);

        // return underlying asset to holder
        _withdrawAsset(
            option.makerAsset,
            msg.sender,
            option.makerAmount
        );

        // update state
        _setOptionState(optionId, LibOption.OptionState.CANCELLED);
    }
}
