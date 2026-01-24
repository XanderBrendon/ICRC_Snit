import { Link } from 'react-router-dom';
import { Navigation } from './Navigation';
import { ConnectButton } from '../shared';

export function Header() {
  return (
    <header className="app-header">
      <div className="header-left">
        <Link to="/" className="logo">
          <span className="logo-icon">S</span>
          <span className="logo-text">BagOfSnit</span>
        </Link>
        <Navigation />
      </div>
      <div className="header-right">
        <ConnectButton />
      </div>
    </header>
  );
}

export default Header;
