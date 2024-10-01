"use server";
import { NextResponse } from 'next/server'
import { AvaCloudSDK} from "@avalabs/avacloud-sdk";
import { Erc20TokenBalance } from '@avalabs/avacloud-sdk/models/components/erc20tokenbalance';

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
      case 'getBlockHeight':
        result = await getBlockHeight()
        break
      case 'listErc20Balances':
        const address: string = searchParams.get('address')!
        const blockNumber: string = searchParams.get('blockNumber')!
        result = await listErc20Balances(address, blockNumber);
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
    return result.result.blocks[0].blockNumber
}

async function listErc20Balances(address: string, blockNumber: string) {
    const result = await avaCloudSDK.data.evm.balances.listErc20Balances({
        blockNumber: blockNumber,
        pageSize: 10,
        address: address,
      });
    const balances: Erc20TokenBalance[] = [];
    for await (const page of result) {
        balances.push(...page.result.erc20TokenBalances);
    }
    return balances
}
