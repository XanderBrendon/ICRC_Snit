import { useState, useEffect } from 'react';
import { useAuth, useActor } from '../../hooks';

export function DaveRegistration() {
  const { principal } = useAuth();
  const { actor, authenticatedActor, isReady } = useActor();
  const [isRegistered, setIsRegistered] = useState(null);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    if (!isReady || !principal) return;

    const checkRegistration = async () => {
      try {
        setLoading(true);
        const result = await actor.snit_dave_profile(principal);
        setIsRegistered(result.length > 0);
      } catch (err) {
        console.error('Failed to check registration:', err);
      } finally {
        setLoading(false);
      }
    };

    checkRegistration();
  }, [actor, principal, isReady]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!authenticatedActor || !name.trim()) return;

    try {
      setSubmitting(true);
      setError(null);
      setSuccess(null);

      const result = await authenticatedActor.dave_register(
        name.trim(),
        description.trim() ? [description.trim()] : []
      );

      if ('ok' in result) {
        setSuccess('Registration submitted! Your Dave is pending admin approval.');
        setIsRegistered(true);
      } else {
        const errorKey = Object.keys(result.err)[0];
        setError(errorKey);
      }
    } catch (err) {
      console.error('Failed to register:', err);
      setError(err.message || 'Failed to register');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return <section className="dave-registration loading">Loading...</section>;
  }

  if (isRegistered) {
    return null; // DaveStatus component will show the status
  }

  return (
    <section className="dave-registration">
      <h2>Register as a Dave</h2>
      <p>Register your application to be able to mint SNIT to your users.</p>

      {error && <div className="alert alert-error">{error}</div>}
      {success && <div className="alert alert-success">{success}</div>}

      <form onSubmit={handleSubmit} className="registration-form">
        <div className="form-group">
          <label htmlFor="dave-name">Application Name *</label>
          <input
            id="dave-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="My Awesome App"
            disabled={submitting}
            required
          />
        </div>

        <div className="form-group">
          <label htmlFor="dave-description">Description</label>
          <textarea
            id="dave-description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Brief description of your application"
            disabled={submitting}
            rows={3}
          />
        </div>

        <button type="submit" disabled={submitting || !name.trim()} className="btn btn-primary">
          {submitting ? 'Registering...' : 'Register Dave'}
        </button>
      </form>
    </section>
  );
}

export default DaveRegistration;
