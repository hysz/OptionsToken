// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../libs/LibOption.sol";
import "./IERC721.sol";


interface IOptionToken /* is IERC721 */
{

    function tokenize(LibOption.Option calldata option)
        external
        returns (
            bytes32 optionId,
            bytes32 makerTokenId,
            bytes32 takerTokenId
        );

    function getTokenOwner(bytes32 tokenId)
        external
        view
        returns (address);

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

    function isFullyCollateralized(bytes32 optionId, LibOption.Option calldata option)
        external
        view
        returns (bool);

    function isOpen(bytes32 optionId, LibOption.Option calldata option)
        external
        view
        returns (bool);

    ///// ERC721 API - Defined in ./core/ERC721.sol /////
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 encodedTokenIds
    )
        external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 encodedTokenIds
    )
        external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 encodedTokenIds,
        bytes calldata
    )
        external;

    function getApproved(uint256 tokenId) external view returns (address);
    function approve(address approved, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
