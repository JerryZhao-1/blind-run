import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { doc, onSnapshot, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../lib/firebase';
import { ArrowLeft, XCircle, Phone, MapPin, Clock } from 'lucide-react';
import { speakText } from '../../lib/speech';

export default function ActiveRun() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [run, setRun] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id || !user) return;

    let lastStatus = '';

    const unsubscribe = onSnapshot(doc(db, 'runs', id), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        setRun({ id: docSnap.id, ...data });
        
        // Announce status changes
        if (data.status !== lastStatus) {
          let message = '';
          switch (data.status) {
            case 'pending': message = '正在为您匹配志愿者，请稍候。'; break;
            case 'accepted': message = '志愿者已接单，正在路上。'; break;
            case 'arrived': message = '志愿者已到达集合地点。'; break;
            case 'running': message = '跑步已开始，祝您跑得愉快。'; break;
            case 'completed': 
              message = data.blindRating ? '跑步已结束，感谢您的使用。' : '跑步已结束，请在屏幕上评价本次志愿服务。'; 
              break;
            case 'cancelled': message = '行程已取消。'; break;
          }
          if (message) {
            speakText(message);
          }
          lastStatus = data.status;
        }

        if (data.status === 'cancelled') {
          setTimeout(() => navigate('/blind'), 5000);
        }
      }
      setLoading(false);
    });

    return () => {
      unsubscribe();
    };
  }, [id, user, navigate]);

  const handleCancel = async () => {
    if (!id) return;
    try {
      await updateDoc(doc(db, 'runs', id), {
        status: 'cancelled',
        updatedAt: serverTimestamp()
      });
      speakText("已取消预约");
      navigate('/blind');
    } catch (error) {
      console.error("Error cancelling run:", error);
    }
  };

  const handleRating = async (rating: string) => {
    if (!id) return;
    try {
      await updateDoc(doc(db, 'runs', id), {
        blindRating: rating,
        updatedAt: serverTimestamp()
      });
      speakText("感谢您的评价，期待下次与您奔跑");
      navigate('/blind');
    } catch (error) {
      console.error("Error rating run:", error);
    }
  };

  const simulateVolunteerAccept = async () => {
    if (!id) return;
    try {
      await updateDoc(doc(db, 'runs', id), {
        status: 'accepted',
        volunteerName: '李雷 (模拟)',
        volunteerRating: 4.9,
        volunteerPhone: '13800138000',
        updatedAt: serverTimestamp()
      });
    } catch (error) {
      console.error("Error simulating accept:", error);
    }
  };

  const simulateStatusUpdate = async (status: string) => {
    if (!id) return;
    try {
      await updateDoc(doc(db, 'runs', id), {
        status,
        updatedAt: serverTimestamp()
      });
    } catch (error) {
      console.error(`Error updating status to ${status}:`, error);
    }
  };

  if (loading || !run) return <div className="min-h-screen bg-black text-white flex items-center justify-center text-3xl">加载中...</div>;

  if (run.status === 'completed' && !run.blindRating) {
    return (
      <div className="min-h-screen bg-black text-white flex flex-col">
        <header className="p-6 flex items-center gap-4 border-b border-zinc-800">
          <h1 className="text-4xl font-bold text-yellow-400">行程已结束</h1>
        </header>
        <main className="flex-1 p-6 flex flex-col gap-6 max-w-md mx-auto w-full justify-center">
          <h2 className="text-4xl font-bold text-center mb-4">请评价本次志愿服务</h2>
          
          <button onClick={() => handleRating('good')} className="w-full bg-emerald-500 text-black font-bold text-4xl rounded-3xl py-12 active:scale-95 transition-transform shadow-lg shadow-emerald-500/20">
            非常满意
          </button>
          <button onClick={() => handleRating('average')} className="w-full bg-yellow-500 text-black font-bold text-4xl rounded-3xl py-12 active:scale-95 transition-transform shadow-lg shadow-yellow-500/20">
            基本满意
          </button>
          <button onClick={() => handleRating('bad')} className="w-full bg-red-500 text-white font-bold text-4xl rounded-3xl py-12 active:scale-95 transition-transform shadow-lg shadow-red-500/20">
            需要改进
          </button>
        </main>
      </div>
    );
  }

  return (
    <div className="h-screen bg-black text-white flex flex-col font-sans overflow-hidden p-4">
      <main className="flex-1 flex flex-col gap-4 w-full">
        
        {/* Status Area */}
        <div className="flex-1 bg-zinc-900 rounded-3xl p-8 flex flex-col items-center justify-center text-center gap-6 border-2 border-zinc-800">
          <h2 className="text-7xl font-extrabold text-yellow-400 leading-tight">
            {run.status === 'pending' && '匹配中'}
            {run.status === 'accepted' && '已接单'}
            {run.status === 'arrived' && '已到达'}
            {run.status === 'running' && '跑步中'}
            {run.status === 'completed' && '已完成'}
            {run.status === 'cancelled' && '已取消'}
          </h2>
          <p className="text-4xl text-zinc-400 font-medium">
            {run.status === 'pending' && '请在原地等待'}
            {run.status === 'accepted' && '志愿者正在赶来'}
            {run.status === 'arrived' && '请与志愿者汇合'}
            {run.status === 'running' && '享受跑步的乐趣吧'}
          </p>
        </div>

        {/* Volunteer Info (If Accepted/Arrived/Running) */}
        {['accepted', 'arrived', 'running'].includes(run.status) && (
          <div className="bg-zinc-900 rounded-3xl p-8 flex items-center gap-8 border-2 border-zinc-800">
            <div className="w-32 h-32 bg-zinc-800 rounded-full overflow-hidden flex-shrink-0">
              <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${run.volunteerId || 'volunteer'}`} alt="Volunteer" className="w-full h-full object-cover" />
            </div>
            <div className="flex-1">
              <h3 className="text-5xl font-bold text-white mb-4">{run.volunteerName || '爱心志愿者'}</h3>
              <div className="flex items-center gap-2 text-yellow-400 text-4xl font-bold">
                <span>★</span>
                <span>{run.volunteerRating || '5.0'}</span>
              </div>
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex flex-col gap-4 mt-auto">
          {run.status === 'pending' && (
            <button
              onClick={simulateVolunteerAccept}
              className="w-full bg-zinc-800 text-zinc-400 font-bold text-3xl rounded-3xl py-8 active:scale-95 transition-transform border-2 border-zinc-700"
            >
              [测试] 模拟志愿者接单
            </button>
          )}

          {run.status === 'accepted' && (
            <>
              <button
                onClick={() => simulateStatusUpdate('arrived')}
                className="w-full bg-zinc-800 text-zinc-400 font-bold text-3xl rounded-3xl py-8 active:scale-95 transition-transform border-2 border-zinc-700"
              >
                [测试] 模拟志愿者到达
              </button>
              <button
                className="w-full bg-emerald-500 text-black font-extrabold text-5xl rounded-3xl py-12 flex items-center justify-center gap-6 active:scale-95 transition-transform shadow-[0_0_40px_rgba(16,185,129,0.4)]"
                aria-label="联系志愿者"
              >
                <Phone size={64} />
                联系志愿者
              </button>
            </>
          )}

          {run.status === 'arrived' && (
            <button
              onClick={() => simulateStatusUpdate('running')}
              className="w-full bg-zinc-800 text-zinc-400 font-bold text-3xl rounded-3xl py-8 active:scale-95 transition-transform border-2 border-zinc-700"
            >
              [测试] 模拟开始跑步
            </button>
          )}

          {run.status === 'running' && (
            <button
              onClick={() => simulateStatusUpdate('completed')}
              className="w-full bg-zinc-800 text-zinc-400 font-bold text-3xl rounded-3xl py-8 active:scale-95 transition-transform border-2 border-zinc-700"
            >
              [测试] 模拟结束行程
            </button>
          )}

          {['pending', 'accepted'].includes(run.status) && (
            <button
              onClick={handleCancel}
              className="w-full bg-red-500 text-white font-extrabold text-5xl rounded-3xl py-12 flex items-center justify-center gap-6 active:scale-95 transition-transform shadow-[0_0_40px_rgba(239,68,68,0.4)]"
              aria-label="取消行程"
            >
              <XCircle size={64} />
              取消行程
            </button>
          )}
        </div>
      </main>
    </div>
  );
}
