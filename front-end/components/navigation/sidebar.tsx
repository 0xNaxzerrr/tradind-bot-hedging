'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Home, Settings, PieChart, Activity } from 'lucide-react';

export function Sidebar() {
  const pathname = usePathname();

  const links = [
    { href: '/', label: 'Dashboard', icon: Home },
    { href: '/positions', label: 'Positions', icon: PieChart },
    { href: '/monitoring', label: 'Monitoring', icon: Activity },
    { href: '/settings', label: 'Settings', icon: Settings },
  ];

  return (
    <div className="fixed left-0 top-0 h-full w-64 bg-white border-r p-4">
      <div className="mb-8">
        <h1 className="text-xl font-bold text-blue-600">IL Hedging Bot</h1>
      </div>

      <nav className="space-y-2">
        {links.map((link) => {
          const Icon = link.icon;
          return (
            <Link
              key={link.href}
              href={link.href}
              className={`flex items-center px-4 py-2 rounded-lg ${
                pathname === link.href
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              <Icon className="h-5 w-5 mr-3" />
              {link.label}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}