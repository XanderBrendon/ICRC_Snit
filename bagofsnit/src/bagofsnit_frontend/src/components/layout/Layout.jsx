import { Outlet } from 'react-router-dom';
import { Header } from './Header';

export function Layout() {
  return (
    <div className="app-layout">
      <Header />
      <main className="app-main">
        <Outlet />
      </main>
      <footer className="app-footer">
        <p>SNIT - Non-transferable engagement tokens on the Internet Computer</p>
      </footer>
    </div>
  );
}

export default Layout;
