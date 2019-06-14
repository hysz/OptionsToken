// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../../src/libs/LibOption.sol";
import "../../src/libs/LibAsset.sol";
import "../../src/interfaces/IOptionToken.sol";
import "../../src/OptionToken.sol";

import "./ERC20.sol";


contract CounterParty
{

    IOptionToken optionToken;

    IERC20 wethToken;
    IERC20 usdcToken;

    constructor(address _optionToken, address _wethToken, address _usdcToken) public {
        optionToken = IOptionToken(_optionToken);
        wethToken = IERC20(_wethToken);
        usdcToken = IERC20(_usdcToken);
        wethToken.approve(address(optionToken), wethToken.totalSupply() / 2);
        usdcToken.approve(address(optionToken), usdcToken.totalSupply() / 2);
    }

    function collateralize(bytes32 optionId, LibOption.Option calldata option, uint256 amount) external {
        optionToken.collateralize(optionId, option, amount);
    }

    function exercise(bytes32 optionId, LibOption.Option calldata option) external {
        optionToken.exercise(optionId, option);
    }
}