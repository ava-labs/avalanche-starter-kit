"use client";
import Image from 'next/image'
import { useEffect, useState } from 'react'
import { Card } from '@/app/components/Card'
import { Input } from '@/app/components/Input'
import { Button } from '@/app/components/Button'
import { NativeTransaction, EvmBlock } from '@avalabs/avacloud-sdk/models/components';


interface SelectedItem {
  type: string;
  id: string;
  from: string;
  to: string;
  value: string;
}

export default function BlockchainExplorer() {
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedItem, setSelectedItem] = useState<SelectedItem | null>(null)
  const [recentTransactions, setRecentTransactions] = useState<NativeTransaction[]>([])
  const [recentBlocks, setRecentBlocks] = useState<EvmBlock[]>([])

  const handleSearch = () => {
    setSelectedItem({ type: 'transaction', id: searchTerm, from: '0xSender', to: '0xReceiver', value: '1.5 ETH' })
  }

  const fetchRecentTransactions = async () => {
    const response = await fetch(`/api/explorer?method=getRecentTransactions`)
    const data = await response.json()
    return data as NativeTransaction[]
  }
  const fetchRecentBlocks = async () => {
    const response = await fetch(`/api/explorer?method=getRecentBlocks`)
    const data = await response.json()
    return data as EvmBlock[]
  }

  useEffect(() => {
    fetchRecentTransactions().then(setRecentTransactions)
    fetchRecentBlocks().then(setRecentBlocks)
  }, [])

  return (
    
    <div className="min-h-screen bg-gradient-to-br from-purple-700 to-blue-500 p-8 text-white">
      <h1 className="text-4xl font-bold mb-8 text-center">Blockchain Explorer</h1>
      <div className="absolute top-0 left-0 p-4">
        <a
          className="pointer-events-none flex place-items-center gap-2 lg:pointer-events-auto lg:p-0"
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
      <div className="max-w-4xl mx-auto mb-8">
        <div className="flex gap-2">
          <Input
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by transaction, block, contract or address"
            className="flex-grow"
          />
          <Button onClick={handleSearch}>
            Search
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
        <Card title="Recent Transactions">
          <ul className="space-y-2">
            {recentTransactions.map((tx) => (
              <li key={tx.txHash} className="flex justify-between items-center hover:bg-white/10 p-2 rounded transition-colors duration-200">
                <div className="flex flex-col items-start">
                  <span className="text-sm">{tx.txHash.substring(0, 12)}...</span>
                    <span className="text-xs border border-gray-400 p-1 rounded mt-1">
                      {Math.floor((Date.now() - new Date(tx.blockTimestamp * 1000).getTime()) / 1000)}s ago
                    </span>
                </div>
                <div className="flex flex-col items-center flex-grow px-10">
                  <span className="text-sm">From: {tx.from.address.substring(0, 12)}</span>
                  <span className="text-sm">To: {tx.to.address.substring(0, 12)}</span>
                </div>
                <div className="flex flex-col items-end border border-gray-400 shadow-inner p-2 rounded">
                  <span className="text-sm font-medium">{(parseFloat(tx.value) / 10 ** 18).toString().substring(0,6)} AVAX</span>
                </div>
              </li>
            ))}
          </ul>
        </Card>

        <Card title="Recent Blocks">
          <ul className="space-y-2">
            {recentBlocks.map((block) => (
              <li key={block.blockNumber} className="flex justify-between items-center hover:bg-white/10 p-2 rounded transition-colors duration-200">
                <div className="flex flex-col items-start">
                  <span className="text-sm">#{block.blockNumber}</span>
                  <span className="text-xs border border-gray-400 p-1 rounded mt-1">
                  {Math.floor((Date.now() - new Date(block.blockTimestamp * 1000).getTime()) / 1000)}s ago
                  </span>
                </div>
                <span className="text-sm font-medium">{block.txCount} transactions</span>
                <div className="flex flex-col items-end border border-gray-400 shadow-inner p-2 rounded">
                  <span className="text-sm font-medium">{(parseFloat(block.feesSpent) / 10 ** 18).toString().substring(0,6)} AVAX</span>
                </div>
              </li>
            ))}
          </ul>
        </Card>
      </div>

      {selectedItem && (
        <Card title={`${selectedItem.type.charAt(0).toUpperCase() + selectedItem.type.slice(1)} Details`} className="mb-8 animate-fadeIn">
          <div className="grid grid-cols-2 gap-4">
            <span className="text-sm font-semibold">ID:</span>
            <span className="text-sm">{selectedItem.id}</span>
            <span className="text-sm font-semibold">From:</span>
            <span className="text-sm">{selectedItem.from}</span>
            <span className="text-sm font-semibold">To:</span>
            <span className="text-sm">{selectedItem.to}</span>
            <span className="text-sm font-semibold">Value:</span>
            <span className="text-sm">{selectedItem.value}</span>
          </div>
        </Card>
      )}
    </div>
  )
}