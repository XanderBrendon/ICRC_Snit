import { useAuth } from '../../hooks';
import { PrincipalDisplay } from './PrincipalDisplay';

export function ConnectButton() {
  const { isAuthenticated, isLoading, principal, login, logout } = useAuth();

  if (isLoading) {
    return <button disabled>Loading...</button>;
  }

  if (isAuthenticated) {
    return (
      <div className="connect-info">
        <PrincipalDisplay principal={principal} />
        <button onClick={logout} className="btn btn-secondary">
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <button onClick={login} className="btn btn-primary">
      Connect Wallet
    </button>
  );
}

export default ConnectButton;
