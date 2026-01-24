import { useAuth } from '../hooks';

export function HomePage() {
  const { isAuthenticated, login } = useAuth();

  return (
    <div className="page home-page">
      <section className="hero">
        <h1>Welcome to BagOfSnit</h1>
        <p>Your wallet for SNIT - the non-transferable engagement token on the Internet Computer.</p>

        {!isAuthenticated && (
          <div className="cta">
            <button onClick={login} className="btn btn-primary btn-large">
              Connect with Internet Identity
            </button>
          </div>
        )}
      </section>

      <section className="features">
        <div className="feature-card">
          <h3>Earn SNIT</h3>
          <p>Partner apps (Daves) mint SNIT to reward your engagement.</p>
        </div>
        <div className="feature-card">
          <h3>Burn to Access</h3>
          <p>Spend SNIT to unlock premium content and features.</p>
        </div>
        <div className="feature-card">
          <h3>Link Wallets</h3>
          <p>Connect multiple principals to share one SNIT balance.</p>
        </div>
      </section>
    </div>
  );
}

export default HomePage;
