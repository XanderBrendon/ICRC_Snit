import { useState, useEffect, useCallback } from 'react';
import { Principal } from '@dfinity/principal';
import { useAuth, useActor } from '../../hooks';
import { PrincipalDisplay } from '../shared';

export function LinkManager() {
  const { principal } = useAuth();
  const { actor, authenticatedActor, isReady } = useActor();
  const [linkedPrincipals, setLinkedPrincipals] = useState([]);
  const [resolvedBag, setResolvedBag] = useState(null);
  const [linkToPrincipal, setLinkToPrincipal] = useState('');
  const [confirmPrincipal, setConfirmPrincipal] = useState('');
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState(null);
  const [message, setMessage] = useState(null);

  const fetchLinkData = useCallback(async () => {
    if (!isReady || !principal) return;

    try {
      setLoading(true);
      setError(null);
      const [linkedResult, resolvedResult] = await Promise.all([
        actor.snit_linked_principals(principal),
        actor.snit_resolve_bag(principal),
      ]);
      setLinkedPrincipals(linkedResult);
      setResolvedBag(resolvedResult);
    } catch (err) {
      console.error('Failed to fetch link data:', err);
      setError(err.message || 'Failed to load link data');
    } finally {
      setLoading(false);
    }
  }, [actor, principal, isReady]);

  useEffect(() => {
    fetchLinkData();
  }, [fetchLinkData]);

  const handleRequestLink = async (e) => {
    e.preventDefault();
    if (!authenticatedActor || !linkToPrincipal.trim()) return;

    try {
      setActionLoading(true);
      setError(null);
      setMessage(null);

      const targetPrincipal = Principal.fromText(linkToPrincipal.trim());
      const result = await authenticatedActor.request_link(targetPrincipal);

      if ('ok' in result) {
        setMessage('Link request sent! The primary wallet must confirm.');
        setLinkToPrincipal('');
      } else {
        setError(Object.keys(result.err)[0]);
      }
    } catch (err) {
      console.error('Failed to request link:', err);
      setError(err.message || 'Failed to request link');
    } finally {
      setActionLoading(false);
    }
  };

  const handleConfirmLink = async (e) => {
    e.preventDefault();
    if (!authenticatedActor || !confirmPrincipal.trim()) return;

    try {
      setActionLoading(true);
      setError(null);
      setMessage(null);

      const secondaryPrincipal = Principal.fromText(confirmPrincipal.trim());
      const result = await authenticatedActor.confirm_link(secondaryPrincipal);

      if ('ok' in result) {
        setMessage('Link confirmed! Balances have been merged.');
        setConfirmPrincipal('');
        fetchLinkData();
      } else {
        setError(Object.keys(result.err)[0]);
      }
    } catch (err) {
      console.error('Failed to confirm link:', err);
      setError(err.message || 'Failed to confirm link');
    } finally {
      setActionLoading(false);
    }
  };

  const handleRemoveLink = async (secondaryPrincipal) => {
    if (!authenticatedActor) return;

    try {
      setActionLoading(true);
      setError(null);
      setMessage(null);

      const result = await authenticatedActor.remove_link(secondaryPrincipal);

      if ('ok' in result) {
        setMessage('Link removed.');
        fetchLinkData();
      } else {
        setError(Object.keys(result.err)[0]);
      }
    } catch (err) {
      console.error('Failed to remove link:', err);
      setError(err.message || 'Failed to remove link');
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return <section className="link-manager loading">Loading link data...</section>;
  }

  const isPrimary = resolvedBag?.toString() === principal?.toString();
  const isLinked = !isPrimary && resolvedBag;

  return (
    <section className="link-manager">
      <h2>Principal Linking</h2>

      {error && <div className="alert alert-error">{error}</div>}
      {message && <div className="alert alert-success">{message}</div>}

      <div className="link-status">
        {isLinked ? (
          <p>
            This wallet is linked to: <PrincipalDisplay principal={resolvedBag} full />
          </p>
        ) : (
          <p>This is a primary wallet.</p>
        )}
      </div>

      {linkedPrincipals.length > 0 && (
        <div className="linked-list">
          <h3>Linked Wallets</h3>
          <ul>
            {linkedPrincipals.map((p) => (
              <li key={p.toString()}>
                <PrincipalDisplay principal={p} />
                <button
                  onClick={() => handleRemoveLink(p)}
                  disabled={actionLoading}
                  className="btn btn-small btn-danger"
                >
                  Remove
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}

      {!isLinked && (
        <>
          <div className="link-form">
            <h3>Request to Link (as Secondary)</h3>
            <p>Enter the primary wallet's principal to request linking this wallet to it.</p>
            <form onSubmit={handleRequestLink}>
              <input
                type="text"
                value={linkToPrincipal}
                onChange={(e) => setLinkToPrincipal(e.target.value)}
                placeholder="Primary principal"
                disabled={actionLoading}
              />
              <button type="submit" disabled={actionLoading || !linkToPrincipal.trim()} className="btn">
                Request Link
              </button>
            </form>
          </div>

          <div className="confirm-form">
            <h3>Confirm Link Request (as Primary)</h3>
            <p>Enter a secondary wallet's principal to confirm their link request.</p>
            <form onSubmit={handleConfirmLink}>
              <input
                type="text"
                value={confirmPrincipal}
                onChange={(e) => setConfirmPrincipal(e.target.value)}
                placeholder="Secondary principal"
                disabled={actionLoading}
              />
              <button type="submit" disabled={actionLoading || !confirmPrincipal.trim()} className="btn">
                Confirm Link
              </button>
            </form>
          </div>
        </>
      )}
    </section>
  );
}

export default LinkManager;
