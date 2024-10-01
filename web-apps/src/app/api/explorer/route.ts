"use server";
import { NextResponse } from 'next/server'
import { AvaCloudSDK} from "@avalabs/avacloud-sdk";
import { NativeTransaction, EvmBlock } from '@avalabs/avacloud-sdk/models/components';

const avaCloudSDK = new AvaCloudSDK({
    apiKey: process.env.GLACIER_API_KEY,
    chainId: "43114", // Avalanche Mainnet
    network: "mainnet",
  });
  
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const method = searchParams.get('method')
  try {
    let result
    switch (method) {
      case 'getRecentTransactions':
        result = await getRecentTransactions()
        break
      case 'getRecentBlocks':
        result = await getRecentBlocks()
        break
      default:
        return NextResponse.json({ error: 'Invalid method' }, { status: 400 })
    }
    return NextResponse.json(result)
  } catch (error) {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}


const getRecentBlocks = async () => {
    const result = await avaCloudSDK.data.evm.blocks.getLatestBlocks({
        pageSize: 1,
      });

    let count = 0;
    const blocks: EvmBlock[] = [];
    for await (const page of result) {
        if (count === 20) {
            break;
        }
        blocks.push(...page.result.blocks);
        count++;
    }
    return blocks
}

const getRecentTransactions = async () => {
    const result = await avaCloudSDK.data.evm.transactions.listLatestTransactions({
        pageSize: 3,
    });

    let count = 0;
    const transactions: NativeTransaction[] = [];
    for await (const page of result) {
        if (count === 20) {
            break;
        }
        transactions.push(...page.result.transactions);
        count++;
    }
    return transactions;
}