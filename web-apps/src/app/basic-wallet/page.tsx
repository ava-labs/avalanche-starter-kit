"use client";
import Image from 'next/image'
import { useEffect, useState } from 'react'
import { useAccount } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit'
import { Erc1155TokenBalance, Erc20TokenBalance, TransactionDetails } from '@avalabs/avacloud-sdk/models/components';
import { Erc721TokenBalance } from '@avalabs/avacloud-sdk/models/components/erc721tokenbalance';

export default function BasicWallet() {
  const { address } = useAccount()
  const [erc20Balances, setErc20Balances] = useState<Erc20TokenBalance[]>([])
  const [erc721Balances, setErc721Balances] = useState<Erc721TokenBalance[]>([])
  const [erc1155Balances, setErc1155Balances] = useState<Erc1155TokenBalance[]>([])
  const [recentTransactions, setRecentTransactions] = useState<TransactionDetails>()
  const [activeTab, setActiveTab] = useState('nfts')

  const fetchERC20Balances = async (address: string) => {
    const blockResult = await fetch("api/balance?method=getBlockHeight");
    const blockNumber = await blockResult.json();
    const balanceResult = await fetch("api/balance?method=listErc20Balances&address=" + address + "&blockNumber=" + blockNumber);
    const balances = await balanceResult.json();
    return balances as Erc20TokenBalance[];
  };

  const fetchERC721Balances = async (address: string) => {
    const result = await fetch(`api/wallet?method=listERC721Balances&address=${address}`);
    const balances = await result.json();
    return balances as Erc721TokenBalance[];
  }

  const fetchERC1155Balances = async (address: string) => {
    const result = await fetch(`api/wallet?method=listERC1155Balances&address=${address}`);
    const balances = await result.json();
    return balances as Erc1155TokenBalance[];
  }

  const fetchRecentTransactions = async (address: string) => {
    const result = await fetch(`api/wallet?method=listRecentTransactions&address=${address}`);
    const transactions = await result.json();
    return transactions as TransactionDetails;
  }

  useEffect(() => {
    if (address) {
        fetchERC20Balances("0xd26C04bE22Cb25c7727504daF4304919cA26e301").then(setErc20Balances);
        fetchERC721Balances("0xd26C04bE22Cb25c7727504daF4304919cA26e301").then(setErc721Balances);
        fetchERC1155Balances("0xd26C04bE22Cb25c7727504daF4304919cA26e301").then(setErc1155Balances);
        fetchRecentTransactions("0xd26C04bE22Cb25c7727504daF4304919cA26e301").then(setRecentTransactions);
    }
  }, [address]);

  return (
    <div className="container mx-auto p-4">
      <header className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Wallet Portfolio</h1>
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
        <div className="flex items-center space-x-2">
          <ConnectButton />
        </div>
      </header>
      
      <div className="flex flex-col lg:flex-row gap-6">
        <main className="flex-grow">
          <div className="mb-4">
            <nav className="flex space-x-4" aria-label="Tabs">
              {['nfts', 'erc20', 'erc1155'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-3 py-2 font-medium text-sm rounded-md ${
                    activeTab === tab
                      ? 'bg-blue-100 text-blue-700'
                      : 'text-gray-500 hover:text-gray-700'
                  }`}
                >
                  {tab.toUpperCase()}
                </button>
              ))}
            </nav>
          </div>

          {activeTab === 'nfts' && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 xl:grid-cols-5 gap-4">
              {erc721Balances.length > 0 && erc721Balances.map((nft) => (
               <a 
               key={nft.symbol} 
               href={`https://snowtrace.io/token/${nft.address}`} 
               target="_blank" 
               rel="noopener noreferrer" 
               className="block hover:scale-105"
               >
              <div key={nft.tokenId} className="border rounded-lg p-4">
                <div className="flex justify-between items-center mb-2">
                <h3 className="text-lg font-semibold">{nft.name}</h3>
                <h3 className="text-lg font-semibold">#{nft.tokenId}</h3>
                </div>
                {nft.metadata.imageUri && (
                <img src={nft.metadata.imageUri} alt={nft.symbol} className="w-full h-auto" />
                )}
              </div>
               </a>
              ))}
            </div>
          )}

          {activeTab === 'erc20' && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {erc20Balances.length > 0 && erc20Balances.map((token) => (
              <a 
                key={token.symbol} 
                href={`https://snowtrace.io/token/${token.address}`} 
                target="_blank" 
                rel="noopener noreferrer" 
                className="border rounded-lg p-4 block hover:bg-gray-200 transition duration-200 ease-in-out transform hover:scale-105"
              >
                <div className="flex items-center mb-2">
                {token.logoUri && (
                  <img src={token.logoUri} alt={token.name} className="w-8 h-8 inline-block mr-2" />
                )}
                <h3 className="text-lg font-semibold">{token.name}</h3>
                </div>
                <p className="text-sm text-gray-500">{token.symbol}</p>
                <p className="text-sm">Balance: {Number(token.balance) / 10 ** Number(token.decimals)}</p>
              </a>
              ))}
            </div>
          )}

          {activeTab === 'erc1155' && (
            <div className="space-y-4">
              {erc1155Balances.length > 0 && erc1155Balances.map((token) => (
                <div key={token.tokenId} className="border rounded-lg p-4">
                  <h3 className="text-lg font-semibold">{token.metadata.name}</h3>
                  <p>Balance: {token.balance}</p>
                </div>
              ))}
            </div>
          )}
        </main>
        
        <aside className="w-full lg:w-80">
          <div className="border rounded-lg p-4">
            <h2 className="text-xl font-semibold mb-4">Recent Transactions</h2>
            <ul className="space-y-4">
              {activeTab === 'nfts' && (
              recentTransactions?.erc721Transfers?.map((tx) => (      
                <li key={tx.logIndex} className="flex items-center space-x-4">
                  <Image 
                  src={tx.erc721Token.metadata.imageUri || "/avax.svg"}
                  alt={"NFT"} 
                  className="w-10 h-10 rounded-full"
                  width={40}
                  height={40}
                  />
                  <div>
                  <p className="text-xs text-white">
                    {String(tx.from?.address) === '0xd26C04bE22Cb25c7727504daF4304919cA26e301' ? 'Send' : String(tx.to?.address) === '0xd26C04bE22Cb25c7727504daF4304919cA26e301' ? 'Receive' : 'SW'}
                  </p>
                  <p className="text-xs text-gray-500">{tx.erc721Token.name}</p>
                  <p className="text-xs text-gray-500">#{tx.erc721Token.tokenId}</p>
                  </div>
                </li>
              )))}
                {activeTab === 'erc20' && (
                recentTransactions?.erc20Transfers?.map((tx) => (
                    <li key={tx.logIndex} className="flex items-center space-x-4 p-4 bg-gray-800 rounded-lg shadow-md">
                    <div className="flex-shrink-0">
                      {tx.erc20Token.logoUri && (
                      <img src={tx.erc20Token.logoUri} alt={tx.erc20Token.name} className="w-10 h-10 rounded-full" />
                      )}
                    </div>
                    <div className="flex-grow">
                      <p className="text-sm font-semibold text-white">
                      {String(tx.from?.address) === '0xd26C04bE22Cb25c7727504daF4304919cA26e301' ? 'Send' : String(tx.to?.address) === '0xd26C04bE22Cb25c7727504daF4304919cA26e301' ? 'Receive' : 'SW'}
                      </p>
                      <p className="text-sm text-gray-400">{tx.erc20Token.name}</p>
                      <p className="text-sm text-gray-400">
                      {Number(tx.value) / 10 ** Number(tx.erc20Token.decimals)}
                      </p>
                    </div>
                    </li>
                ))
                )}
            </ul>
          </div>
        </aside>
      </div>
    </div>
  )
}