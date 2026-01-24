import { useAuth } from '../hooks';
import { DaveRegistration } from '../components/dave/DaveRegistration';
import { DaveStatus } from '../components/dave/DaveStatus';

export function DavePage() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <div className="page loading">Loading...</div>;
  }

  if (!isAuthenticated) {
    return (
      <div className="page dave-page">
        <h1>Dave Portal</h1>
        <p>Please connect your wallet to register as a Dave or view your status.</p>
      </div>
    );
  }

  return (
    <div className="page dave-page">
      <h1>Dave Portal</h1>
      <p>Register your application as a Dave to mint SNIT to your users.</p>
      <DaveStatus />
      <DaveRegistration />
    </div>
  );
}

export default DavePage;
