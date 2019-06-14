// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;

pragma experimental ABIEncoderV2;

import "../libs/LibOption.sol";
import "./MixinTokenState.sol";
import "./MixinOptionState.sol";
import "./MixinState.sol";


contract MixinTether is
    MixinState,
    MixinTokenState,
    MixinOptionState
{

    // when tethered the options cannot be exercised
    function _tether(
        bytes32 leftOptionId,
        LibOption.Option memory leftOption,
        bytes32 rightOptionId,
        LibOption.Option memory rightOption
    )
        internal
    {
        _assertOptionIdMatchesOption(leftOptionId, leftOption);
        _assertOptionIdMatchesOption(rightOptionId, rightOption);
        _assertHoldsBothTokens(leftOptionId, msg.sender);
        _assertHoldsBothTokens(rightOptionId, msg.sender);
        _assertOptionNotTethered(leftOptionId);
        _assertOptionNotTethered(rightOptionId);
        _assertOptionIsCall(leftOption);
        _assertOptionIsPut(rightOption);
        _assertOptionStateIsOpen(leftOptionId, leftOption);
        _assertOptionStateIsOpen(rightOptionId, rightOption);
        _assertOptionFullyCollateralized(leftOptionId, leftOption); // only the left (call) option must be collateralized
        require(
            leftOption.makerAsset == rightOption.takerAsset && leftOption.takerAsset == rightOption.makerAsset,
            "OPTIONS_MUST_HAVE_COMPLEMENTARY_ASSET_TYPES"
        );
        // validate strike prices are the same
        require(
            leftOption.takerAmount * rightOption.takerAmount == leftOption.makerAmount * rightOption.makerAmount,
            "OPTIONS_MUST_HAVE_THE_SAME_STRIKE_PRICE"
        );

        // @TODO - the PUT option should be European so that the issuer can't exercise the PUT prematurely
        //         However, I don't think this is an issue because we prevent from exercising if not fully collateralized.

        // tether
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
        _assertOptionIdMatchesOption(leftOptionId, leftOption);
        _assertOptionIdMatchesOption(rightOptionId, rightOption);
        _assertOptionsAreTethered(leftOptionId, rightOptionId);
        require(
           (_isOptionOpen(leftOptionId, leftOption) || _isOptionOpen(rightOptionId, rightOption)) && !_isOptionFullyCollateralized(rightOptionId, rightOption),
            "ONE_OR_BOTH_OPTIONS_ARE_STILL_OPEN_AND_UNCOLLATERALIZED"
        );

        // untether
        tetherByOptionId[leftOptionId] = 0;
        tetherByOptionId[rightOptionId] = 0;
    }
}
