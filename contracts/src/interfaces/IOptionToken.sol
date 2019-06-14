// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../libs/LibOption.sol";
import "./IERC721.sol";


interface IOptionToken //is
    // IERC721
{

    function tokenize(LibOption.Option calldata option)
        external
        returns (
            bytes32 optionId,
            bytes32 makerTokenId,
            bytes32 takerTokenId
        );

    function cancelAndBurn(
        bytes32 optionId,
        LibOption.Option calldata option
    )
        external;

    function collateralize(
        bytes32 optionId,
        LibOption.Option calldata option,
        uint256 amount
    )
        external;

    function exercise(
        bytes32 optionId,
        LibOption.Option calldata option
    )
        external;
}
