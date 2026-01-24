import { useAuth } from '../hooks';
import { AdminGuard } from '../components/admin/AdminGuard';
import { DaveManagement } from '../components/admin/DaveManagement';
import { AdminPermissions } from '../components/admin/AdminPermissions';

export function AdminPage() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <div className="page loading">Loading...</div>;
  }

  if (!isAuthenticated) {
    return (
      <div className="page admin-page">
        <h1>Admin Panel</h1>
        <p>Please connect your wallet to access admin functions.</p>
      </div>
    );
  }

  return (
    <AdminGuard>
      <div className="page admin-page">
        <h1>Admin Panel</h1>
        <DaveManagement />
        <AdminPermissions />
      </div>
    </AdminGuard>
  );
}

export default AdminPage;
