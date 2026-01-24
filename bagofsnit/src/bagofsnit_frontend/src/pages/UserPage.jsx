import { useAuth } from '../hooks';
import { UserDashboard } from '../components/user/UserDashboard';
import { AffinityList } from '../components/user/AffinityList';
import { LinkManager } from '../components/user/LinkManager';

export function UserPage() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <div className="page loading">Loading...</div>;
  }

  if (!isAuthenticated) {
    return (
      <div className="page user-page">
        <h1>My Wallet</h1>
        <p>Please connect your wallet to view your SNIT balance.</p>
      </div>
    );
  }

  return (
    <div className="page user-page">
      <h1>My Wallet</h1>
      <UserDashboard />
      <AffinityList />
      <LinkManager />
    </div>
  );
}

export default UserPage;
