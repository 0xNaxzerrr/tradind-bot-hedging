// lib/hooks/useTradingBot.ts
'use client';

import { useContractRead, useContractWrite, useAccount } from 'wagmi';
import { CONTRACTS } from '@/lib/constants/contracts';
import TradingBotABI from '@/abis/TradingBot.json';
import { parseEther } from 'viem';

export function useTradingBot() {
  const { address } = useAccount();

  // Lecture de la position actuelle
  const { data: currentPosition, isLoading: positionLoading } = useContractRead({
    address: CONTRACTS.TRADING_BOT,
    abi: TradingBotABI.abi,
    functionName: 'currentPosition',
    watch: true,
  });

  // Vérification du rebalancement
  const { data: rebalanceCheck, isLoading: rebalanceLoading } = useContractRead({
    address: CONTRACTS.TRADING_BOT,
    abi: TradingBotABI.abi,
    functionName: 'checkRebalance',
    watch: true,
  });

  // Ouverture d'une position
  const { writeAsync: openPosition } = useContractWrite({
    address: CONTRACTS.TRADING_BOT,
    abi: TradingBotABI.abi,
    functionName: 'openPosition',
  });

  // Fermeture d'une position
  const { writeAsync: closePosition } = useContractWrite({
    address: CONTRACTS.TRADING_BOT,
    abi: TradingBotABI.abi,
    functionName: 'closePosition',
  });

  return {
    currentPosition,
    rebalanceCheck,
    positionLoading,
    rebalanceLoading,
    openPosition,
    closePosition,
  };
}