import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Save, LogOut, Bell, Shield, CircleUser, ChevronRight, Settings as SettingsIcon, HelpCircle } from 'lucide-react';
import { speakText } from '../lib/speech';

export default function Settings() {
  const { role, setRole } = useAuth();
  const navigate = useNavigate();
  const [emergencyContact, setEmergencyContact] = useState('');
  const [isAvailable, setIsAvailable] = useState(true);
  const [notifications, setNotifications] = useState(true);

  const handleSave = () => {
    if (role === 'blind') {
      speakText("设置已保存");
    }
    navigate(-1);
  };

  const handleLogout = () => {
    setRole(null);
    navigate('/');
  };

  if (role === 'volunteer') {
    return (
      <div className="min-h-screen bg-gray-50 font-sans flex flex-col">
        {/* Top Bar */}
        <div className="bg-white px-6 pt-12 pb-4 flex items-center gap-4 sticky top-0 z-10 border-b border-gray-100">
          <button 
            onClick={() => navigate(-1)}
            className="w-10 h-10 bg-gray-50 rounded-full flex items-center justify-center text-gray-900 active:scale-95 transition-transform"
            aria-label="返回"
          >
            <ArrowLeft size={20} />
          </button>
          <h1 className="text-2xl font-bold text-gray-900">设置</h1>
        </div>

        <main className="flex-1 p-6 space-y-8 max-w-lg mx-auto w-full">
          
          {/* Account Section */}
          <section>
            <h2 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-3 px-2">账号与安全</h2>
            <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
              <button className="w-full flex items-center justify-between p-4 border-b border-gray-50 active:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="bg-gray-100 p-2 rounded-full">
                    <CircleUser size={20} className="text-gray-700" />
                  </div>
                  <span className="font-medium text-gray-900">个人资料</span>
                </div>
                <ChevronRight size={18} className="text-gray-300" />
              </button>
              <button className="w-full flex items-center justify-between p-4 active:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="bg-gray-100 p-2 rounded-full">
                    <Shield size={20} className="text-gray-700" />
                  </div>
                  <span className="font-medium text-gray-900">账号安全</span>
                </div>
                <ChevronRight size={18} className="text-gray-300" />
              </button>
            </div>
          </section>

          {/* Preferences Section */}
          <section>
            <h2 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-3 px-2">接单偏好</h2>
            <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
              <div className="w-full flex items-center justify-between p-4 border-b border-gray-50">
                <div className="flex items-center gap-3">
                  <div className="bg-gray-100 p-2 rounded-full">
                    <Bell size={20} className="text-gray-700" />
                  </div>
                  <span className="font-medium text-gray-900">接收新订单推送</span>
                </div>
                <button 
                  onClick={() => setIsAvailable(!isAvailable)}
                  className={`w-12 h-7 rounded-full transition-colors relative ${isAvailable ? 'bg-black' : 'bg-gray-200'}`}
                >
                  <div className={`w-5 h-5 bg-white rounded-full absolute top-1 transition-transform shadow-sm ${isAvailable ? 'translate-x-6' : 'translate-x-1'}`} />
                </button>
              </div>
              <div className="p-4 bg-gray-50/50">
                <p className="text-sm text-gray-500 leading-relaxed">关闭后，您将不会收到新的附近盲人跑步预约推送，但已接订单不受影响。</p>
              </div>
            </div>
          </section>

          {/* Support Section */}
          <section>
            <h2 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-3 px-2">帮助与支持</h2>
            <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
              <button className="w-full flex items-center justify-between p-4 border-b border-gray-50 active:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="bg-gray-100 p-2 rounded-full">
                    <HelpCircle size={20} className="text-gray-700" />
                  </div>
                  <span className="font-medium text-gray-900">帮助中心</span>
                </div>
                <ChevronRight size={18} className="text-gray-300" />
              </button>
              <button className="w-full flex items-center justify-between p-4 active:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="bg-gray-100 p-2 rounded-full">
                    <SettingsIcon size={20} className="text-gray-700" />
                  </div>
                  <span className="font-medium text-gray-900">通用设置</span>
                </div>
                <ChevronRight size={18} className="text-gray-300" />
              </button>
            </div>
          </section>

          {/* Action Buttons */}
          <div className="pt-4 space-y-4">
            <button
              onClick={handleSave}
              className="w-full bg-black text-white font-bold text-lg rounded-2xl py-4 flex items-center justify-center gap-2 shadow-md active:scale-95 transition-transform"
            >
              <Save size={20} />
              保存设置
            </button>

            <button
              onClick={handleLogout}
              className="w-full bg-white text-red-500 font-bold text-lg rounded-2xl py-4 flex items-center justify-center gap-2 border border-gray-200 shadow-sm active:scale-95 transition-transform"
            >
              <LogOut size={20} />
              退出登录 / 切换角色
            </button>
          </div>

        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-zinc-900 text-white flex flex-col">
      <header className="p-6 flex items-center gap-4 border-b border-zinc-800">
        <button 
          onClick={() => navigate(-1)}
          className="p-4 bg-zinc-800 rounded-full active:scale-95"
          aria-label="返回"
        >
          <ArrowLeft size={32} />
        </button>
        <h1 className="text-3xl font-bold text-yellow-400">设置</h1>
      </header>

      <main className="flex-1 p-6 space-y-8 max-w-md mx-auto w-full">
        
        {role === 'blind' && (
          <div className="space-y-4">
            <label className="block text-2xl font-bold text-yellow-400">紧急联系人电话</label>
            <input
              type="tel"
              value={emergencyContact}
              onChange={(e) => setEmergencyContact(e.target.value)}
              className="w-full bg-zinc-800 border-2 border-zinc-700 rounded-2xl p-6 text-2xl focus:border-yellow-400 outline-none"
              placeholder="请输入手机号"
            />
            <p className="text-zinc-400 text-lg">在紧急情况下，我们将通过短信通知该联系人。</p>
          </div>
        )}

        <button
          onClick={handleSave}
          className="w-full bg-yellow-400 text-black font-bold text-3xl rounded-full py-6 flex items-center justify-center gap-4 mt-8 active:scale-95 transition-transform"
        >
          <Save size={32} />
          保存设置
        </button>

        <button
          onClick={handleLogout}
          className="w-full bg-red-500 text-white font-bold text-3xl rounded-full py-6 flex items-center justify-center gap-4 mt-4 active:scale-95 transition-transform"
        >
          <LogOut size={32} />
          切换角色
        </button>

      </main>
    </div>
  );
}
