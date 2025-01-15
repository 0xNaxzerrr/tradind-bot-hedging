'use client';

import { useAccount } from 'wagmi';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useState } from 'react';
import { useTradingBot } from '@/lib/hooks/useTradingBot';
import { CustomConnectButton } from '@/components/ui/connect-button';
import { RealTimeMonitor } from '@/components/monitoring/real-time-monitor';
import { parseEther, formatEther } from 'viem';

export default function PositionsPage() {
 const { isConnected } = useAccount();
 const { openPosition, currentPosition, closePosition } = useTradingBot();
 const [isLoading, setIsLoading] = useState(false);
 const [newPosition, setNewPosition] = useState({
   token0Amount: '',
   token1Amount: ''
 });

 const handleOpenPosition = async (e: React.FormEvent) => {
   e.preventDefault();
   setIsLoading(true);
   try {
     await openPosition({
       args: [
         parseEther(newPosition.token0Amount),
         parseEther(newPosition.token1Amount),
         0n
       ]
     });
   } catch (error) {
     console.error('Error opening position:', error);
   } finally {
     setIsLoading(false);
   }
 };

 if (!isConnected) {
   return (
     <div className="flex items-center justify-center min-h-screen">
       <div className="text-center">
         <h1 className="text-2xl font-bold mb-4">Manage Positions</h1>
         <p className="text-gray-600 mb-4">Please connect your wallet to continue</p>
         <CustomConnectButton />
       </div>
     </div>
   );
 }

 return (
   <div className="container mx-auto p-6">
     <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
       {/* Left Column */}
       <div className="space-y-6">
         <RealTimeMonitor />
         
         {/* Active Position Card */}
         <Card>
           <CardHeader>
             <CardTitle>Active Position</CardTitle>
           </CardHeader>
           <CardContent>
             {currentPosition?.isActive ? (
               <div className="space-y-4">
                 <div className="grid grid-cols-2 gap-4">
                   <div>
                     <p className="text-sm text-gray-500">ETH Amount</p>
                     <p className="font-medium">{formatEther(currentPosition.token0Amount)} ETH</p>
                   </div>
                   <div>
                     <p className="text-sm text-gray-500">USDC Amount</p>
                     <p className="font-medium">{formatEther(currentPosition.token1Amount)} USDC</p>
                   </div>
                   <div>
                     <p className="text-sm text-gray-500">Initial Price</p>
                     <p className="font-medium">{formatEther(currentPosition.initialPrice)} USDC/ETH</p>
                   </div>
                   <div>
                     <p className="text-sm text-gray-500">Last Update</p>
                     <p className="font-medium">
                       {new Date(Number(currentPosition.lastUpdateTime) * 1000).toLocaleString()}
                     </p>
                   </div>
                 </div>
                 <Button 
                   variant="destructive" 
                   className="w-full"
                   onClick={() => closePosition({ args: [0n, 0n] })}
                 >
                   Close Position
                 </Button>
               </div>
             ) : (
               <div className="text-center text-gray-500 py-4">
                 No active position
               </div>
             )}
           </CardContent>
         </Card>
       </div>

       {/* Right Column */}
       <div>
         <Tabs defaultValue="new">
           <TabsList className="w-full">
             <TabsTrigger value="new" className="flex-1">New Position</TabsTrigger>
             <TabsTrigger value="history" className="flex-1">History</TabsTrigger>
           </TabsList>
           
           <TabsContent value="new">
             <Card>
               <CardHeader>
                 <CardTitle>Open New Position</CardTitle>
               </CardHeader>
               <CardContent>
                 <form onSubmit={handleOpenPosition} className="space-y-4">
                   <div className="space-y-2">
                     <Label htmlFor="token0Amount">ETH Amount</Label>
                     <Input
                       id="token0Amount"
                       type="number"
                       step="0.01"
                       value={newPosition.token0Amount}
                       onChange={(e) => setNewPosition(prev => ({
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
                       value={newPosition.token1Amount}
                       onChange={(e) => setNewPosition(prev => ({
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
           </TabsContent>
           
           <TabsContent value="history">
             <Card>
               <CardHeader>
                 <CardTitle>Position History</CardTitle>
               </CardHeader>
               <CardContent>
                 <div className="text-center text-gray-500 py-4">
                   No position history available
                 </div>
               </CardContent>
             </Card>
           </TabsContent>
         </Tabs>
       </div>
     </div>
   </div>
 );
}