"use client"

import { avalanche, avalancheFuji } from "wagmi/chains";
import { echo } from "./../../chains/definitions/echo";
import { dispatch } from "./../../chains/definitions/dispatch";

import { ICTT, PoweredByAvalanche, Web3Provider } from "@0xstt/avalanche-builderkit";
import { Info } from 'lucide-react';

export default function Home() {

    const teleporter_messenger = "0x253b2784c75e510dd0ff1da844684a1ac0aa5fcf";

    const chains = [avalanche, avalancheFuji, echo, dispatch];

    const tokens = [
        {
            address: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
            name: "TOK",
            symbol: "TOK",
            decimals: 18,
            chain_id: 43113,
            supports_ictt: true,
            transferer: "0xD63c60859e6648b20c38092cCceb92c5751E32fF",
            mirrors: [
                {
                    address: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
                    transferer: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
                    chain_id: 173750,
                    decimals: 18
                }
            ]
        },
        {
            address: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
            name: "TOK.e",
            symbol: "TOK.e",
            decimals: 18,
            chain_id: 173750,
            supports_ictt: true,
            is_transferer: true,
            mirrors: [
                {
                    home: true,
                    address: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
                    transferer: "0xD63c60859e6648b20c38092cCceb92c5751E32fF",
                    chain_id: 43113,
                    decimals: 18
                }
            ]
        },
        {
            address: "0xD737192fB95e5D106a459a69Faec4a7bD38c2A17",
            name: "STT",
            symbol: "STT",
            decimals: 18,
            chain_id: 43113,
            supports_ictt: true,
            transferer: "0x8a6A0605556ec621EB75F27954C32f048B51d8e9",
            mirrors: [
                {
                    address: "0x96cA8090Ab3748C0697058C06FBdcF0813Cd9576",
                    transferer: "0x96cA8090Ab3748C0697058C06FBdcF0813Cd9576",
                    chain_id: 173750,
                    decimals: 18
                },
                {
                    address: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
                    transferer: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
                    chain_id: 779672,
                    decimals: 18
                }
            ]
        },
        {
            address: "0x96cA8090Ab3748C0697058C06FBdcF0813Cd9576",
            name: "STT.e",
            symbol: "STT.e",
            decimals: 18,
            chain_id: 173750,
            supports_ictt: true,
            is_transferer: true,
            mirrors: [
                {
                    home: true,
                    address: "0xD737192fB95e5D106a459a69Faec4a7bD38c2A17",
                    transferer: "0x8a6A0605556ec621EB75F27954C32f048B51d8e9",
                    chain_id: 43113,
                    decimals: 18
                },
                {
                    address: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
                    transferer: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
                    chain_id: 779672,
                    decimals: 18
                }
            ]
        },
        {
            address: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
            name: "STT.d",
            symbol: "STT.d",
            decimals: 18,
            chain_id: 779672,
            supports_ictt: true,
            is_transferer: true,
            mirrors: [
                {
                    home: true,
                    address: "0xD737192fB95e5D106a459a69Faec4a7bD38c2A17",
                    transferer: "0x8a6A0605556ec621EB75F27954C32f048B51d8e9",
                    chain_id: 43113,
                    decimals: 18
                },
                {
                    address: "0x96cA8090Ab3748C0697058C06FBdcF0813Cd9576",
                    transferer: "0x96cA8090Ab3748C0697058C06FBdcF0813Cd9576",
                    chain_id: 173750,
                    decimals: 18
                }
            ]
        }
    ];

    return (
        <Web3Provider appName="Flows - ICTT" projectId="YOUR_PROJECT_ID" chains={chains}>
            <div className="grid grid-cols-12 text-white text-sm items-center">
                {/* ICTT Example */}
                <div className="col-span-12 flows-bg w-full h-screen">
                    <div className="flex flex-col w-full h-full justify-center items-center gap-4">
                        <ICTT teleporter_messenger={teleporter_messenger} tokens={tokens} token_in="0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d" source_chain_id={43113} destination_chain_id={173750}></ICTT>
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
