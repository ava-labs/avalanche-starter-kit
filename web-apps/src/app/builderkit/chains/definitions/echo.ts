import { defineChain } from "viem";

export const echo = defineChain({
    id: 173750,
    name: 'Echo L1',
    network: 'echo',
    nativeCurrency: {
        decimals: 18,
        name: 'Ech',
        symbol: 'ECH',
    },
    rpcUrls: {
        default: {
            http: ['https://subnets.avax.network/echo/testnet/rpc']
        },
    },
    blockExplorers: {
        default: { name: 'Explorer', url: 'https://subnets-test.avax.network/echo' },
    },
    // Custom variables
    iconUrl: "/chains/logo/173750.png",
    blockchain_id_hex: "0x1278d1be4b987e847be3465940eb5066c4604a7fbd6e086900823597d81af4c1"
});