// app/layout.tsx
import { Providers } from './providers';
import { Sidebar } from '@/components/navigation/sidebar';
import './globals.css';

export const metadata = {
  title: 'IL Hedging Bot',
  description: 'Automated hedging for Uniswap V2 LP positions',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Providers>
          <div className="flex">
            <Sidebar />
            <div className="flex-1 ml-64">
              {children}
            </div>
          </div>
        </Providers>
      </body>
    </html>
  );
}