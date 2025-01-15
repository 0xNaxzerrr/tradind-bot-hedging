'use client';

import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';

const mockData = [
  { timestamp: '00:00', il: 0 },
  { timestamp: '04:00', il: -0.5 },
  { timestamp: '08:00', il: -0.8 },
  { timestamp: '12:00', il: -0.3 },
  { timestamp: '16:00', il: -0.6 },
  { timestamp: '20:00', il: -0.4 }
];

export function ILChart() {
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm">
      <h2 className="text-lg font-bold mb-4">Impermanent Loss Over Time</h2>
      <div className="h-[400px]">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={mockData}>
            <XAxis dataKey="timestamp" />
            <YAxis />
            <Tooltip />
            <Line 
              type="monotone" 
              dataKey="il" 
              stroke="#2563eb" 
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}