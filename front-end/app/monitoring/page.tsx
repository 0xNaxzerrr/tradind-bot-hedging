'use client';

import { useEffect, useState } from 'react';
import { useTradingBot } from '@/lib/hooks/useTradingBot';
import { useILCalculator } from '@/lib/hooks/useILCalculator';
import { formatEther } from 'viem';

export function RealTimeMonitor() {
  const { currentPosition, rebalanceCheck } = useTradingBot();
  const [lastUpdate, setLastUpdate] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => {
      setLastUpdate(new Date());
    }, 15000); // Update every 15 seconds

    return () => clearInterval(timer);
  }, []);

  return (
    <div className="bg-white p-4 rounded-lg shadow-sm">
      <div className="flex justify-between items-center mb-4">
        <h3 className="font-medium">Real-Time Monitoring</h3>
        <span className="text-sm text-gray-500">
          Last update: {lastUpdate.toLocaleTimeString()}
        </span>
      </div>

      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="p-3 bg-gray-50 rounded">
            <p className="text-sm text-gray-500">Current IL</p>
            <p className="font-bold text-red-600">
              {rebalanceCheck ? `${formatEther(rebalanceCheck.newHedgeAmount)}%` : 'N/A'}
            </p>
          </div>
          <div className="p-3 bg-gray-50 rounded">
            <p className="text-sm text-gray-500">Status</p>
            <p className="font-bold text-blue-600">
              {rebalanceCheck?.requiresRebalance ? '⚠️ Rebalance Needed' : '✅ Optimal'}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}