import React, { createContext, useContext, useEffect, useState } from 'react';

type Role = 'blind' | 'volunteer' | null;

interface User {
  uid: string;
  displayName: string | null;
}

interface AuthContextType {
  user: User | null;
  role: Role;
  setRole: (role: Role) => Promise<void>;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [role, setRoleState] = useState<Role>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load local role preference
    const savedRole = localStorage.getItem('aidrun_role') as Role;
    if (savedRole) {
      setRoleState(savedRole);
      setUser({
        uid: savedRole === 'blind' ? 'demo-blind-id' : 'demo-volunteer-id',
        displayName: savedRole === 'blind' ? '盲人跑者' : '志愿者'
      });
    }
    setLoading(false);
  }, []);

  const setRole = async (newRole: Role) => {
    setRoleState(newRole);
    if (newRole) {
      localStorage.setItem('aidrun_role', newRole);
      setUser({
        uid: newRole === 'blind' ? 'demo-blind-id' : 'demo-volunteer-id',
        displayName: newRole === 'blind' ? '盲人跑者' : '志愿者'
      });
    } else {
      localStorage.removeItem('aidrun_role');
      setUser(null);
    }
  };

  return (
    <AuthContext.Provider value={{ user, role, setRole, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
