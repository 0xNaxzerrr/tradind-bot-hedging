'use client';

import Link from 'next/link';
import { CustomConnectButton } from './ui/connect-button';
import { TrendingUp } from 'lucide-react';

export function Navbar() {
  return (
    <nav className="bg-white shadow-sm p-4">
      <div className="flex items-center justify-between max-w-7xl mx-auto">
        <div className="flex items-center space-x-2">
          <TrendingUp className="h-6 w-6 text-blue-600" />
          <span className="text-xl font-bold">IL Hedging Bot</span>
        </div>
        <div className="flex items-center space-x-4">
          <CustomConnectButton />
        </div>
      </div>
    </nav>
  );
}