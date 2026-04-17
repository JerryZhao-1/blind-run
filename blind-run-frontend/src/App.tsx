import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import RoleSelection from './pages/RoleSelection';
import BlindDashboard from './pages/Blind/Dashboard';
import RequestRun from './pages/Blind/RequestRun';
import BlindActiveRun from './pages/Blind/ActiveRun';
import VolunteerDashboard from './pages/Volunteer/Dashboard';
import VolunteerActiveRun from './pages/Volunteer/ActiveRun';
import Settings from './pages/Settings';

const ProtectedRoute = ({ children, allowedRole }: { children: React.ReactNode, allowedRole: 'blind' | 'volunteer' }) => {
  const { user, role, loading } = useAuth();
  
  if (loading) return <div className="min-h-screen bg-zinc-900 flex items-center justify-center text-white">加载中...</div>;
  if (!user || !role) return <Navigate to="/" replace />;
  if (role !== allowedRole) return <Navigate to={`/${role}`} replace />;
  
  return <>{children}</>;
};

const RootRoute = () => {
  const { user, role, loading } = useAuth();
  
  if (loading) return <div className="min-h-screen bg-zinc-900 flex items-center justify-center text-white">加载中...</div>;
  if (!user || !role) return <RoleSelection />;
  return <Navigate to={`/${role}`} replace />;
};

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<RootRoute />} />
          <Route path="/settings" element={<Settings />} />
          
          {/* Blind Runner Routes */}
          <Route path="/blind" element={<ProtectedRoute allowedRole="blind"><BlindDashboard /></ProtectedRoute>} />
          <Route path="/blind/request" element={<ProtectedRoute allowedRole="blind"><RequestRun /></ProtectedRoute>} />
          <Route path="/blind/run/:id" element={<ProtectedRoute allowedRole="blind"><BlindActiveRun /></ProtectedRoute>} />
          
          {/* Volunteer Routes */}
          <Route path="/volunteer" element={<ProtectedRoute allowedRole="volunteer"><VolunteerDashboard /></ProtectedRoute>} />
          <Route path="/volunteer/run/:id" element={<ProtectedRoute allowedRole="volunteer"><VolunteerActiveRun /></ProtectedRoute>} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
