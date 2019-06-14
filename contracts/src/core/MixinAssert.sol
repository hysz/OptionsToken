// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "./MixinState.sol";


contract MixinAssert is
    MixinState
{

    function _assertOptionNotTethered(bytes32 optionId)
        internal
    {
        require(
            tetherByOptionId[optionId] == 0,
            "OPTION_IS_TETHERED"
        );
    }
}