import {
    chaiSetup,
    provider,
    txDefaults,
    web3Wrapper,
} from '@0x/contracts-test-utils';
import { BlockchainLifecycle } from '@0x/dev-utils';
import * as chai from 'chai';
import * as _ from 'lodash';
import { LogWithDecodedArgs } from 'ethereum-types';
import { LogDecoder } from '@0x/contracts-test-utils';

import {
    artifacts,
    OptionTokenTestContract,
    OptionTokenContract,
    PriceOracleContract,
    ERC20Contract,
    
} from '../src';

import { expectTransactionFailedAsync } from './utils/tx';
import { BigNumber } from '@0x/utils';

chaiSetup.configure();
const expect = chai.expect;
const blockchainLifecycle = new BlockchainLifecycle(web3Wrapper);




// tslint:disable:no-unnecessary-type-assertion
describe('OptionTokenTest', () => {
    let logDecoder: LogDecoder;
    let testContract: OptionTokenTestContract;

    
    // tests
    before(async () => {
        await blockchainLifecycle.startAsync();
    });
    after(async () => {
        await blockchainLifecycle.revertAsync();
    });
    before(async () => {
        logDecoder = new LogDecoder(web3Wrapper, artifacts);

 
        const priceOracleContract = await PriceOracleContract.deployFrom0xArtifactAsync(
            artifacts.PriceOracle,
            provider,
            txDefaults,
            new BigNumber(0)
        );

        const wethContract = await ERC20Contract.deployFrom0xArtifactAsync(
            artifacts.ERC20,
            provider,
            txDefaults,
        );

        const usdcContract = await ERC20Contract.deployFrom0xArtifactAsync(
            artifacts.ERC20,
            provider,
            txDefaults,
        );

        const optionTokenContract = await OptionTokenContract.deployFrom0xArtifactAsync(
            artifacts.OptionToken,
            provider,
            txDefaults,
            priceOracleContract.address,
            wethContract.address,
            usdcContract.address
        );


        testContract = await OptionTokenTestContract.deployFrom0xArtifactAsync(
            artifacts.OptionTokenTest,
            provider,
            txDefaults,
            optionTokenContract.address,
            priceOracleContract.address,
            wethContract.address,
            usdcContract.address
        );
    });
    beforeEach(async () => {
        await blockchainLifecycle.startAsync();
    });
    afterEach(async () => {
        await blockchainLifecycle.revertAsync();
    });
    describe('safeTransferFrom', () => {
        it('should mint multiple', async () => {
           const txReceipt = await logDecoder.getTxWithDecodedLogsAsync(await testContract.testMinting.sendTransactionAsync({gas: 3000000}));
           console.log(JSON.stringify(txReceipt.logs, null, 4));
        });

        it('should collateralize', async () => {
            const txReceipt = await logDecoder.getTxWithDecodedLogsAsync(await testContract.testCollateralize.sendTransactionAsync({gas: 3000000}));
            console.log(JSON.stringify(txReceipt.logs, null, 4));
        });

        it('should cancel & burn', async () => {
            const txReceipt = await logDecoder.getTxWithDecodedLogsAsync(await testContract.testCancelAndBurn.sendTransactionAsync({gas: 3000000}));
            console.log(JSON.stringify(txReceipt.logs, null, 4));
        });

        it('should exercise american call', async () => {
            const txReceipt = await logDecoder.getTxWithDecodedLogsAsync(await testContract.testExerciseLongAmericanCall.sendTransactionAsync({gas: 3000000}));
            console.log(JSON.stringify(txReceipt.logs, null, 4));
         });

         it('should fail to exercise by not owner', async () => {
            await expectTransactionFailedAsync(
                testContract.testExerciseByNotOwner.sendTransactionAsync(),
                "OWNER_DOES_NOT_HOLD_TOKEN"
            );
         });

         it('should fail to exercise after expiry', async () => {
            await expectTransactionFailedAsync(
                testContract.testExerciseAfterExpiry.sendTransactionAsync(),
                "OPTION_NOT_OPEN"
            );
         });

         it('should fail to exercise twice', async () => {
            await expectTransactionFailedAsync(
                testContract.testExerciseTwice.sendTransactionAsync(),
                "OPTION_NOT_OPEN"
            );
         });

         it('should fail to exercise if option is not collateralized', async () => {
            await expectTransactionFailedAsync(
                testContract.testExerciseWithInsufficientCollateral.sendTransactionAsync(),
                "OPTION_NOT_FULLY_COLLATERALIZED"
            );
         });

         it('should successfully margin call at collateralization threshold', async () => {
            const txReceipt = await logDecoder.getTxWithDecodedLogsAsync(await testContract.testSuccessfulMarginCall.sendTransactionAsync({gas: 3000000}));
            console.log(JSON.stringify(txReceipt.logs, null, 4));
         });

         it('should fail to margin call outside of the collatearlization threshold', async () => {
            await expectTransactionFailedAsync(
                testContract.testUnsuccessfulMarginCall.sendTransactionAsync(),
                "OPTION_NOT_FULLY_COLLATERALIZED"
            );
         });

         it('should create synthetic long positions', async () => {
            await expectTransactionFailedAsync(
                testContract.testSyntheticLong.sendTransactionAsync(),
                "OPTION_NOT_FULLY_COLLATERALIZED"
            );
         });
    });
});
// tslint:enable:no-unnecessary-type-assertion