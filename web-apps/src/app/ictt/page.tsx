"use client"

import { ICTT, PoweredByAvalanche, Web3Provider } from "@0xstt/builderkit";
import { Info } from 'lucide-react';

import { CHAINS, TOKENS } from "./../constants";

export default function Home() {

    return (
        <Web3Provider appName="Flows - ICTT" projectId="YOUR_PROJECT_ID" chains={CHAINS}>
            <div className="grid grid-cols-12 text-white text-sm items-center">
                {/* ICTT Example */}
                <div className="col-span-12 flows-bg w-full h-screen">
                    <div className="flex flex-col w-full h-full justify-center items-center gap-4">
                        <ICTT tokens={TOKENS} token_in="0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d" source_chain_id={43113} destination_chain_id={173750}></ICTT>
                        <a className="flex items-center gap-2 text-white hover:underline" href="https://academy.avax.network/course/interchain-token-transfer" target="_blank">
                            <Info size={16} />
                            <p className="text-xs">What is ICTT?</p>
                        </a>
                        <a className="w-[120px]" href="https://subnets.avax.network/" target="_blank">
                            <PoweredByAvalanche className={"w-full h-full"}></PoweredByAvalanche>
                        </a>
                    </div>
                </div>
            </div>
        </Web3Provider>
    );
}
