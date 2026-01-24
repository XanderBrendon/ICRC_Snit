import { NavLink } from 'react-router-dom';
import { useAuth } from '../../hooks';

export function Navigation() {
  const { isAuthenticated } = useAuth();

  return (
    <nav className="main-nav">
      <NavLink to="/" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
        Home
      </NavLink>

      {isAuthenticated && (
        <>
          <NavLink to="/user" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            My Wallet
          </NavLink>
          <NavLink to="/dave" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Dave Portal
          </NavLink>
          <NavLink to="/admin" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Admin
          </NavLink>
        </>
      )}
    </nav>
  );
}

export default Navigation;
