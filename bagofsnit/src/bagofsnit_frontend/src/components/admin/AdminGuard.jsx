import { useState, useEffect } from 'react';
import { useAuth, useActor } from '../../hooks';

export function AdminGuard({ children }) {
  const { principal } = useAuth();
  const { actor, isReady } = useActor();
  const [isAdmin, setIsAdmin] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isReady || !principal) return;

    const checkAdmin = async () => {
      try {
        setLoading(true);
        const result = await actor.admin_is_admin(principal);
        setIsAdmin(result);
      } catch (err) {
        console.error('Failed to check admin status:', err);
        setIsAdmin(false);
      } finally {
        setLoading(false);
      }
    };

    checkAdmin();
  }, [actor, principal, isReady]);

  if (loading) {
    return <div className="admin-guard loading">Checking admin access...</div>;
  }

  if (!isAdmin) {
    return (
      <div className="admin-guard unauthorized">
        <h2>Access Denied</h2>
        <p>You do not have admin permissions to access this page.</p>
      </div>
    );
  }

  return <>{children}</>;
}

export default AdminGuard;
