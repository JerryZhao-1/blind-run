import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Eye, HeartHandshake } from 'lucide-react';

export default function RoleSelection() {
  const { setRole } = useAuth();
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  const handleRoleSelect = async (selectedRole: 'blind' | 'volunteer') => {
    setIsLoggingIn(true);
    // Simulate a tiny delay for better UX
    setTimeout(async () => {
      await setRole(selectedRole);
      setIsLoggingIn(false);
    }, 300);
  };

  return (
    <div className="min-h-screen bg-zinc-900 flex flex-col items-center justify-center p-6 text-white">
      <h1 className="text-4xl font-bold mb-12 text-center">欢迎使用<br/>AidRun 助盲跑</h1>
      
      <div className="w-full max-w-md space-y-6">
        <button
          onClick={() => handleRoleSelect('blind')}
          disabled={isLoggingIn}
          className="w-full bg-yellow-400 text-zinc-900 rounded-3xl p-8 flex flex-col items-center justify-center gap-4 transition-transform active:scale-95 hover:bg-yellow-300 shadow-xl disabled:opacity-50"
          aria-label="我是盲人跑者"
        >
          <Eye size={64} />
          <span className="text-3xl font-bold">我是盲人跑者</span>
          <span className="text-zinc-800 text-lg">需要陪跑协助</span>
        </button>

        <button
          onClick={() => handleRoleSelect('volunteer')}
          disabled={isLoggingIn}
          className="w-full bg-zinc-800 text-white border-2 border-zinc-700 rounded-3xl p-8 flex flex-col items-center justify-center gap-4 transition-transform active:scale-95 hover:bg-zinc-700 shadow-xl disabled:opacity-50"
          aria-label="我是志愿者"
        >
          <HeartHandshake size={64} className="text-emerald-400" />
          <span className="text-3xl font-bold">我是志愿者</span>
          <span className="text-zinc-400 text-lg">提供陪跑服务</span>
        </button>
      </div>
    </div>
  );
}
