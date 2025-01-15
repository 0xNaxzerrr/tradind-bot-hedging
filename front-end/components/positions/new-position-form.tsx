'use client';

import { useState } from 'react';
import { useTradingBot } from '@/lib/hooks/useTradingBot';
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { parseEther } from 'viem';

export function NewPositionForm() {
  const { openPosition } = useTradingBot();
  const [formData, setFormData] = useState({
    token0Amount: '',
    token1Amount: '',
  });
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      await openPosition({
        args: [
          parseEther(formData.token0Amount),
          parseEther(formData.token1Amount),
          0n
        ]
      });
    } catch (error) {
      console.error('Error opening position:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Open New Position</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="token0Amount">ETH Amount</Label>
            <Input
              id="token0Amount"
              type="number"
              step="0.01"
              value={formData.token0Amount}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                token0Amount: e.target.value
              }))}
              placeholder="0.0"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="token1Amount">USDC Amount</Label>
            <Input
              id="token1Amount"
              type="number"
              step="0.01"
              value={formData.token1Amount}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                token1Amount: e.target.value
              }))}
              placeholder="0.0"
            />
          </div>

          <Button 
            type="submit" 
            className="w-full" 
            disabled={isLoading}
          >
            {isLoading ? "Opening Position..." : "Open Position"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}