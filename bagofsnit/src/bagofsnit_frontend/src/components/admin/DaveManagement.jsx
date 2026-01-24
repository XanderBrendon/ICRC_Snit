import { useState, useEffect, useCallback } from 'react';
import { useActor } from '../../hooks';
import { PrincipalDisplay } from '../shared';

const STATUS_LABELS = {
  Pending: { label: 'Pending', className: 'status-pending' },
  Active: { label: 'Active', className: 'status-active' },
  Suspended: { label: 'Suspended', className: 'status-suspended' },
  Revoked: { label: 'Revoked', className: 'status-revoked' },
};

export function DaveManagement() {
  const { actor, authenticatedActor, isReady } = useActor();
  const [daves, setDaves] = useState([]);
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(null);
  const [error, setError] = useState(null);
  const [message, setMessage] = useState(null);

  const fetchDaves = useCallback(async () => {
    if (!isReady) return;

    try {
      setLoading(true);
      setError(null);
      const result = await actor.snit_all_daves();
      setDaves(result);
    } catch (err) {
      console.error('Failed to fetch daves:', err);
      setError(err.message || 'Failed to load daves');
    } finally {
      setLoading(false);
    }
  }, [actor, isReady]);

  useEffect(() => {
    fetchDaves();
  }, [fetchDaves]);

  const handleAction = async (davePrincipal, action) => {
    if (!authenticatedActor) return;

    try {
      setActionLoading(davePrincipal.toString());
      setError(null);
      setMessage(null);

      let result;
      switch (action) {
        case 'approve':
          result = await authenticatedActor.admin_approve_dave(davePrincipal);
          break;
        case 'suspend':
          result = await authenticatedActor.admin_suspend_dave(davePrincipal);
          break;
        case 'revoke':
          result = await authenticatedActor.admin_revoke_dave(davePrincipal);
          break;
        default:
          return;
      }

      if ('ok' in result) {
        setMessage(`Dave ${action}d successfully.`);
        fetchDaves();
      } else {
        const errorKey = Object.keys(result.err)[0];
        setError(errorKey);
      }
    } catch (err) {
      console.error(`Failed to ${action} dave:`, err);
      setError(err.message || `Failed to ${action} dave`);
    } finally {
      setActionLoading(null);
    }
  };

  if (loading) {
    return <section className="dave-management loading">Loading Daves...</section>;
  }

  const filteredDaves = daves.filter((dave) => {
    if (filter === 'all') return true;
    const statusKey = Object.keys(dave.status)[0];
    return statusKey.toLowerCase() === filter;
  });

  return (
    <section className="dave-management">
      <h2>Dave Management</h2>

      {error && <div className="alert alert-error">{error}</div>}
      {message && <div className="alert alert-success">{message}</div>}

      <div className="filter-tabs">
        <button
          className={filter === 'all' ? 'active' : ''}
          onClick={() => setFilter('all')}
        >
          All ({daves.length})
        </button>
        <button
          className={filter === 'pending' ? 'active' : ''}
          onClick={() => setFilter('pending')}
        >
          Pending ({daves.filter((d) => 'Pending' in d.status).length})
        </button>
        <button
          className={filter === 'active' ? 'active' : ''}
          onClick={() => setFilter('active')}
        >
          Active ({daves.filter((d) => 'Active' in d.status).length})
        </button>
        <button
          className={filter === 'suspended' ? 'active' : ''}
          onClick={() => setFilter('suspended')}
        >
          Suspended ({daves.filter((d) => 'Suspended' in d.status).length})
        </button>
      </div>

      {filteredDaves.length === 0 ? (
        <p>No Daves found.</p>
      ) : (
        <div className="dave-list">
          {filteredDaves.map((dave) => {
            const statusKey = Object.keys(dave.status)[0];
            const statusInfo = STATUS_LABELS[statusKey] || { label: statusKey, className: '' };
            const isLoading = actionLoading === dave.principal.toString();

            return (
              <div key={dave.principal.toString()} className="dave-item">
                <div className="dave-info">
                  <div className="dave-header">
                    <h4>{dave.name}</h4>
                    <span className={`status-badge ${statusInfo.className}`}>
                      {statusInfo.label}
                    </span>
                  </div>
                  <PrincipalDisplay principal={dave.principal} />
                  {dave.description && <p className="description">{dave.description}</p>}
                  <div className="stats">
                    <span>Level: {dave.level?.toString() || '0'}</span>
                    <span>Minted: {dave.total_snit_minted?.toString() || '0'}</span>
                    <span>Burned: {dave.total_snit_burned?.toString() || '0'}</span>
                  </div>
                </div>
                <div className="dave-actions">
                  {statusKey === 'Pending' && (
                    <button
                      onClick={() => handleAction(dave.principal, 'approve')}
                      disabled={isLoading}
                      className="btn btn-success btn-small"
                    >
                      Approve
                    </button>
                  )}
                  {statusKey === 'Active' && (
                    <button
                      onClick={() => handleAction(dave.principal, 'suspend')}
                      disabled={isLoading}
                      className="btn btn-warning btn-small"
                    >
                      Suspend
                    </button>
                  )}
                  {(statusKey === 'Suspended' || statusKey === 'Pending') && (
                    <button
                      onClick={() => handleAction(dave.principal, 'revoke')}
                      disabled={isLoading}
                      className="btn btn-danger btn-small"
                    >
                      Revoke
                    </button>
                  )}
                  {statusKey === 'Suspended' && (
                    <button
                      onClick={() => handleAction(dave.principal, 'approve')}
                      disabled={isLoading}
                      className="btn btn-success btn-small"
                    >
                      Reactivate
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}

export default DaveManagement;
