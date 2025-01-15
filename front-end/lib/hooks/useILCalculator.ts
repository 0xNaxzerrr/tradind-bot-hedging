'use client';

import { useReadContract } from 'wagmi';
import { CONTRACTS } from '@/lib/constants/contracts';
import { impermanentLossCalculatorABI } from './abis';

export function useILCalculator(poolAddress: string) {
  const { data: ilData, isLoading } = useReadContract({
    address: CONTRACTS.IL_CALCULATOR,
    abi: impermanentLossCalculatorABI,
    functionName: 'calculateImpermanentLoss',
    args: [poolAddress],
  });

  return { ilData, isLoading };
}