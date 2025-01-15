'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Button } from '@/components/ui/button';

export function CustomConnectButton() {
 return (
   <ConnectButton.Custom>
     {({
       account,
       chain,
       openAccountModal,
       openChainModal,
       openConnectModal,
       mounted,
     }) => {
       if (!mounted) return null;

       if (!account || !chain) {
         return (
           <Button onClick={openConnectModal} variant="outline">
             Connect Wallet
           </Button>
         );
       }

       if (chain.unsupported) {
         return (
           <Button onClick={openChainModal} variant="destructive">
             Wrong network
           </Button>
         );
       }

       return (
         <div className="flex items-center gap-4">
           <Button
             onClick={openChainModal}
             variant="outline"
             className="hidden sm:flex"
           >
             {chain.name}
           </Button>

           <Button
             onClick={openAccountModal}
             variant="outline"
           >
             {account.displayName}
             {account.displayBalance ? ` (${account.displayBalance})` : ""}
           </Button>
         </div>
       );
     }}
   </ConnectButton.Custom>
 );
}