import { RevertReason } from '@0x/types';
import { logUtils } from '@0x/utils';
import { NodeType } from '@0x/web3-wrapper';
import * as chai from 'chai';
import * as _ from 'lodash';

import { TransactionReceipt, TransactionReceiptStatus, TransactionReceiptWithDecodedLogs } from 'ethereum-types';

import {
    web3Wrapper
} from '@0x/contracts-test-utils';

const expect = chai.expect;

let nodeType: NodeType | undefined;

export type sendTransactionResult = Promise<TransactionReceipt | TransactionReceiptWithDecodedLogs | string>;

export async function expectTransactionFailedAsync(p: sendTransactionResult, reason: string): Promise<void> {
    // HACK(albrow): This dummy `catch` should not be necessary, but if you
    // remove it, there is an uncaught exception and the Node process will
    // forcibly exit. It's possible this is a false positive in
    // make-promises-safe.
    p.catch(e => {
        _.noop(e);
    });

    if (nodeType === undefined) {
        nodeType = await web3Wrapper.getNodeTypeAsync();
    }
    switch (nodeType) {
        case NodeType.Ganache:
            const rejectionMessageRegex = new RegExp(`^VM Exception while processing transaction: revert ${reason}$`);
            return expect(p).to.be.rejectedWith(rejectionMessageRegex);
        default:
            throw new Error(`Unknown node type: ${nodeType}`);
    }
}