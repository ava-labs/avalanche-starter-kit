import { NextResponse } from "next/server";

import {
    CHAINS
} from './../../../constants'

import { Wallet } from "ethers";

export async function GET() {
    const fauced_supported_chains = CHAINS.filter((c: any) => c.faucet !== undefined);
    return NextResponse.json({
        chains: fauced_supported_chains.map((c: any) => {
            const { id, blockExplorers, faucet } = c;
            const pk = process.env[`PK_${id}`];
            if (pk === undefined) {
                return;
            }
            const wallet = new Wallet(pk);
            faucet.address = wallet.address;
            return { id, blockExplorers, faucet };
        })
    });
}