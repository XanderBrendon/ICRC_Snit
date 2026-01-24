import { Principal } from '@dfinity/principal';

export function PrincipalDisplay({ principal, full = false }) {
  if (!principal) return <span className="principal-empty">-</span>;

  // Handle both Principal objects and strings
  const principalStr = typeof principal === 'string'
    ? principal
    : principal.toString();

  if (full) {
    return (
      <code className="principal principal-full" title={principalStr}>
        {principalStr}
      </code>
    );
  }

  return (
    <code className="principal principal-short" title={principalStr}>
      {principalStr.slice(0, 8)}...{principalStr.slice(-4)}
    </code>
  );
}

export default PrincipalDisplay;
