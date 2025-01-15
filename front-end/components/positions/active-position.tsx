'use client';

import { useTradingBot } from '@/lib/hooks/useTradingBot';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { formatEther } from 'viem';

export function ActivePosition() {
  const { currentPosition, closePosition } = useTradingBot();

  if (!currentPosition?.isActive) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="text-center text-gray-500">
            No active position
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Active Position</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <div className="text-sm text-gray-500">ETH Amount</div>
            <div className="font-medium">
              {formatEther(currentPosition.token0Amount)} ETH
            </div>
          </div>
          <div>
            <div className="text-sm text-gray-500">USDC Amount</div>
            <div className="font-medium">
              {formatEther(currentPosition.token1Amount)} USDC
            </div>
          </div>
          <div>
            <div className="text-sm text-gray-500">Initial Price</div>
            <div className="font-medium">
              {formatEther(currentPosition.initialPrice)} USDC/ETH
            </div>
          </div>
          <div>
            <div className="text-sm text-gray-500">Last Update</div>
            <div className="font-medium">
              {new Date(Number(currentPosition.lastUpdateTime) * 1000).toLocaleString()}
            </div>
          </div>
        </div>
      </CardContent>
      <CardFooter>
        <Button 
          variant="destructive" 
          className="w-full"
          onClick={() => closePosition({ args: [0n, 0n] })}
        >
          Close Position
        </Button>
      </CardFooter>
    </Card>
  );
}