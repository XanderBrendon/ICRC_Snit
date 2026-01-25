import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { AuthClient } from '@dfinity/auth-client';
import { HttpAgent } from '@dfinity/agent';

const AuthContext = createContext(null);

// Internet Identity URL - use mainnet II for local development too
const II_URL = process.env.DFX_NETWORK === 'ic'
  ? 'https://identity.ic0.app'
  : `http://${process.env.CANISTER_ID_INTERNET_IDENTITY || 'rdmx6-jaaaa-aaaaa-aaadq-cai'}.localhost:4943`;

export function AuthProvider({ children }) {
  const [authClient, setAuthClient] = useState(null);
  const [identity, setIdentity] = useState(null);
  const [principal, setPrincipal] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [agent, setAgent] = useState(null);

  // Initialize auth client on mount
  useEffect(() => {
    const init = async () => {
      try {
        const client = await AuthClient.create();
        setAuthClient(client);

        const authenticated = await client.isAuthenticated();
        if (authenticated) {
          const identity = client.getIdentity();
          const principal = identity.getPrincipal();

          setIdentity(identity);
          setPrincipal(principal);
          setIsAuthenticated(true);

          // Create agent with identity
          const agent = new HttpAgent({
            identity,
            host: process.env.DFX_NETWORK === 'ic'
              ? 'https://ic0.app'
              : 'http://127.0.0.1:4943'
          });

          // Fetch root key for local development
          if (process.env.DFX_NETWORK !== 'ic') {
            await agent.fetchRootKey();
          }

          setAgent(agent);
        }
      } catch (error) {
        console.error('Failed to initialize auth client:', error);
      } finally {
        setIsLoading(false);
      }
    };

    init();
  }, []);

  const login = useCallback(async () => {
    if (!authClient) return;

    return new Promise((resolve, reject) => {
      authClient.login({
        identityProvider: II_URL,
        maxTimeToLive: BigInt(30 * 24 * 60 * 60 * 1000 * 1000 * 1000), // 30 days in nanoseconds (max allowed)
        onSuccess: async () => {
          const identity = authClient.getIdentity();
          const principal = identity.getPrincipal();

          setIdentity(identity);
          setPrincipal(principal);
          setIsAuthenticated(true);

          // Create agent with identity
          const agent = new HttpAgent({
            identity,
            host: process.env.DFX_NETWORK === 'ic'
              ? 'https://ic0.app'
              : 'http://127.0.0.1:4943'
          });

          // Fetch root key for local development
          if (process.env.DFX_NETWORK !== 'ic') {
            await agent.fetchRootKey();
          }

          setAgent(agent);
          resolve();
        },
        onError: (error) => {
          console.error('Login failed:', error);
          reject(error);
        },
      });
    });
  }, [authClient]);

  const logout = useCallback(async () => {
    if (!authClient) return;

    await authClient.logout();
    setIdentity(null);
    setPrincipal(null);
    setIsAuthenticated(false);
    setAgent(null);
  }, [authClient]);

  const value = {
    authClient,
    identity,
    principal,
    isAuthenticated,
    isLoading,
    agent,
    login,
    logout,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

export default AuthContext;
