"use client"

import { Faucet, PoweredByAvalanche, Web3Provider } from "@0xstt/builderkit";
import { CHAINS, TOKENS } from "./../constants";

export default function Home() {

    return (
        <Web3Provider appName="Flows - Faucet" projectId="YOUR_PROJECT_ID" chains={CHAINS}>
            <div className="grid grid-cols-12 text-white text-sm items-center">
                {/* Faucet Example */}
                <div className="col-span-12 flows-bg w-full h-screen">
                    <div className="flex flex-col w-full h-full justify-center items-center gap-4">
                        <Faucet tokens={TOKENS}></Faucet>
                        <a className="w-[120px]" href="https://subnets.avax.network/" target="_blank">
                            <PoweredByAvalanche className={"w-full h-full"}></PoweredByAvalanche>
                        </a>
                    </div>
                </div>
            </div>
        </Web3Provider>
    );
}
