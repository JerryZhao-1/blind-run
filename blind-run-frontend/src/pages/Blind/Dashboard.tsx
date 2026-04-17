import React, { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { collection, query, where, onSnapshot, orderBy, limit } from 'firebase/firestore';
import { db } from '../../lib/firebase';
import { useNavigate } from 'react-router-dom';
import { Navigation, Activity, LogOut } from 'lucide-react';
import { speakText } from '../../lib/speech';

export default function BlindDashboard() {
  const { user, setRole } = useAuth();
  const navigate = useNavigate();
  const [activeRun, setActiveRun] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;

    // Speak welcome message
    speakText("欢迎来到助盲跑，您可以点击屏幕中央的大按钮发起预约。");

    const q = query(
      collection(db, 'runs'),
      where('blindRunnerId', '==', user.uid)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const runs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() as any }));
      // Sort in memory to avoid requiring a composite index
      runs.sort((a, b) => (b.createdAt?.toMillis() || 0) - (a.createdAt?.toMillis() || 0));
      
      const active = runs.find(r => ['pending', 'accepted', 'arrived', 'running'].includes(r.status));
      
      if (active) {
        setActiveRun(active);
      } else {
        setActiveRun(null);
      }
      setLoading(false);
    }, (err) => {
      console.error("Firestore error:", err);
      setError(err.message);
      setLoading(false);
    });

    return () => {
      unsubscribe();
    };
  }, [user]);

  const handleRequestClick = () => {
    speakText("进入预约页面");
    navigate('/blind/request');
  };

  const handleActiveRunClick = () => {
    speakText("查看当前行程");
    navigate(`/blind/run/${activeRun.id}`);
  };

  const handleSwitchRole = async () => {
    await setRole(null);
    navigate('/');
  };

  if (loading) return <div className="min-h-screen bg-black text-white flex items-center justify-center text-5xl font-bold">加载中...</div>;

  return (
    <div className="min-h-screen bg-black text-white flex flex-col">
      <header className="p-4 flex justify-end">
        <button 
          onClick={handleSwitchRole}
          className="flex items-center gap-2 bg-zinc-800 text-zinc-300 px-6 py-4 rounded-2xl text-2xl font-bold active:scale-95 transition-transform"
        >
          <LogOut size={32} />
          切换角色
        </button>
      </header>
      <main className="flex-1 flex flex-col p-4 gap-4">
        {error && (
          <div className="bg-red-500 text-white p-4 rounded-2xl text-2xl font-bold">
            错误: {error}
          </div>
        )}
        {activeRun ? (
          <button
            onClick={handleActiveRunClick}
            className="w-full h-full flex-1 bg-emerald-500 text-black rounded-3xl flex flex-col items-center justify-center gap-8 active:scale-95 transition-transform"
            aria-label="查看当前行程"
          >
            <Activity size={120} />
            <span className="text-6xl font-bold">查看行程</span>
            <span className="text-3xl font-medium mt-4">
              {activeRun.status === 'pending' && '正在匹配志愿者'}
              {activeRun.status === 'accepted' && '志愿者已接单'}
              {activeRun.status === 'arrived' && '志愿者已到达'}
              {activeRun.status === 'running' && '跑步进行中'}
            </span>
          </button>
        ) : (
          <button
            onClick={handleRequestClick}
            className="w-full h-full flex-1 bg-yellow-400 text-black rounded-3xl flex flex-col items-center justify-center gap-8 active:scale-95 transition-transform"
            aria-label="发起陪跑预约"
          >
            <Navigation size={120} />
            <span className="text-7xl font-bold">发起预约</span>
            <span className="text-3xl font-medium mt-4">点击屏幕任意位置开始</span>
          </button>
        )}
      </main>
    </div>
  );
}
