// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "../libs/LibOption.sol";
import "./MixinState.sol";


contract MixinOptionState is
    MixinState
{

    function _computeAmountToBeFullyCollateralized(bytes32 optionId, LibOption.Option memory option)
        internal
        view
        returns (uint256)
    {
        return option.makerAmount - collateralByOptionId[optionId];
    }

    function _isOptionFullyCollateralized(bytes32 optionId, LibOption.Option memory option)
        internal
        view
        returns (bool)
    {
        return _computeAmountToBeFullyCollateralized(optionId, option) == 0;
    }

    function _getOptionState(bytes32 optionId)
        internal
        view
        returns (LibOption.OptionState)
    {
        return optionStateById[optionId];
    }

    function _isOptionOpen(bytes32 optionId)
        internal
        view
        returns (bool)
    {
        return _getOptionState(optionId) == LibOption.OptionState.OPEN;
    }

    function _assertOptionIdMatchesOption(bytes32 optionId, LibOption.Option memory option)
        internal
        view
    {
        bytes32 optionHash = LibOption._hashOption(option);
        require(
            optionHashById[optionId] == optionHash,
            "OPTION_DOES_NOT_MATCH_OPTION_ID"
        );
    }

    function _assertOptionFullyCollateralized(bytes32 optionId, LibOption.Option memory option) internal view {
        require(
            _isOptionFullyCollateralized(optionId, option),
            "OPTION_NOT_FULLY_COLLATERALIZED"
        );
    }

    function _assignOptionToId(bytes32 optionId, LibOption.Option memory option) internal {
        bytes32 optionHash = LibOption._hashOption(option);
        optionHashById[optionId] = optionHash;
    }

    function _setOptionState(bytes32 optionId, LibOption.OptionState state) internal {
        optionStateById[optionId] = state;
    }

    function _assertOptionStateIsOpen(bytes32 optionId) internal view {
        require(
            optionStateById[optionId] == LibOption.OptionState.OPEN,
            "OPTION_NOT_OPEN"
        );
    }
}