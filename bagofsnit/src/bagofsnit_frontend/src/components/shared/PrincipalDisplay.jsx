import { useState } from 'react';
import { Principal } from '@dfinity/principal';

export function PrincipalDisplay({ principal, full = false }) {
  const [copied, setCopied] = useState(false);

  if (!principal) return <span className="principal-empty">-</span>;

  // Handle both Principal objects and strings
  const principalStr = typeof principal === 'string'
    ? principal
    : principal.toString();

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(principalStr);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  const displayText = full
    ? principalStr
    : `${principalStr.slice(0, 8)}...${principalStr.slice(-4)}`;

  return (
    <span className={`principal-container ${full ? 'principal-full' : 'principal-short'}`}>
      <code className="principal" title={principalStr}>
        {displayText}
      </code>
      <button
        className="copy-btn"
        onClick={handleCopy}
        title={copied ? 'Copied!' : 'Copy principal'}
        aria-label="Copy principal to clipboard"
      >
        {copied ? (
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <polyline points="20 6 9 17 4 12" />
          </svg>
        ) : (
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
          </svg>
        )}
      </button>
    </span>
  );
}

export default PrincipalDisplay;
