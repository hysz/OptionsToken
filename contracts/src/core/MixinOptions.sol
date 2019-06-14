// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "./MixinState.sol";


contract MixinOptions is
    MixinState
{

    function _computeAmountToBeFullyCollateralized(bytes32 optionId, LibOption.Option memory option)
        internal
        pure
    {
        return option.makerAmount - collateralByOptionId[optionId];
    }

    function _getOptionState(bytes32 optionId) internal pure {
        return optionStateById[optionId];
    }

    function _collateralize(
        bytes32 optionId,
        LibOption.Option calldata option,
        uint256 amount
    )
        internal
    {
        _assertOptionIdMatchesOption(optionId, option);
        uint256 maxAmountAllowed = _computeAmountToBeFullyCollateralized();
        uint256 amountToDeposit = amount <= maxAmountAllowed ? amount : maxAmountAllowed;
        _depositAsset(option.makerAsset, amountToDeposit, msg.sender);
    }

    function _exercise(
        bytes32 optionId,
        LibOption.Option calldata option
    )
        internal
    {
        _assertOptionIdMatchesOption(optionId, option);
        _assertOptionNotTethered(optionId);
        _assertOptionFullyCollateralized(optionId, option);
        bytes32 (makerTokenId, takerTokenId) = _getTokensFromOptionId(optionId);
        _assertTokenOwner(takerTokenId, msg.sender);
        _assertOptionIsOpen(optionId);

        // perform transfers
        transferFrom(ownerByTokenId[takerTokenId], ownerByTokenId[makerTokenId], option.takerAsset, option.takerAmount);
        transferTo(ownerByTokenId[takerTokenId], option.makerAsset, option.makerAmount);

        // update option state
        _setOptionStateToExercised(optionId);
    }
    
    function _cancel(bytes32 optionId)
        internal
    {
        _assertOptionOwner(optionId, msg.sender);
        transferTo(msg.sender, option.makerAsset, option.makerAmount);
        _setOptionStateToCancelled(optionId);
    }
   
}