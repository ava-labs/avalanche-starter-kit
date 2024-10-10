import { fuji } from "./chains/definitions/fuji";
import { echo } from "./chains/definitions/echo";
import { dispatch } from "./chains/definitions/dispatch";

export const CHAINS = [fuji, echo, dispatch];
export const TOKENS = [
    {
        address: "native",
        name: "Avalanche",
        symbol: "AVAX",
        decimals: 18,
        chain_id: 43113
    },
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