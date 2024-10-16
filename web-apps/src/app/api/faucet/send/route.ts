import { CHAINS } from "./../../../constants";
import { NextRequest, NextResponse } from "next/server";
import { Chain, erc20Abi, isAddress, toHex } from "viem";
import { ethers, Wallet } from "ethers";
import { BigNumber } from "bignumber.js";
import { rateLimiter } from "./../../../utils/RateLimiter";

const getFaucetBalance = async (chain: any, address: string, wallet: Wallet) => {
    let rpc_url = chain.rpcUrls.default.http[0];
    let provider = new ethers.JsonRpcProvider(rpc_url, { chainId: chain.id, name: "NW" });
    let balance;
    if (address === "native") {
        balance = await provider.getBalance(wallet.address);
    } else {
        const contract = new ethers.Contract(address, erc20Abi, provider);
        balance = await contract.balanceOf(wallet);
    }
    return new BigNumber(balance.toString());
}

const getFeeData = async (chain: any) => {
    let rpc_url = chain.rpcUrls.default.http[0];
    let provider = new ethers.JsonRpcProvider(rpc_url, { chainId: chain.id, name: "NW" });
    return await provider.getFeeData();
}

const send = async (chain: any, address: string, wallet: Wallet, receiver: string, amount: BigNumber) => {
    let fee_data = await getFeeData(chain);
    if (fee_data.gasPrice === null) {
        throw new Error("TransactionSender cound not fetch the actual fee data.");
    }
    let adjusted_gas_price = BigInt(new BigNumber(fee_data.gasPrice.toString()).times(1.25).toFixed(0));
    if (address === "native") {
        const transaction = await wallet.sendTransaction({
            to: receiver,
            value: amount.toString(),
            gasPrice: toHex(adjusted_gas_price),
            gasLimit: 21000
        });
        return transaction.hash;
    } else {
        const intf = new ethers.Interface(erc20Abi);
        const amount_hex = toHex(BigInt(amount.toFixed(0)));
        let data = intf.encodeFunctionData("transfer", [receiver, amount_hex]);
        const transaction = await wallet.sendTransaction({
            to: address,
            value: '0x0',
            gasPrice: toHex(adjusted_gas_price),
            gasLimit: 65000,
            data: data
        });
        return transaction.hash;
    }
}

export async function POST(req: NextRequest) {
    const body = await req.json();
    const { chain_id, address, receiver } = body;
    // Check parameters
    if (chain_id === undefined || (address !== "native" && isAddress(address) === false) || isAddress(receiver) === false) {
        return NextResponse.json({ message: 'Invalid parameters passed!' }, { status: 400 });
    }
    // Check chain is supporting faucet
    const fauced_supported_chains = CHAINS.filter((c: any) => c.faucet !== undefined);
    const chain: any = fauced_supported_chains.find(c => c.id === chain_id);
    if (chain === undefined) {
        return NextResponse.json({ message: 'Faucet config cannot be found!' }, { status: 400 });
    }
    // Check faucet is supporting asset
    const { faucet } = chain;
    const asset = faucet.assets.find((a: any) => a.address === address);
    if (asset === undefined) {
        return NextResponse.json({ message: 'Asset config cannot be found!' }, { status: 400 });
    }
    const { decimals, drip_amount, rate_limit } = asset;
    // Check rate limit
    const client_ip = req.headers.get('x-forwarded-for') || req.ip || 'unknown';
    const { max_limit, window_size } = rate_limit;
    if (rateLimiter(client_ip, max_limit, window_size) === false) {
        return NextResponse.json({ message: 'Too many requests, please try again later.' }, { status: 429 });
    }
    // Get faucet wallet
    const pk = process.env[`PK_${chain.id}`];
    if (pk === undefined) {
        return NextResponse.json({ message: 'Faucet wallet cannot be found!' }, { status: 400 });
    }
    let rpc_url = chain.rpcUrls.default.http[0];
    let provider = new ethers.JsonRpcProvider(rpc_url, { chainId: chain.id, name: "NW" });
    const wallet = new Wallet(pk, provider);
    // Get faucet asset balance
    const balance = await getFaucetBalance(chain, address, wallet);
    // Check drip amount bigger than faucet balance
    const drip_amount_bn = new BigNumber(drip_amount).times(10 ** decimals);
    if (drip_amount_bn.gte(balance)) {
        return NextResponse.json({ message: 'Faucet balance is not enough!' }, { status: 400 });
    }
    // Send asset
    try {
        const hash = await send(chain, address, wallet, receiver, drip_amount_bn);
        return NextResponse.json({ hash });
    } catch (err) {
        return NextResponse.json({ message: err }, { status: 400 });
    }
}