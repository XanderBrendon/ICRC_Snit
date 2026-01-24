import { useState, useEffect } from 'react';
import { useAuth, useActor } from '../../hooks';
import { PrincipalDisplay } from '../shared';

export function UserDashboard() {
  const { principal } = useAuth();
  const { actor, isReady } = useActor();
  const [balance, setBalance] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!isReady || !principal) return;

    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);

        const [balanceResult, profileResult] = await Promise.all([
          actor.snit_balance(principal),
          actor.snit_user_profile(principal),
        ]);

        setBalance(balanceResult);
        setProfile(profileResult.length > 0 ? profileResult[0] : null);
      } catch (err) {
        console.error('Failed to fetch user data:', err);
        setError(err.message || 'Failed to load user data');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [actor, principal, isReady]);

  if (loading) {
    return <section className="user-dashboard loading">Loading balance...</section>;
  }

  if (error) {
    return <section className="user-dashboard error">Error: {error}</section>;
  }

  return (
    <section className="user-dashboard">
      <h2>Balance</h2>
      <div className="dashboard-grid">
        <div className="stat-card balance-card">
          <div className="stat-value">{balance?.toString() || '0'}</div>
          <div className="stat-label">SNIT</div>
        </div>

        {profile && (
          <>
            <div className="stat-card">
              <div className="stat-value">{profile.level?.toString() || '0'}</div>
              <div className="stat-label">Level</div>
            </div>
            <div className="stat-card">
              <div className="stat-value">{profile.experience?.toString() || '0'}</div>
              <div className="stat-label">XP</div>
            </div>
            <div className="stat-card">
              <div className="stat-value">{profile.total_snit_earned?.toString() || '0'}</div>
              <div className="stat-label">Total Earned</div>
            </div>
            <div className="stat-card">
              <div className="stat-value">{profile.total_snit_spent?.toString() || '0'}</div>
              <div className="stat-label">Total Spent</div>
            </div>
          </>
        )}
      </div>

      <div className="principal-info">
        <strong>Principal:</strong> <PrincipalDisplay principal={principal} full />
      </div>
    </section>
  );
}

export default UserDashboard;
