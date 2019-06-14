// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "../libs/LibToken.sol";
import "./MixinState.sol";


contract MixinMargin is
    MixinState
{

  /*
    function _setCollateralizationTolerance(bytes32 optionId, uint256 tolerance)
        internal
    {
        _assertOptionOwner(optionId, msg.sender);
        _assertOptionNotTethered(optionId);
        collateralizationToleranceByOptionId[leftOptionId] = tolerance;
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

    */
}
