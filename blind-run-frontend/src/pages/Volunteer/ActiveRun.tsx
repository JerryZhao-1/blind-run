import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { doc, onSnapshot, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../lib/firebase';
import { ArrowLeft, MapPin, Clock, CheckCircle, Navigation, Play, Flag, Phone, MessageSquare, MoreHorizontal, Star } from 'lucide-react';
import { MapContainer, TileLayer, Marker, Popup, Polyline } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix Leaflet default icon issue
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

export default function VolunteerActiveRun() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [run, setRun] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id || !user) return;

    const unsubscribe = onSnapshot(doc(db, 'runs', id), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        setRun({ id: docSnap.id, ...data });
        
        if (data.status === 'cancelled') {
          setTimeout(() => navigate('/volunteer'), 3000);
        }
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, [id, user, navigate]);

  const updateStatus = async (newStatus: string) => {
    if (!id) return;
    try {
      await updateDoc(doc(db, 'runs', id), {
        status: newStatus,
        updatedAt: serverTimestamp()
      });
    } catch (error) {
      console.error("Error updating status:", error);
    }
  };

  if (loading || !run) return <div className="h-screen bg-gray-50 flex items-center justify-center font-sans">加载中...</div>;

  if (run.status === 'completed') {
    const mockTrack: [number, number][] = [
      [39.9042, 116.4074],
      [39.9052, 116.4084],
      [39.9062, 116.4074],
      [39.9072, 116.4064],
      [39.9082, 116.4084],
    ];

    return (
      <div className="h-screen bg-gray-50 flex flex-col relative font-sans overflow-hidden">
        {/* Map Background with Track */}
        <div className="absolute inset-0 z-0">
          <MapContainer center={[39.9062, 116.4074]} zoom={15} style={{ height: '100%', width: '100%' }} zoomControl={false}>
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            />
            <Polyline positions={mockTrack} color="#000000" weight={5} opacity={0.8} />
            <Marker position={mockTrack[0]} />
            <Marker position={mockTrack[mockTrack.length - 1]} />
          </MapContainer>
        </div>

        {/* Bottom Sheet for Summary */}
        <div className="absolute bottom-0 w-full bg-white rounded-t-[2rem] shadow-[0_-10px_40px_rgba(0,0,0,0.08)] z-20 flex flex-col p-6 pb-8">
          <div className="w-12 h-1.5 bg-gray-200 rounded-full mx-auto mb-6"></div>
          
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">行程结算</h2>
            <p className="text-gray-500">感谢您的爱心陪伴</p>
          </div>

          <div className="grid grid-cols-3 gap-4 mb-8">
            <div className="bg-gray-50 rounded-2xl p-4 text-center border border-gray-100">
              <div className="text-gray-500 text-sm mb-1">里程</div>
              <div className="text-2xl font-bold text-gray-900">3.2<span className="text-sm font-normal text-gray-500 ml-1">km</span></div>
            </div>
            <div className="bg-gray-50 rounded-2xl p-4 text-center border border-gray-100">
              <div className="text-gray-500 text-sm mb-1">时长</div>
              <div className="text-2xl font-bold text-gray-900">34<span className="text-sm font-normal text-gray-500 ml-1">min</span></div>
            </div>
            <div className="bg-emerald-50 rounded-2xl p-4 text-center border border-emerald-100">
              <div className="text-emerald-600 text-sm mb-1">获得积分</div>
              <div className="text-2xl font-bold text-emerald-600">+50</div>
            </div>
          </div>

          <button
            onClick={() => navigate('/volunteer')}
            className="w-full bg-black text-white font-bold text-lg rounded-2xl py-4 flex items-center justify-center active:scale-95 transition-transform"
          >
            返回大厅
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen bg-gray-50 flex flex-col relative font-sans overflow-hidden">
      {/* Map Background */}
      <div className="absolute inset-0 z-0">
        <MapContainer center={[39.9042, 116.4074]} zoom={13} style={{ height: '100%', width: '100%' }} zoomControl={false}>
          <TileLayer
            url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
          />
          <Marker position={[39.9042, 116.4074]}>
            <Popup>
              <div className="font-bold">{run.location}</div>
            </Popup>
          </Marker>
        </MapContainer>
      </div>

      {/* Top Bar */}
      <div className="absolute top-0 w-full p-4 z-10 pt-8">
        <button 
          onClick={() => navigate('/volunteer')}
          className="w-12 h-12 bg-white rounded-full shadow-md flex items-center justify-center text-gray-900 active:scale-95 transition-transform"
          aria-label="返回"
        >
          <ArrowLeft size={24} />
        </button>
      </div>

      {/* Bottom Sheet */}
      <div className="absolute bottom-0 w-full bg-white rounded-t-[2rem] shadow-[0_-10px_40px_rgba(0,0,0,0.08)] z-20 flex flex-col">
        <div className="w-12 h-1.5 bg-gray-200 rounded-full mx-auto mt-4 mb-5"></div>
        
        <div className="px-6 pb-8 flex flex-col h-full">
          
          {/* Status Header */}
          <div className="text-center mb-6">
            <h2 className="text-2xl font-bold text-gray-900">
              {run.status === 'accepted' && '前往集合地点'}
              {run.status === 'arrived' && '等待盲人跑者'}
              {run.status === 'running' && '陪伴跑步中'}
              {run.status === 'completed' && '行程已完成'}
              {run.status === 'cancelled' && '行程已取消'}
            </h2>
            <p className="text-gray-500 text-sm mt-1">
              {run.status === 'accepted' && '请尽快前往指定地点'}
              {run.status === 'arrived' && '您已到达，请与跑者汇合'}
              {run.status === 'running' && '保持配速，注意安全'}
              {run.status === 'completed' && '感谢您的志愿服务'}
            </p>
          </div>

          {/* Run Details Card */}
          <div className="bg-gray-50 rounded-2xl p-5 border border-gray-100 mb-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-gray-200 rounded-full overflow-hidden">
                  <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${run.id}`} alt="Runner Avatar" className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                </div>
                <div>
                  <h3 className="font-bold text-gray-900">盲人跑者</h3>
                  <div className="flex items-center gap-1 text-gray-500 text-sm mt-0.5">
                    <Star size={12} className="text-black fill-black" />
                    <span className="font-medium text-gray-900">5.0</span>
                  </div>
                </div>
              </div>
              <div className="flex gap-2">
                <button className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm border border-gray-100 text-gray-900 active:scale-95">
                  <MessageSquare size={18} />
                </button>
                <button className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm border border-gray-100 text-gray-900 active:scale-95">
                  <Phone size={18} />
                </button>
              </div>
            </div>

            <div className="h-px bg-gray-200 w-full my-4"></div>

            <div className="flex items-start gap-3">
              <div className="bg-white p-2 rounded-full shadow-sm border border-gray-100 text-black mt-0.5">
                <MapPin size={18} />
              </div>
              <div className="flex-1">
                <h4 className="font-bold text-gray-900">{run.location}</h4>
                <p className="text-gray-500 text-sm mt-0.5">{run.time}</p>
                {run.notes && (
                  <div className="mt-3 bg-white p-3 rounded-xl border border-gray-100 text-sm text-gray-600">
                    <span className="font-bold text-gray-900">备注：</span>{run.notes}
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="mt-auto">
            {run.status === 'accepted' && (
              <button
                onClick={() => updateStatus('arrived')}
                className="w-full bg-black text-white font-bold text-lg rounded-2xl py-4 flex items-center justify-center gap-3 active:scale-95 transition-transform"
              >
                <Navigation size={20} />
                我已到达集合点
              </button>
            )}

            {run.status === 'arrived' && (
              <button
                onClick={() => updateStatus('running')}
                className="w-full bg-black text-white font-bold text-lg rounded-2xl py-4 flex items-center justify-center gap-3 active:scale-95 transition-transform"
              >
                <Play size={20} className="fill-white" />
                开始跑步
              </button>
            )}

            {run.status === 'running' && (
              <button
                onClick={() => updateStatus('completed')}
                className="w-full bg-red-500 text-white font-bold text-lg rounded-2xl py-4 flex items-center justify-center gap-3 active:scale-95 transition-transform"
              >
                <Flag size={20} className="fill-white" />
                结束行程
              </button>
            )}

            {run.status === 'cancelled' && (
              <div className="text-center text-gray-500 flex flex-col items-center gap-3 py-4">
                <CheckCircle size={40} className="text-black" />
                <p className="font-medium">即将返回大厅...</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
