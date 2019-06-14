// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "./MixinState.sol";


contract MixinTether is
    MixinState
{



    // can untether in two cases:
    // 1. Both are fully collateralized
    // 2. The options are expired
    function _untether(
        bytes32 leftOptionId,
        LibOption.Option calldata leftOption,
        bytes32 rightOptionId,
        LibOption.Option calldata rightOption
    )
        internal
    {
        
    }


     function _setCollateralizationTolerance(bytes32 optionId, uint256 tolerance)
        internal
    {
        _assertOptionOwner(optionId, msg.sender);
        _assertOptionNotTethered(optionId);
        collateralizationToleranceByOptionId[leftOptionId] = tolerance;
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

    // Margin call an under-collateralized position (makerdao price oracle)
    function _marginCall(LibOption.Option calldata option)
        internal
    {

    }

    function _canMarginCall(LibOption.Option calldata option)
        internal
    {

    }
}
