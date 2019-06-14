// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../libs/LibOption.sol";
import "../libs/LibToken.sol";
import "../libs/LibAsset.sol";
import "./MixinState.sol";
import "./MixinTokenState.sol";
import "./MixinOptionState.sol";


contract MixinMargin is
    MixinState,
    MixinTokenState,
    MixinOptionState
{

    function _setMarginTolerance(bytes32 optionId, uint256 tolerance)
        internal
    {
        _assertHoldsBothTokens(optionId, msg.sender);
        _assertOptionNotTethered(optionId);
        marginToleranceByOptionId[optionId] = tolerance;
    }

    // Margin call an under-collateralized position (makerdao price oracle)
    function _marginCall(bytes32 optionId, LibOption.Option memory option)
        internal
    {

    }

    function _canMarginCall(bytes32 optionId, LibOption.Option memory option)
        internal
        view
        returns (bool)
    {
        
    }

    function _getEthSpotPriceInUsd()
        internal
        view
        returns (uint256)
    {
        (bytes32 price,) = priceOracle.compute();
        return uint256(price);
    }

    function _getUsdSpotPriceInEth()
        internal
        view
        returns (uint256)
    {
        (bytes32 price,) = priceOracle.compute();
        uint256 inversePrice = 1 / uint256(price);
        return inversePrice;
    }
}
