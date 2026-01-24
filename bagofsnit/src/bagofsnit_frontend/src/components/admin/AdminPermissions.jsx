import { useState, useEffect, useCallback } from 'react';
import { Principal } from '@dfinity/principal';
import { useAuth, useActor } from '../../hooks';
import { PrincipalDisplay } from '../shared';

export function AdminPermissions() {
  const { principal } = useAuth();
  const { actor, authenticatedActor, isReady } = useActor();
  const [adminInfo, setAdminInfo] = useState(null);
  const [newAdmin, setNewAdmin] = useState('');
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState(null);
  const [message, setMessage] = useState(null);

  const fetchAdmins = useCallback(async () => {
    if (!isReady) return;

    try {
      setLoading(true);
      setError(null);
      const result = await actor.admin_list_admins();
      setAdminInfo(result);
    } catch (err) {
      console.error('Failed to fetch admins:', err);
      setError(err.message || 'Failed to load admins');
    } finally {
      setLoading(false);
    }
  }, [actor, isReady]);

  useEffect(() => {
    fetchAdmins();
  }, [fetchAdmins]);

  const isOwner = principal && adminInfo && principal.toString() === adminInfo.owner.toString();

  const handleAddAdmin = async (e) => {
    e.preventDefault();
    if (!authenticatedActor || !newAdmin.trim()) return;

    try {
      setActionLoading(true);
      setError(null);
      setMessage(null);

      const adminPrincipal = Principal.fromText(newAdmin.trim());
      const result = await authenticatedActor.admin_add_admin(adminPrincipal);

      if ('ok' in result) {
        setMessage('Admin added successfully.');
        setNewAdmin('');
        fetchAdmins();
      } else {
        const errorKey = Object.keys(result.err)[0];
        setError(errorKey);
      }
    } catch (err) {
      console.error('Failed to add admin:', err);
      setError(err.message || 'Failed to add admin');
    } finally {
      setActionLoading(false);
    }
  };

  const handleRemoveAdmin = async (adminPrincipal) => {
    if (!authenticatedActor) return;

    try {
      setActionLoading(true);
      setError(null);
      setMessage(null);

      const result = await authenticatedActor.admin_remove_admin(adminPrincipal);

      if ('ok' in result) {
        setMessage('Admin removed successfully.');
        fetchAdmins();
      } else {
        const errorKey = Object.keys(result.err)[0];
        setError(errorKey);
      }
    } catch (err) {
      console.error('Failed to remove admin:', err);
      setError(err.message || 'Failed to remove admin');
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return <section className="admin-permissions loading">Loading admin info...</section>;
  }

  return (
    <section className="admin-permissions">
      <h2>Admin Permissions</h2>

      {error && <div className="alert alert-error">{error}</div>}
      {message && <div className="alert alert-success">{message}</div>}

      <div className="owner-info">
        <h3>Owner</h3>
        <PrincipalDisplay principal={adminInfo?.owner} full />
        {isOwner && <span className="badge">(You)</span>}
      </div>

      <div className="admins-list">
        <h3>Delegated Admins</h3>
        {adminInfo?.admins?.length > 0 ? (
          <ul>
            {adminInfo.admins.map((admin) => (
              <li key={admin.toString()}>
                <PrincipalDisplay principal={admin} />
                {isOwner && (
                  <button
                    onClick={() => handleRemoveAdmin(admin)}
                    disabled={actionLoading}
                    className="btn btn-small btn-danger"
                  >
                    Remove
                  </button>
                )}
              </li>
            ))}
          </ul>
        ) : (
          <p>No delegated admins.</p>
        )}
      </div>

      {isOwner && (
        <div className="add-admin-form">
          <h3>Add Admin</h3>
          <form onSubmit={handleAddAdmin}>
            <input
              type="text"
              value={newAdmin}
              onChange={(e) => setNewAdmin(e.target.value)}
              placeholder="Principal ID"
              disabled={actionLoading}
            />
            <button type="submit" disabled={actionLoading || !newAdmin.trim()} className="btn">
              Add Admin
            </button>
          </form>
        </div>
      )}

      {!isOwner && (
        <p className="info">Only the owner can add or remove admins.</p>
      )}
    </section>
  );
}

export default AdminPermissions;
