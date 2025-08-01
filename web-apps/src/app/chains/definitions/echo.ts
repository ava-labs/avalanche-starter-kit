import { defineChain } from "viem";

export const echo = defineChain({
  id: 173750,
  //   name: "Echo L1",
  //   network: "echo",
  name: "Ulalo- L1",
  network: "ula",
  nativeCurrency: {
    decimals: 18,
    // name: 'Ech',
    // symbol: 'ECH',
    name: "Ulalo- L1",
    symbol: "Ulalo- L1",
  },
  rpcUrls: {
    default: {
      http: ["https://subnets.avax.network/echo/testnet/rpc"],
    },
  },
  blockExplorers: {
    default: {
      name: "Explorer",
      url: "https://subnets-test.avax.network/echo",
    },
  },
  // Custom variables
  //   iconUrl: "/chains/logo/173750.png",
  //   icm_registry: "0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228",
  iconUrl: "/ula.jpg",
  icm_registry: "0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228",
});
