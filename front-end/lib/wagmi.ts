import { http, createConfig } from 'wagmi'
import { sepolia } from 'wagmi/chains'
import { getDefaultConfig } from '@rainbow-me/rainbowkit'

export const config = getDefaultConfig({
  appName: 'IL Hedging Bot',
  projectId: process.env.NEXT_PUBLIC_REOWN_PROJECT_ID!,
  chains: [sepolia],
  transports: {
    [sepolia.id]: http()
  },
});