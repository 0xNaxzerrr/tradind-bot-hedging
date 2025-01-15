'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { Navbar } from '@/components/navbar';
import { useTradingBot } from '@/lib/hooks/useTradingBot';

export default function SettingsPage() {
  const { isConnected } = useAccount();
  const [threshold, setThreshold] = useState("500"); // 5%

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      <main className="max-w-7xl mx-auto p-4">
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <h2 className="text-lg font-semibold mb-6">Bot Settings ⚙️</h2>
          
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Rebalance Threshold (%)
              </label>
              <input
                type="number"
                value={threshold}
                onChange={(e) => setThreshold(e.target.value)}
                className="w-full p-2 border rounded-lg"
                placeholder="5.00"
              />
              <p className="mt-1 text-sm text-gray-500">
                Minimum price deviation to trigger rebalancing
              </p>
            </div>

            <div>
              <h3 className="text-md font-medium mb-2">Gas Settings</h3>
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-600">
                  Automatic gas optimization enabled
                </p>
              </div>
            </div>

            <div>
              <h3 className="text-md font-medium mb-2">Notifications</h3>
              <div className="space-y-2">
                <label className="flex items-center">
                  <input type="checkbox" className="rounded border-gray-300" />
                  <span className="ml-2 text-sm text-gray-700">
                    Alert on rebalance needed
                  </span>
                </label>
                <label className="flex items-center">
                  <input type="checkbox" className="rounded border-gray-300" />
                  <span className="ml-2 text-sm text-gray-700">
                    Daily performance reports
                  </span>
                </label>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}