// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../src/libs/LibOption.sol";
import "../src/libs/LibAsset.sol";
import "../src/interfaces/IOptionToken.sol";

import "./utils/ISettablePriceOracle.sol";
import "./utils/CounterParty.sol";
import "./utils/ITestERC20.sol";


contract OptionTokenTest {

    ISettablePriceOracle oracle;
    IOptionToken optionToken;
    ITestERC20 wethToken;
    ITestERC20 usdcToken;
    CounterParty counterParty;


    constructor(
        address _optionToken,
        address _oracle,
        address _wethToken,
        address _usdcToken
    )
        public
    {
        optionToken = IOptionToken(_optionToken);
        oracle = ISettablePriceOracle(_oracle);
        wethToken = ITestERC20(_wethToken);
        usdcToken = ITestERC20(_usdcToken);

        wethToken.init();
        usdcToken.init();

        wethToken.approve(address(optionToken), wethToken.totalSupply()/2);
        usdcToken.approve(address(optionToken), usdcToken.totalSupply()/2);
        counterParty = new CounterParty(address(optionToken), address(wethToken), address(usdcToken));
        wethToken.transfer(address(counterParty), wethToken.totalSupply()/2);
        usdcToken.transfer(address(counterParty), usdcToken.totalSupply()/2);
    }

    event E (
        bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId
    );

    function testMinting() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });
        
        {
            // tokenize it!
            (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);
            require(
                optionId == 0x0000000000000000000000000000000100000000000000000000000000000001,
                "BAD_OPTION_ID"
            );
            require(
                makerTokenId == 0x0000000000000000000000000000000100000000000000000000000000000000,
                "BAD_MAKER_ID"
            );
            require(
                takerTokenId == 0x0000000000000000000000000000000000000000000000000000000000000001,
                "BAD_TAKER_ID"
            );
            require(
                optionToken.getTokenOwner(makerTokenId) == address(this),
                "TAKER_TOKEN_BAD_OWNER"
            );
            require(
                optionToken.getTokenOwner(makerTokenId) == address(this),
                "TAKER_TOKEN_BAD_OWNER"
            );
        }

        {
            // tokenize it!
            (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);
            require(
                optionId == 0x0000000000000000000000000000000200000000000000000000000000000002,
                "BAD_OPTION_ID"
            );
            require(
                makerTokenId == 0x0000000000000000000000000000000200000000000000000000000000000000,
                "BAD_MAKER_ID"
            );
            require(
                takerTokenId == 0x0000000000000000000000000000000000000000000000000000000000000002,
                "BAD_TAKER_ID"
            );
            require(
                optionToken.ownerOf(uint256(makerTokenId)) == address(this),
                "TAKER_TOKEN_BAD_OWNER"
            );
            require(
                optionToken.ownerOf(uint256(makerTokenId)) == address(this),
                "TAKER_TOKEN_BAD_OWNER"
            );
        }
    }

    function testCollateralize() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // partially collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount - 1);
        require(
            wethToken.balanceOf(address(optionToken)) == option.makerAmount - 1,
            "DID_NOT_DEPOSIT"
        );

        // check collateral state
        require(
            optionToken.isFullyCollateralized(optionId, option) == false,
            "OPTION_SHOULD_NOT_BE_FULLY_COLLATERALIZED"
        );

        // fully collateralize it
        optionToken.collateralize(optionId, option, 1);
        require(
            wethToken.balanceOf(address(optionToken)) == option.makerAmount,
            "DID_NOT_DEPOSIT"
        );

        // check collateral state
        require(
            optionToken.isFullyCollateralized(optionId, option),
            "OPTION_SHOULD_BE_FULLY_COLLATERALIZED"
        );
    }

    function testCancelAndBurn() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // get my balance
        uint256 initBalance = wethToken.balanceOf(address(this));

        // collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount);

        // cancel it
        optionToken.cancelAndBurn(optionId, option);

        // check refund
        uint256 finalBalance = wethToken.balanceOf(address(this));
        require(
            finalBalance == initBalance,
            "DID_NOT_GET_REFUNDED"
        );

        // check cancelled
        require(
            optionToken.isOpen(optionId, option) == false,
            "OPTION_STILL_OPEN"
        );

        // check tokens burned
        require(
            optionToken.getTokenOwner(makerTokenId) == address(0),
            "MAKER_TOKEN_NOT_BURNED"
        );
        require(
            optionToken.getTokenOwner(takerTokenId) == address(0),
            "TAKER_TOKEN_NOT_BURNED"
        );
    }

    function testExerciseLongAmericanCall() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount);

        // give the taker token to our counterparty
        optionToken.transferFrom(
            address(this),
            address(counterParty),
            uint256(takerTokenId)
        );

        // get balances before exercise
        uint256 initMakerBalanceWeth = wethToken.balanceOf(address(this));
        uint256 initMakerBalanceUsdc = usdcToken.balanceOf(address(this));
        uint256 initTakerBalanceWeth = wethToken.balanceOf(address(counterParty));
        uint256 initTakerBalanceUsdc = usdcToken.balanceOf(address(counterParty));

        // exercise the option
        counterParty.exercise(optionId, option);

        // get balacnes after exercise
        uint256 finalMakerBalanceWeth = wethToken.balanceOf(address(this));
        uint256 finalMakerBalanceUsdc = usdcToken.balanceOf(address(this));
        uint256 finalTakerBalanceWeth = wethToken.balanceOf(address(counterParty));
        uint256 finalTakerBalanceUsdc = usdcToken.balanceOf(address(counterParty));
        
        // check that funds were swapped
        require(
            finalMakerBalanceWeth - initMakerBalanceWeth == 0, // maker had already collateralized 
            "UNEXPECTED_MAKER_WETH_BALANCE"
        );
        require(
            finalMakerBalanceUsdc - initMakerBalanceUsdc == option.takerAmount,
            "UNEXPECTED_MAKER_USDC_BALANCE"
        );
        require(
            finalTakerBalanceWeth - initTakerBalanceWeth == option.makerAmount,
            "UNEXPECTED_TAKER_WETH_BALANCE"
        );
        require(
            initTakerBalanceUsdc - finalTakerBalanceUsdc == option.takerAmount,
            "UNEXPECTED_TAKER_USDC_BALANCE"
        );

        // check that option is now closed
        require(
            optionToken.isOpen(optionId, option) == false,
            "OPTION_SHOULD_BE_CLOSED"
        );
   }

    function testExerciseByNotOwner() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount);

        // try to exercise when counterparty does not hold option
        counterParty.exercise(optionId, option);
    }

    function testExerciseAfterExpiry() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp - 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // try to exercise when counterparty does not hold option
        optionToken.exercise(optionId, option);
    }

    function testExerciseTwice() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // collateralize it
        optionToken.collateralize(optionId, option, option.makerAmount);

        // try to exercise when counterparty does not hold option
        optionToken.exercise(optionId, option);

        // try to exercise when counterparty does not hold option
        optionToken.exercise(optionId, option);
    }

    function testExerciseWithInsufficientCollateral() external {
        // create an option
        LibOption.Option memory option = LibOption.Option({
            optionType: LibOption.OptionType.AMERICAN_CALL,
            makerAsset: LibAsset.AssetType.WETH,
            takerAsset: LibAsset.AssetType.USDC,
            makerAmount: LibAsset._toBaseUnit(200),
            takerAmount: LibAsset._toBaseUnit(1),
            expirationTimeInSeconds: block.timestamp + 10000
        });

        // tokenize it!
        (bytes32 optionId, bytes32 makerTokenId, bytes32 takerTokenId) = optionToken.tokenize(option);

        // try to exercise when counterparty does not hold option
        optionToken.exercise(optionId, option);
    }

    function testSuccessfulMarginCall() external {

    }

    function testUnsuccessfulMarginCall() external {

    }

    function testSyntheticLong() external {

    }
}