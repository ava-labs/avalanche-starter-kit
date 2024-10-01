"use server";
import { NextResponse } from 'next/server'
import { AvaCloudSDK} from "@avalabs/avacloud-sdk";
import { Erc721TokenBalance } from '@avalabs/avacloud-sdk/models/components/erc721tokenbalance';
import { Erc1155TokenBalance } from '@avalabs/avacloud-sdk/models/components/erc1155tokenbalance';
import { TransactionDetails } from '@avalabs/avacloud-sdk/models/components/transactiondetails';

const avaCloudSDK = new AvaCloudSDK({
    apiKey: process.env.GLACIER_API_KEY,
    chainId: "43114", // Avalanche Mainnet
    network: "mainnet",
  });
  
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const method = searchParams.get('method')
  let address
  try {
    let result
    switch (method) {
      case 'listERC721Balances':
        address = searchParams.get('address')!
        result = await listERC721Balances(address)
        break
      case 'listERC1155Balances':
        address = searchParams.get('address')!
        result = await listErc1155Balances(address)
        break
      case 'listRecentTransactions':
        address = searchParams.get('address')!
        result = await listRecentTransactions(address)
        break
      default:
        return NextResponse.json({ error: 'Invalid method' }, { status: 400 })
    }
    return NextResponse.json(result)
  } catch (error) {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}

async function getBlockHeight() {
    const result = await avaCloudSDK.data.evm.blocks.getLatestBlocks({
        pageSize: 1,
      });
    return Number(result.result.blocks[0].blockNumber)
}

const listERC721Balances = async (address: string) => {
    const result = await avaCloudSDK.data.evm.balances.listErc721Balances({
        pageSize: 10,
        address: address,
      });
    const balances: Erc721TokenBalance[] = [];
    for await (const page of result) {
        balances.push(...page.result.erc721TokenBalances);
    }
    return balances
}

const listErc1155Balances = async (address: string) => {
    const result = await avaCloudSDK.data.evm.balances.listErc1155Balances({
        pageSize: 10,
        address: address,
      });
    const balances: Erc1155TokenBalance[] = [];
    for await (const page of result) {
        balances.push(...page.result.erc1155TokenBalances);
    }
    return balances
}

const listRecentTransactions = async (address: string) => {
    const blockHeight = await getBlockHeight()
    const result = await avaCloudSDK.data.evm.transactions.listTransactions({
        pageSize: 10,
        startBlock: blockHeight - 100000,
        endBlock: blockHeight,
        address: address,
        sortOrder: "desc",
      });
    const transactions: TransactionDetails = {
        erc20Transfers: [],
        erc721Transfers: [],
        erc1155Transfers: [],
        nativeTransaction: {
            blockNumber: '',
            blockTimestamp: 0,
            blockHash: '',
            blockIndex: 0,
            txHash: '',
            txStatus: '',
            txType: 0,
            gasLimit: '',
            gasUsed: '',
            gasPrice: '',
            nonce: '',
            from: {
                name: undefined,
                symbol: undefined,
                decimals: undefined,
                logoUri: undefined,
                address: ''
            },
            to: {
                name: undefined,
                symbol: undefined,
                decimals: undefined,
                logoUri: undefined,
                address: ''
            },
            value: ''
        },
    }
    for await (const page of result) {
        for (const transaction of page.result.transactions) {
            if (transaction.erc20Transfers) {
                if (transactions.erc20Transfers) {
                    transactions.erc20Transfers.push(...transaction.erc20Transfers);
                }
            } 
            else if (transaction.erc721Transfers) {
                if (transactions.erc721Transfers) {
                    transactions.erc721Transfers.push(...transaction.erc721Transfers);
                }
            }
            else if (transaction.erc1155Transfers) {
                if (transactions.erc1155Transfers) {
                    transactions.erc1155Transfers.push(...transaction.erc1155Transfers);
                }
            }
        }
    }
    return transactions
}