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
    icm_registry: "0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228"
})
