import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { ActorProvider } from './contexts/ActorContext';
import { Layout } from './components/layout';
import { HomePage, UserPage, DavePage, AdminPage } from './pages';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ActorProvider>
          <Routes>
            <Route path="/" element={<Layout />}>
              <Route index element={<HomePage />} />
              <Route path="user" element={<UserPage />} />
              <Route path="dave" element={<DavePage />} />
              <Route path="admin" element={<AdminPage />} />
            </Route>
          </Routes>
        </ActorProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
