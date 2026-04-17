import React, { useEffect, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { collection, query, where, onSnapshot, doc, updateDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../lib/firebase';
import { useNavigate } from 'react-router-dom';
import { Map, Clock, User, MapPin, Navigation, CheckCircle, ChevronRight, Star, Gift, Settings, LogOut, Menu } from 'lucide-react';

import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix Leaflet default icon issue
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

const MOCK_RUNS = [
  { id: 'mock-1', location: '奥林匹克森林公园南园', time: '今天 18:00', notes: '第一次跑，希望配速慢一点', lat: 40.0150, lng: 116.3900, status: 'pending' },
  { id: 'mock-2', location: '朝阳公园东门', time: '明天 07:30', notes: '带导盲犬', lat: 39.9435, lng: 116.4830, status: 'pending' },
  { id: 'mock-3', location: '天坛公园北门', time: '今天 19:00', notes: '', lat: 39.8837, lng: 116.4128, status: 'pending' },
];

// --- Tab Components ---

const MapTab = ({ activeRun, pendingRuns, handleAcceptRun, navigate }: any) => {
  const displayRuns = [...pendingRuns, ...MOCK_RUNS];
  const center = [39.9042, 116.4074]; // Beijing center
  
  const runsWithCoords = displayRuns.map((run, index) => {
    if (run.lat && run.lng) return run;
    const offsetLat = (Math.sin(index) * 0.05);
    const offsetLng = (Math.cos(index) * 0.05);
    return { ...run, lat: center[0] + offsetLat, lng: center[1] + offsetLng };
  });

  return (
    <div className="flex-1 flex flex-col relative bg-[#f3f4f6]">
      {/* Map Background */}
      <div className="absolute inset-0 z-0">
        <MapContainer center={[39.9042, 116.4074]} zoom={11} style={{ height: '100%', width: '100%' }} zoomControl={false}>
          <TileLayer
            url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
          />
          {/* Mock "You are here" Marker */}
          <Marker position={[39.9042, 116.4074]}>
            <Popup>
              <div className="font-bold">您的位置</div>
            </Popup>
          </Marker>
          
          {runsWithCoords.map(run => (
            <Marker key={run.id} position={[run.lat, run.lng]}>
              <Popup>
                <div className="font-bold">{run.location}</div>
                <div className="text-sm text-gray-500">{run.time}</div>
                {run.notes && <div className="text-xs text-gray-400 mt-1">{run.notes}</div>}
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>

      {/* Top Bar */}
      <div className="absolute top-0 w-full p-4 z-10 pt-8">
        <div className="bg-white rounded-full shadow-md px-6 py-3 flex justify-between items-center max-w-md mx-auto">
          <div className="flex items-center gap-3">
            <div className="w-2.5 h-2.5 bg-green-500 rounded-full shadow-[0_0_8px_rgba(34,197,94,0.6)]"></div>
            <span className="font-bold text-sm text-gray-900">在线 - 正在寻找附近需求</span>
          </div>
          <Menu size={20} className="text-gray-900" />
        </div>
      </div>

      {/* Bottom Sheet */}
      <div className="absolute bottom-0 w-full bg-white rounded-t-[2rem] shadow-[0_-10px_40px_rgba(0,0,0,0.08)] z-20 h-[55%] flex flex-col">
        <div className="w-12 h-1.5 bg-gray-200 rounded-full mx-auto mt-4 mb-5"></div>
        
        <div className="px-6 pb-4">
          <h2 className="text-2xl font-bold text-gray-900">附近需求 ({displayRuns.length})</h2>
        </div>

        <div className="flex-1 overflow-y-auto px-6 pb-6 space-y-4">
          {activeRun && (
             <div className="bg-black text-white rounded-2xl p-5 shadow-lg cursor-pointer active:scale-95 transition-transform" onClick={() => navigate(`/volunteer/run/${activeRun.id}`)}>
                <div className="flex justify-between items-center mb-2">
                  <span className="font-bold text-lg">当前行程进行中</span>
                  <Navigation size={20} className="text-white" />
                </div>
                <p className="text-gray-300 text-sm">{activeRun.location}</p>
             </div>
          )}

          {displayRuns.map((run: any) => (
            <div key={run.id} className="bg-white border border-gray-100 rounded-2xl p-5 shadow-sm">
              <div className="flex items-start gap-4">
                <div className="bg-gray-50 p-3 rounded-full">
                  <MapPin size={24} className="text-black" />
                </div>
                <div className="flex-1">
                  <h3 className="font-bold text-lg text-gray-900 leading-tight">{run.location}</h3>
                  <p className="text-gray-500 text-sm mt-1">{run.time}</p>
                  {run.notes && <p className="text-gray-600 text-sm mt-3 bg-gray-50 p-2.5 rounded-xl">备注: {run.notes}</p>}
                </div>
              </div>
              <button 
                onClick={() => handleAcceptRun(run.id)} 
                disabled={!!activeRun} 
                className="w-full mt-5 bg-black text-white font-bold text-lg rounded-xl py-3.5 disabled:bg-gray-200 disabled:text-gray-400 active:scale-95 transition-all"
              >
                {activeRun ? '请先完成当前行程' : '立即接单'}
              </button>
            </div>
          ))}
          
          {displayRuns.length === 0 && !activeRun && (
            <div className="text-center py-10 text-gray-400">
              <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <MapPin size={24} className="text-gray-300" />
              </div>
              <p className="font-medium">附近暂无需求</p>
              <p className="text-sm mt-1">请保持在线，有新需求会立即通知您</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

const HistoryTab = ({ user }: any) => {
  const [history, setHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    const q = query(collection(db, 'runs'), where('volunteerId', '==', user.uid));
    const unsub = onSnapshot(q, (snapshot) => {
      const runs = snapshot.docs
        .map(d => ({ id: d.id, ...d.data() } as any))
        .filter(r => ['completed', 'cancelled'].includes(r.status))
        .sort((a, b) => (b.createdAt?.toMillis() || 0) - (a.createdAt?.toMillis() || 0));
      setHistory(runs);
      setLoading(false);
    });
    return () => unsub();
  }, [user]);

  return (
    <div className="flex-1 bg-white overflow-y-auto">
      <div className="px-6 pt-12 pb-6 bg-white sticky top-0 z-10 border-b border-gray-50">
        <h1 className="text-3xl font-bold text-gray-900">历史行程</h1>
      </div>
      <div className="px-6 py-6 space-y-6">
        {loading ? (
          <p className="text-gray-500 font-medium">加载中...</p>
        ) : history.length === 0 ? (
          <div className="text-center py-20">
            <Clock size={48} className="text-gray-200 mx-auto mb-4" />
            <p className="text-gray-500 font-medium">暂无历史行程</p>
          </div>
        ) : (
          history.map(run => (
            <div key={run.id} className="flex items-center justify-between border-b border-gray-100 pb-6 last:border-0">
              <div className="flex items-start gap-4">
                <div className="bg-gray-50 p-3 rounded-full">
                  <CheckCircle size={24} className={run.status === 'completed' ? 'text-black' : 'text-gray-300'} />
                </div>
                <div>
                  <h3 className="font-bold text-gray-900 text-lg mb-1">{run.location}</h3>
                  <p className="text-gray-500 text-sm">
                    {run.createdAt ? new Date(run.createdAt.toDate()).toLocaleDateString() : '刚刚'} • {run.time}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <span className={`font-bold text-lg ${run.status === 'completed' ? 'text-black' : 'text-gray-400'}`}>
                  {run.status === 'completed' ? '+50 积分' : '已取消'}
                </span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

const StoreTab = () => {
  const rewards = [
    { id: 1, name: '运动水壶', points: 500, image: 'https://picsum.photos/seed/bottle/400/300' },
    { id: 2, name: '速干排汗T恤', points: 1200, image: 'https://picsum.photos/seed/shirt/400/300' },
    { id: 3, name: '专业跑步袜', points: 300, image: 'https://picsum.photos/seed/socks/400/300' },
    { id: 4, name: '运动腰包', points: 800, image: 'https://picsum.photos/seed/bag/400/300' },
  ];

  return (
    <div className="flex-1 bg-gray-50 overflow-y-auto">
      <div className="bg-black text-white px-6 pt-16 pb-10 rounded-b-[2.5rem] shadow-md">
        <h1 className="text-3xl font-bold mb-8">积分商城</h1>
        <div className="bg-white/10 rounded-3xl p-6 backdrop-blur-md border border-white/10">
          <p className="text-gray-300 text-sm mb-2 font-medium">当前可用积分</p>
          <div className="flex items-end gap-2">
            <span className="text-5xl font-bold tracking-tight">1,250</span>
            <span className="text-gray-300 mb-1.5 font-medium">分</span>
          </div>
        </div>
      </div>

      <div className="px-6 py-8">
        <h2 className="text-xl font-bold text-gray-900 mb-6">热门兑换</h2>
        <div className="grid grid-cols-2 gap-4">
          {rewards.map(item => (
            <div key={item.id} className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100 flex flex-col">
              <img src={item.image} alt={item.name} className="w-full h-32 object-cover" referrerPolicy="no-referrer" />
              <div className="p-4 flex flex-col flex-1 justify-between">
                <h3 className="font-bold text-gray-900 text-sm mb-3">{item.name}</h3>
                <div className="flex items-center justify-between mt-auto">
                  <span className="text-black font-bold text-sm">{item.points} 积分</span>
                  <button className="bg-black text-white text-xs px-4 py-2 rounded-full font-bold active:scale-95 transition-transform">兑换</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const ProfileTab = ({ user, setRole, navigate }: any) => {
  return (
    <div className="flex-1 bg-gray-50 overflow-y-auto">
      <div className="px-6 pt-16 pb-8 bg-white rounded-b-[2.5rem] shadow-sm">
        <div className="flex items-center gap-5 mb-8">
          <div className="w-20 h-20 bg-gray-100 rounded-full overflow-hidden border border-gray-200">
            <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${user?.uid || 'volunteer'}`} alt="Avatar" className="w-full h-full object-cover" referrerPolicy="no-referrer" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{user?.displayName || '志愿者'}</h1>
            <div className="flex items-center gap-1.5 text-gray-600 mt-2 bg-gray-50 inline-flex px-2.5 py-1 rounded-full">
              <Star size={14} className="text-black fill-black" />
              <span className="font-bold text-gray-900 text-sm">4.98</span>
              <span className="text-xs text-gray-500"> (128次评价)</span>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-3">
          <div className="bg-gray-50 rounded-2xl p-4 text-center border border-gray-100">
            <div className="text-2xl font-bold text-gray-900">42</div>
            <div className="text-xs text-gray-500 mt-1 font-medium">完成行程</div>
          </div>
          <div className="bg-gray-50 rounded-2xl p-4 text-center border border-gray-100">
            <div className="text-2xl font-bold text-gray-900">186</div>
            <div className="text-xs text-gray-500 mt-1 font-medium">陪伴公里</div>
          </div>
          <div className="bg-gray-50 rounded-2xl p-4 text-center border border-gray-100">
            <div className="text-2xl font-bold text-gray-900">1.2k</div>
            <div className="text-xs text-gray-500 mt-1 font-medium">获得积分</div>
          </div>
        </div>
      </div>

      <div className="px-6 py-8 space-y-3">
        <button onClick={() => navigate('/settings')} className="w-full bg-white p-5 rounded-2xl flex items-center justify-between shadow-sm border border-gray-100 active:scale-95 transition-transform">
          <div className="flex items-center gap-4">
            <Settings size={24} className="text-gray-900" />
            <span className="font-bold text-gray-900 text-lg">设置</span>
          </div>
          <ChevronRight size={20} className="text-gray-400" />
        </button>
        
        <button onClick={() => { setRole(null); navigate('/'); }} className="w-full bg-white p-5 rounded-2xl flex items-center justify-between shadow-sm border border-gray-100 active:scale-95 transition-transform">
          <div className="flex items-center gap-4">
            <LogOut size={24} className="text-red-500" />
            <span className="font-bold text-red-500 text-lg">退出登录 / 切换角色</span>
          </div>
          <ChevronRight size={20} className="text-gray-400" />
        </button>
      </div>
    </div>
  );
};

// --- Main Dashboard Component ---

export default function VolunteerDashboard() {
  const { user, setRole } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('map');
  
  const [pendingRuns, setPendingRuns] = useState<any[]>([]);
  const [activeRun, setActiveRun] = useState<any>(null);

  useEffect(() => {
    if (!user) return;

    // Active run
    const activeQ = query(collection(db, 'runs'), where('volunteerId', '==', user.uid));
    const unsubActive = onSnapshot(activeQ, (snapshot) => {
      const active = snapshot.docs
        .map(d => ({ id: d.id, ...d.data() } as any))
        .find(r => ['accepted', 'arrived', 'running'].includes(r.status));
      setActiveRun(active || null);
    });

    // Pending runs
    const pendingQ = query(collection(db, 'runs'), where('status', '==', 'pending'));
    const unsubPending = onSnapshot(pendingQ, (snapshot) => {
      const runs = snapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data() } as any))
        .sort((a, b) => (b.createdAt?.toMillis() || 0) - (a.createdAt?.toMillis() || 0));
      setPendingRuns(runs);
    });

    return () => {
      unsubActive();
      unsubPending();
    };
  }, [user]);

  const handleAcceptRun = async (runId: string) => {
    if (!user) return;
    try {
      if (runId.startsWith('mock-')) {
        const mockRun = MOCK_RUNS.find(r => r.id === runId);
        if (mockRun) {
          const newRunRef = doc(collection(db, 'runs'));
          await setDoc(newRunRef, {
            location: mockRun.location,
            time: mockRun.time,
            notes: mockRun.notes,
            status: 'accepted',
            volunteerId: user.uid,
            volunteerName: user.displayName || '爱心志愿者',
            volunteerRating: '5.0',
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
          });
          navigate(`/volunteer/run/${newRunRef.id}`);
          return;
        }
      }

      await updateDoc(doc(db, 'runs', runId), {
        volunteerId: user.uid,
        volunteerName: user.displayName || '爱心志愿者',
        volunteerRating: '5.0',
        status: 'accepted',
        updatedAt: serverTimestamp()
      });
      navigate(`/volunteer/run/${runId}`);
    } catch (error) {
      console.error("Error accepting run:", error);
      alert("接单失败，可能已被其他志愿者抢单。");
    }
  };

  return (
    <div className="h-screen bg-white flex flex-col overflow-hidden font-sans">
      {/* Main Content Area */}
      {activeTab === 'map' && <MapTab activeRun={activeRun} pendingRuns={pendingRuns} handleAcceptRun={handleAcceptRun} navigate={navigate} />}
      {activeTab === 'history' && <HistoryTab user={user} />}
      {activeTab === 'store' && <StoreTab />}
      {activeTab === 'profile' && <ProfileTab user={user} setRole={setRole} navigate={navigate} />}

      {/* Bottom Navigation */}
      <nav className="bg-white border-t border-gray-100 pt-3 pb-6 z-50 shadow-[0_-4px_20px_rgba(0,0,0,0.02)]">
        <div className="flex justify-around items-center px-2">
          <NavItem icon={<Map size={24} />} label="地图" active={activeTab === 'map'} onClick={() => setActiveTab('map')} />
          <NavItem icon={<Clock size={24} />} label="历史" active={activeTab === 'history'} onClick={() => setActiveTab('history')} />
          <NavItem icon={<Gift size={24} />} label="商城" active={activeTab === 'store'} onClick={() => setActiveTab('store')} />
          <NavItem icon={<User size={24} />} label="我的" active={activeTab === 'profile'} onClick={() => setActiveTab('profile')} />
        </div>
      </nav>
    </div>
  );
}

const NavItem = ({ icon, label, active, onClick }: any) => (
  <button 
    onClick={onClick} 
    className={`flex flex-col items-center justify-center w-full space-y-1.5 transition-colors ${active ? 'text-black' : 'text-gray-400 hover:text-gray-600'}`}
  >
    {icon}
    <span className="text-[11px] font-bold">{label}</span>
  </button>
);
