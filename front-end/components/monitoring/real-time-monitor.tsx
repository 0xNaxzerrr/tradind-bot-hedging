'use client';

import { useEffect, useState } from 'react';
import { useTradingBot } from '@/lib/hooks/useTradingBot';
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { formatEther } from 'viem';

export function RealTimeMonitor() {
  const { currentPosition, rebalanceCheck } = useTradingBot();
  const [lastUpdate, setLastUpdate] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => {
      setLastUpdate(new Date());
    }, 15000);

    return () => clearInterval(timer);
  }, []);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Real-Time Monitor</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-4">
          <MonitorItem 
            label="ETH Amount"
            value={currentPosition ? formatEther(currentPosition.token0Amount) : '0'}
            unit="ETH"
          />
          <MonitorItem 
            label="USDC Amount"
            value={currentPosition ? formatEther(currentPosition.token1Amount) : '0'}
            unit="USDC"
          />
          <MonitorItem 
            label="IL Status"
            value={rebalanceCheck?.requiresRebalance ? 'Rebalance Needed' : 'Optimal'}
            status={rebalanceCheck?.requiresRebalance ? 'warning' : 'success'}
          />
          <MonitorItem 
            label="Last Update"
            value={lastUpdate.toLocaleTimeString()}
          />
        </div>
      </CardContent>
    </Card>
  );
}

function MonitorItem({ 
  label, 
  value, 
  unit, 
  status 
}: { 
  label: string; 
  value: string; 
  unit?: string;
  status?: 'success' | 'warning';
}) {
  return (
    <div className="bg-gray-50 p-3 rounded-lg">
      <p className="text-sm text-gray-500">{label}</p>
      <p className={`font-bold ${
        status === 'warning' ? 'text-yellow-600' : 
        status === 'success' ? 'text-green-600' : 'text-gray-900'
      }`}>
        {value} {unit}
      </p>
    </div>
  );
}