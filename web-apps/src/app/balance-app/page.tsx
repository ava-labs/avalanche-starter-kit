
"use client";
import Image from "next/image";
import { useState } from "react";
import { Erc20TokenBalance } from "@avalabs/avacloud-sdk/models/components/erc20tokenbalance";

export default function BalanceApp() {
  const [address, setAddress] = useState<string>();
  const [balances, setBalances] = useState<Erc20TokenBalance[]>([]);

  const handleSetAddress = async () => {
    const addressInput = document.getElementById("address") as HTMLInputElement;
    const address = addressInput.value;
    const addressPattern = /^0x[a-fA-F0-9]{40}$/;  

    if (addressInput && addressPattern.test(address)) {
      setAddress(address);
      setBalances(await fetchERC20Balances(address));
    }
  };

  const fetchERC20Balances = async (address: string) => {
    const blockResult = await fetch("api/balance?method=getBlockHeight");
    const blockNumber = await blockResult.json();
    const balanceResult = await fetch("api/balance?method=listErc20Balances&address=" + address + "&blockNumber=" + blockNumber);
    const balances = await balanceResult.json();
    return balances as Erc20TokenBalance[];
  };


  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="z-10 w-full max-w-5xl items-center justify-between font-mono text-sm lg:flex">
        <div className="fixed bottom-0 left-0 flex h-48 w-full items-end justify-center bg-gradient-to-t from-white via-white dark:from-black dark:via-black lg:static lg:size-auto lg:bg-none">
          <a
            className="pointer-events-none flex place-items-center gap-2 p-8 lg:pointer-events-auto lg:p-0"
            href="https://www.avalabs.org/"
            target="_blank"
            rel="noopener noreferrer"
          >
            By{" "}
            <Image
              src="/ava-labs.svg"
              alt="Ava Labs Logo"
              className="dark:invert"
              width={100}
              height={24}
              priority
            />
          </a>
        </div>
        <div className="flex flex-col items-center justify-center mt-8">
          {address ? (
            <p className="text-lg font-semibold mb-2">Address: {address}</p>
          ) : (
            <>
              <label htmlFor="address" className="text-lg font-semibold mb-2">
                Set Address
              </label>
              <div className="flex">
                <input
                  type="text"
                  id="address"
                  className="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-black" // Add the "text-black" class to make the text visible
                  placeholder="Enter address"
                />
                <button
                  onClick={handleSetAddress}
                  className="ml-2 px-4 py-2 bg-red-500 text-white rounded-md"
                >
                  +
                </button>
              </div>
            </>
          )}
        </div>
      </div>
      <table className="mt-8 w-full max-w-5xl">
        <thead>
          <tr>
            <th className="px-4 py-2 bg-red-500 text-lg font-semibold mb-2">Logo</th>
            <th className="px-4 py-2 bg-red-500 text-lg font-semibold mb-2">Contract Address</th>
            <th className="px-4 py-2 bg-red-500 text-lg font-semibold mb-2">Token Name</th>
            <th className="px-4 py-2 bg-red-500 text-lg font-semibold mb-2">Balance</th>
          </tr>
        </thead>
        <tbody>
          {Array.isArray(balances) &&
            balances.map((token) => {
              return (
                <tr key={token.address}>
                  <td className="px-4 py-2">
                    {token.logoUri && (
                      <Image
                        src={token.logoUri}
                        alt="Token Logo"
                        width={24}
                        height={24}
                      />
                    )}
                  </td>
                  <td className="px-4 py-2">
                    <a
                      href={`https://subnets.avax.network/c-chain/address/${token.address}`}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      {token.address}
                    </a>
                  </td>
                  <td className="px-4 py-2">{token.name}</td>
                  <td className="px-4 py-2">{Number(token.balance) / 10 ** Number(token.decimals)}</td>
                </tr>
              );
            })}
        </tbody>
      </table>
    </main>
  );
}

