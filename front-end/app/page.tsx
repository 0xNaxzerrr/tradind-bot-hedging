'use client';

import { useAccount } from 'wagmi';
import { RealTimeMonitor } from '@/components/monitoring/real-time-monitor';
import { CustomConnectButton } from '@/components/ui/connect-button';
import { ILChart } from '@/components/dashboard/il-chart'; // À créer
import { PositionHistory } from '@/components/positions/position-history';

export default function Dashboard() {
  const { isConnected } = useAccount();

  if (!isConnected) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Welcome to IL Hedging Bot</h1>
          <p className="text-gray-600 mb-4">Please connect your wallet to continue</p>
          <CustomConnectButton />
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Section de monitoring en temps réel */}
        <div>
          <RealTimeMonitor />
        </div>

        {/* Section d'historique */}
        <div>
          <PositionHistory />
        </div>

        {/* Section graphique */}
        <div className="md:col-span-2">
          <ILChart />
        </div>
      </div>
    </div>
  );
}