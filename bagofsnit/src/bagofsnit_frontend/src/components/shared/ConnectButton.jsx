import { useAuth } from '../../hooks';

export function ConnectButton() {
  const { isAuthenticated, isLoading, principal, login, logout } = useAuth();

  if (isLoading) {
    return <button disabled>Loading...</button>;
  }

  if (isAuthenticated) {
    return (
      <div className="connect-info">
        <span className="principal" title={principal?.toString()}>
          {principal?.toString().slice(0, 8)}...{principal?.toString().slice(-4)}
        </span>
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
