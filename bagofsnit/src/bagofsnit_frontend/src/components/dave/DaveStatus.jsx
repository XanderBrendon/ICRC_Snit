import { useState, useEffect } from 'react';
import { useAuth, useActor } from '../../hooks';
import { PrincipalDisplay } from '../shared';

const STATUS_LABELS = {
  Pending: { label: 'Pending', className: 'status-pending' },
  Active: { label: 'Active', className: 'status-active' },
  Suspended: { label: 'Suspended', className: 'status-suspended' },
  Revoked: { label: 'Revoked', className: 'status-revoked' },
};

export function DaveStatus() {
  const { principal } = useAuth();
  const { actor, isReady } = useActor();
  const [dave, setDave] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!isReady || !principal) return;

    const fetchDave = async () => {
      try {
        setLoading(true);
        setError(null);
        const result = await actor.snit_dave_profile(principal);
        setDave(result.length > 0 ? result[0] : null);
      } catch (err) {
        console.error('Failed to fetch dave profile:', err);
        setError(err.message || 'Failed to load dave profile');
      } finally {
        setLoading(false);
      }
    };

    fetchDave();
  }, [actor, principal, isReady]);

  if (loading) {
    return <section className="dave-status loading">Loading Dave status...</section>;
  }

  if (error) {
    return <section className="dave-status error">Error: {error}</section>;
  }

  if (!dave) {
    return (
      <section className="dave-status not-registered">
        <h2>Your Dave Status</h2>
        <p>You are not registered as a Dave yet.</p>
      </section>
    );
  }

  const statusKey = Object.keys(dave.status)[0];
  const statusInfo = STATUS_LABELS[statusKey] || { label: statusKey, className: '' };

  return (
    <section className="dave-status">
      <h2>Your Dave Status</h2>
      <div className="dave-card">
        <div className="dave-header">
          <h3>{dave.name}</h3>
          <span className={`status-badge ${statusInfo.className}`}>{statusInfo.label}</span>
        </div>

        {dave.description && (
          <p className="dave-description">{dave.description}</p>
        )}

        <div className="dave-stats">
          <div className="stat">
            <span className="stat-label">Principal</span>
            <PrincipalDisplay principal={dave.principal} />
          </div>
          <div className="stat">
            <span className="stat-label">Level</span>
            <span className="stat-value">{dave.level?.toString() || '0'}</span>
          </div>
          <div className="stat">
            <span className="stat-label">Total Minted</span>
            <span className="stat-value">{dave.total_snit_minted?.toString() || '0'}</span>
          </div>
          <div className="stat">
            <span className="stat-label">Total Burned</span>
            <span className="stat-value">{dave.total_snit_burned?.toString() || '0'}</span>
          </div>
        </div>

        <div className="dave-dates">
          <small>Registered: {new Date(Number(dave.registered_at) / 1_000_000).toLocaleDateString()}</small>
          {dave.approved_at && dave.approved_at.length > 0 && (
            <small>Approved: {new Date(Number(dave.approved_at[0]) / 1_000_000).toLocaleDateString()}</small>
          )}
        </div>
      </div>
    </section>
  );
}

export default DaveStatus;
