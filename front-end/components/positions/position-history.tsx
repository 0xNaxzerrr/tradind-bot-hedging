'use client';

import { useEffect, useState } from 'react';
import { formatEther } from 'viem';

interface PositionEvent {
  type: 'OPEN' | 'CLOSE' | 'REBALANCE';
  timestamp: number;
  data: any;
}

export function PositionHistory() {
  const [events, setEvents] = useState<PositionEvent[]>([]);

  // Simulated events for now - would be replaced with actual contract events
  useEffect(() => {
    const mockEvents: PositionEvent[] = [
      {
        type: 'OPEN',
        timestamp: Date.now() - 86400000,
        data: { token0Amount: '1000000000000000000', token1Amount: '2000000000' }
      },
      {
        type: 'REBALANCE',
        timestamp: Date.now() - 43200000,
        data: { oldHedge: '500000000000000000', newHedge: '600000000000000000' }
      }
    ];
    setEvents(mockEvents);
  }, []);

  return (
    <div className="bg-white p-4 rounded-lg shadow-sm">
      <h3 className="font-medium mb-4">Position History</h3>
      <div className="space-y-3">
        {events.map((event, i) => (
          <div key={i} className="border-l-4 border-blue-500 pl-4 py-2">
            <div className="flex justify-between items-center">
              <span className="font-medium">
                {event.type}
              </span>
              <span className="text-sm text-gray-500">
                {new Date(event.timestamp).toLocaleString()}
              </span>
            </div>
            <p className="text-sm text-gray-600 mt-1">
              {event.type === 'OPEN' && 
                `Added ${formatEther(event.data.token0Amount)} ETH and ${formatEther(event.data.token1Amount)} USDC`}
              {event.type === 'REBALANCE' &&
                `Rebalanced hedge from ${formatEther(event.data.oldHedge)} to ${formatEther(event.data.newHedge)}`}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}