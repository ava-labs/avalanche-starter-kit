import { defineChain } from "viem";

export const fuji = defineChain({
    id: 43113,
    name: 'Avalanche Fuji',
    nativeCurrency: {
        decimals: 18,
        name: 'Avalanche Fuji',
        symbol: 'AVAX',
    },
    rpcUrls: {
        default: { http: ['https://api.avax-test.network/ext/bc/C/rpc'] },
    },
    blockExplorers: {
        default: {
            name: 'SnowTrace',
            url: 'https://testnet.snowtrace.io',
            apiUrl: 'https://api-testnet.snowtrace.io',
        },
    },
    contracts: {
        multicall3: {
            address: '0xca11bde05977b3631167028862be2a173976ca11',
            blockCreated: 7096959,
        },
    },
    testnet: true,
    // Custom variables
    icm_registry: "0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228",
    faucet: {
        recalibrate: 30,
        assets: [
            {
                address: "native",
                decimals: 18,
                drip_amount: 0.05, // max .05 token per request
                rate_limit: { // max 1 request in 24hrs
                    max_limit: 1,
                    window_size: 24 * 60 * 60 * 1000
                }
            },
            {
                address: "0x8D6f0E153B1D4Efb46c510278Db3678Bb1Cc823d",
                decimals: 18,
                drip_amount: 2, // max 2 token per request
                rate_limit: { // max 1 request in 24hrs
                    max_limit: 1,
                    window_size: 24 * 60 * 60 * 1000
                }
            }
        ]
    }
})
