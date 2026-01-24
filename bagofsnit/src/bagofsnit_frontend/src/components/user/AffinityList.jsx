import { useState, useEffect } from 'react';
import { useAuth, useActor } from '../../hooks';
import { PrincipalDisplay } from '../shared';

export function AffinityList() {
  const { principal } = useAuth();
  const { actor, isReady } = useActor();
  const [affinities, setAffinities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!isReady || !principal) return;

    const fetchAffinities = async () => {
      try {
        setLoading(true);
        setError(null);
        const result = await actor.snit_user_affinities(principal);
        setAffinities(result);
      } catch (err) {
        console.error('Failed to fetch affinities:', err);
        setError(err.message || 'Failed to load affinities');
      } finally {
        setLoading(false);
      }
    };

    fetchAffinities();
  }, [actor, principal, isReady]);

  if (loading) {
    return <section className="affinity-list loading">Loading affinities...</section>;
  }

  if (error) {
    return <section className="affinity-list error">Error: {error}</section>;
  }

  if (affinities.length === 0) {
    return (
      <section className="affinity-list empty">
        <h2>Affinities</h2>
        <p>No affinities yet. Earn SNIT from Dave apps to build affinity!</p>
      </section>
    );
  }

  return (
    <section className="affinity-list">
      <h2>Affinities</h2>
      <div className="affinity-grid">
        {affinities.map(([davePrincipal, affinity]) => (
          <div key={davePrincipal.toString()} className="affinity-card">
            <div className="affinity-header">
              <PrincipalDisplay principal={davePrincipal} />
            </div>
            <div className="affinity-stats">
              <div className="affinity-stat">
                <span className="stat-value">{affinity.level?.toString() || '0'}</span>
                <span className="stat-label">Level</span>
              </div>
              <div className="affinity-stat">
                <span className="stat-value">{affinity.dust?.toString() || '0'}</span>
                <span className="stat-label">Dust</span>
              </div>
              <div className="affinity-stat">
                <span className="stat-value">{affinity.total_minted?.toString() || '0'}</span>
                <span className="stat-label">Minted</span>
              </div>
              <div className="affinity-stat">
                <span className="stat-value">{affinity.total_burned?.toString() || '0'}</span>
                <span className="stat-label">Burned</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}

export default AffinityList;
