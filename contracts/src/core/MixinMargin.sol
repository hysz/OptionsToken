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
import "../libs/LibSafeMath.sol";
import "./MixinState.sol";
import "./MixinTokenState.sol";
import "./MixinOptionState.sol";
import "./MixinAssets.sol";


contract MixinMargin is
    MixinState,
    MixinTokenState,
    MixinOptionState,
    MixinAssets
{

    using LibSafeMath for uint256;

    function _setMarginTolerance(bytes32 optionId, uint256 tolerance)
        internal
    {
        _assertHoldsBothTokens(optionId, msg.sender);
        _assertOptionNotTethered(optionId);
        require(
            tolerance >= 0 && tolerance <= 100,
            "TOLERANCE_MUST_BE_PERCENTAGE"
        );
        marginToleranceByOptionId[optionId] = tolerance;
    }

    // Margin call an under-collateralized position (makerdao price oracle)
    function _marginCall(bytes32 optionId, LibOption.Option memory option)
        internal
    {
        require(
            _canMarginCall(optionId, option),
            "CANNOT_MARGIN_CALL"
        );

        // lookup counterparty
        (,bytes32 takerTokenId) = LibToken._getTokensFromOptionId(optionId);
        address taker = _getTokenOwner(takerTokenId);

        //send collateral to taker
        uint256 collateral = _getCollateral(optionId);
        _withdrawAsset(option.makerAsset, taker, collateral);

        // close option with state margin called
        _setOptionState(optionId, LibOption.OptionState.MARGIN_CALLED);
    }

    event EE(uint256 strikePrice, uint256 spotPrice);

    function _canMarginCall(bytes32 optionId, LibOption.Option memory option)
        internal
        //view
        returns (bool)
    {
        _assertOptionIdMatchesOption(optionId, option);
        _assertOptionIsPut(option);
        require(
            _isOptionOpen(optionId, option) || (_isOptionExpired(option) && _isOptionTethered(optionId)),
            "OPTION_MUST_BE_OPEN__OR__EXPIRED_AND_TETHERED"
        );

        uint256 strikePrice = LibOption._computeStrikePriceInUSD(option);
        uint256 spotPrice = _getEthSpotPriceInUsd();
        
        //uint256 opposingIntrinsicValue = spotPrice > strikePrice ? spotPrice - strikePrice : 0;
        //uint256 marginTolerance = marginToleranceByOptionId[optionId];
        //uint256 marginThreshold = (opposingIntrinsicValue._mul(100 + marginTolerance))._div(100);

        uint256 marginCallPrice = strikePrice;//strikePrice._add(marginThreshold);
        uint256 collateral = _getCollateral(optionId);
        if (marginCallPrice > spotPrice && collateral < marginCallPrice - spotPrice) {
            return true;
        }
        return false;
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
