import { createRoot } from 'react-dom/client'
import { useEffect, useState, useRef } from 'react'
import './styles.css'
import { api, rowsOf } from './shared/api'
import { dateTime } from './shared/format'
import { Icons } from './shared/icons'
import Login from './features/auth/Login'
import Register from './features/auth/Register'
import VerifyEmail from './features/auth/VerifyEmail'
import { ChangePassword, ForgotPassword, ResetPassword } from './features/auth/AuthRecovery'
import Dashboard from './features/dashboard/Dashboard'
import BookingsPage from './features/bookings/BookingsPage'
import OperationsPage from './features/operations/OperationsPage'
import WalletPage from './features/wallet/WalletPage'
import ReportsPage from './features/reports/ReportsPage'
import Notifications from './features/notifications/Notifications'
import ReviewsPage from './features/reviews/ReviewsPage'
import ProviderStoreSettings from './features/profile/ProviderStoreSettings'
import MessagesPage from './features/messages/MessagesPage'

const storage = {
  token: 'pawcareProviderToken',
  refresh: 'pawcareProviderRefreshToken',
  profile: 'pawcareProviderProfile'
}

const menu = [
  { key: 'dashboard', icon: <Icons.Dashboard size={18} />, label: 'Tổng quan' },
  { key: 'services', icon: <Icons.Services size={18} />, label: 'Dịch vụ' },
  { key: 'staff', icon: <Icons.Staff size={18} />, label: 'Nhân viên' },
  { key: 'schedules', icon: <Icons.Schedules size={18} />, label: 'Lịch làm việc' },
  { key: 'bookings', icon: <Icons.Bookings size={18} />, label: 'Booking' },
  { key: 'wallet', icon: <Icons.Wallet size={18} />, label: 'Ví doanh thu' },
  { key: 'reports', icon: <Icons.Reports size={18} />, label: 'Báo cáo' },
  { key: 'reviews', icon: <Icons.Reviews size={18} />, label: 'Đánh giá' },
  { key: 'notifications', icon: <Icons.Bell size={18} />, label: 'Thông báo' },
  { key: 'messages', icon: <Icons.Chat size={18} />, label: 'Tin nhắn' },
]

function App() {
  const [token, setToken] = useState(localStorage[storage.token] || '')
  const [refresh, setRefresh] = useState(localStorage[storage.refresh] || '')
  const [page, setPage] = useState('dashboard')
  const [bookings, setBookings] = useState([])
  const [dashboard, setDashboard] = useState({})
  const [notifications, setNotifications] = useState([])
  const [notice, setNotice] = useState('')
  const [account, setAccount] = useState(null)
  const [authScreen, setAuthScreen] = useState(() => {
    if (window.location.pathname === '/reset-password') return 'reset'
    if (window.location.pathname === '/verify-email') return 'verify-email'
    return 'login'
  })
  const [verificationBusy, setVerificationBusy] = useState(false)
  const [verificationCooldown, setVerificationCooldown] = useState(0)
  const [syncing, setSyncing] = useState(false)
  const [lastSyncTime, setLastSyncTime] = useState('')

  // Topbar dropdown states
  const [notifDropdownOpen, setNotifDropdownOpen] = useState(false)
  const [userDropdownOpen, setUserDropdownOpen] = useState(false)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [settingsModalOpen, setSettingsModalOpen] = useState(false)

  // Profile info
  let profile = {}
  try {
    profile = JSON.parse(localStorage[storage.profile] || '{}')
  } catch (_) {}

  const clinicName = profile.fullName || profile.name || profile.clinicName || 'PawCare Partner'
  const clinicInitials = (clinicName.split(' ').map(w => w[0]).join('').slice(0, 2) || 'PC').toUpperCase()

  const logout = () => {
    Object.values(storage).forEach(k => localStorage.removeItem(k))
    setToken('')
    setRefresh('')
    setAccount(null)
  }

  const login = s => {
    localStorage[storage.token] = s.accessToken
    localStorage[storage.refresh] = s.refreshToken
    localStorage[storage.profile] = JSON.stringify(s.profile)
    setToken(s.accessToken)
    setRefresh(s.refreshToken)
  }

  const reload = async () => {
    if (!token) return
    setSyncing(true)
    try {
      const [b, d, n, currentAccount] = await Promise.all([
        api('/bookings', {}, token),
        api('/provider/dashboard', {}, token),
        api('/notifications', {}, token).catch(() => []),
        api('/auth/me', {}, token).catch(() => null)
      ])
      setBookings(rowsOf(b))
      setDashboard(d)
      setNotifications(rowsOf(n))
      if (currentAccount) setAccount(currentAccount)
      setNotice('')
      const now = new Date()
      setLastSyncTime(`${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`)
    } catch (e) {
      setNotice(e.message)
    } finally {
      setSyncing(false)
    }
  }

  useEffect(() => {
    const expired = () => {
      setNotice('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.')
      logout()
    }
    window.addEventListener('pawcare:unauthorized', expired)
    return () => window.removeEventListener('pawcare:unauthorized', expired)
  }, [])

  useEffect(() => {
    reload()
  }, [token])

  useEffect(() => {
    if (!verificationCooldown) return
    const interval = window.setInterval(() => setVerificationCooldown(value => Math.max(0, value - 1)), 1000)
    return () => window.clearInterval(interval)
  }, [verificationCooldown])

  const requestVerification = async () => {
    setVerificationBusy(true)
    try {
      await api('/auth/email-verification/request', { method: 'POST' }, token)
      setVerificationCooldown(60)
      setNotice('Đã gửi email xác minh. Vui lòng kiểm tra hộp thư của bạn.')
    } catch (error) {
      setNotice(error.message || 'Không thể gửi email xác minh. Vui lòng thử lại.')
    } finally {
      setVerificationBusy(false)
    }
  }

  const handlePasswordChanged = () => {
    setSettingsModalOpen(false)
    setNotice('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.')
    logout()
  }

  const exitAuthSubRoute = () => {
    window.history.replaceState({}, '', '/')
    setAuthScreen('login')
  }

  const resetSucceeded = () => {
    exitAuthSubRoute()
    setNotice('Đặt lại mật khẩu thành công. Bạn có thể đăng nhập.')
  }

  const registerCompleted = session => {
    window.history.replaceState({}, '', '/')
    setAuthScreen('login')
    setNotice('')
    login(session)
  }

  // Token auto refresh
  useEffect(() => {
    if (!token || !refresh) return
    let id
    try {
      const exp = JSON.parse(atob(token.split('.')[1])).exp * 1000
      id = setTimeout(async () => {
        try {
          login(await api('/auth/refresh', { method: 'POST', body: JSON.stringify({ refreshToken: refresh }) }))
        } catch {
          window.dispatchEvent(new Event('pawcare:unauthorized'))
        }
      }, Math.max(0, exp - Date.now() - 60000))
    } catch {
      logout()
    }
    return () => clearTimeout(id)
  }, [token, refresh])

  // Close dropdowns when clicking outside
  useEffect(() => {
    function handleClickOutside(e) {
      if (!e.target.closest('.dropdown-wrap')) {
        setNotifDropdownOpen(false)
        setUserDropdownOpen(false)
      }
    }
    window.addEventListener('click', handleClickOutside)
    return () => window.removeEventListener('click', handleClickOutside)
  }, [])

  if (!token) {
    const actionToken = new URLSearchParams(window.location.search).get('token') || ''
    return (
      <>
        {authScreen === 'forgot' && <ForgotPassword onBack={() => setAuthScreen('login')} />}
        {authScreen === 'reset' && <ResetPassword token={actionToken} onBack={exitAuthSubRoute} onSuccess={resetSucceeded} />}
        {authScreen === 'register' && <Register onBack={() => setAuthScreen('login')} onComplete={registerCompleted} />}
        {authScreen === 'verify-email' && <VerifyEmail token={actionToken} onBack={exitAuthSubRoute} />}
        {authScreen === 'login' && (
          <Login
            onLogin={login}
            onForgotPassword={() => setAuthScreen('forgot')}
            onRegister={() => {
              setNotice('')
              setAuthScreen('register')
            }}
          />
        )}
        {notice && <p className="session-notice">{notice}</p>}
      </>
    )
  }

  if (authScreen === 'verify-email') {
    const verifyToken = new URLSearchParams(window.location.search).get('token') || ''
    return (
      <VerifyEmail
        token={verifyToken}
        accessToken={token}
        onVerified={reload}
        onBack={exitAuthSubRoute}
      />
    )
  }

  const unreadNotifs = notifications.filter(n => !n.is_read)
  const unreadCount = unreadNotifs.length

  const content = {
    dashboard: <Dashboard bookings={bookings} dashboard={dashboard} onNavigate={setPage} onRefresh={reload} />,
    bookings: <BookingsPage token={token} onMutated={reload} onOpenMessages={() => setPage('messages')} />,
    services: <OperationsPage kind="services" token={token} />,
    staff: <OperationsPage kind="staff" token={token} />,
    schedules: <OperationsPage kind="schedules" token={token} />,
    wallet: <WalletPage token={token} />,
    reports: <ReportsPage token={token} />,
    notifications: <Notifications token={token} onBooking={() => setPage('bookings')} />,
    reviews: <ReviewsPage token={token} />,
    messages: <MessagesPage token={token} />,
  }[page]

  return (
    <div className="app-shell">
      {/* Mobile Drawer Backdrop */}
      {mobileMenuOpen && (
        <div className="sidebar-backdrop" onClick={() => setMobileMenuOpen(false)} />
      )}

      {/* Sidebar Navigation */}
      <aside className={`sidebar ${mobileMenuOpen ? 'mobile-open' : ''}`}>
        <div className="sidebar-logo">
          <div className="logo-brand">
            <div className="logo-icon-wrap">
              <Icons.Paw size={22} />
            </div>
            <div>
              <div className="logo-text">PawCare</div>
              <span className="logo-badge">Provider Portal</span>
            </div>
          </div>
        </div>

        {/* Clinic Info Widget */}
        <div className="sidebar-clinic-card">
          <div className="clinic-avatar">{clinicInitials}</div>
          <div className="clinic-info">
            <span className="clinic-name" title={clinicName}>{clinicName}</span>
            <span className="clinic-status">
              <span className="status-dot-pulse" /> Đang hoạt động
            </span>
          </div>
        </div>

        {/* Navigation Menu */}
        <nav className="sidebar-nav">
          {menu.map(item => {
            const isActive = page === item.key
            return (
              <button
                key={item.key}
                className={`nav-link ${isActive ? 'active' : ''}`}
                onClick={() => {
                  setPage(item.key)
                  setMobileMenuOpen(false)
                }}
              >
                <span className="nav-icon">{item.icon}</span>
                <span>{item.label}</span>
                {item.key === 'notifications' && unreadCount > 0 && (
                  <span className="nav-badge-pill">{unreadCount}</span>
                )}
              </button>
            )
          })}
        </nav>

        {/* Sidebar Footer */}
        <div className="sidebar-footer">
          <div className="escrow-verified-card">
            <div className="escrow-icon">
              <Icons.Shield size={18} />
            </div>
            <div className="escrow-text">
              <strong>Bảo vệ Escrow 100%</strong>
              <span>An toàn thanh toán & dòng tiền</span>
            </div>
          </div>

          <button className="logout-btn" onClick={logout}>
            <Icons.Logout size={16} />
            <span>Đăng xuất</span>
          </button>
        </div>
      </aside>

      {/* Main Area */}
      <main>
        {/* Topbar */}
        <header className="topbar">
          <div className="topbar-left">
            <button
              type="button"
              className="mobile-menu-btn"
              aria-label="Mở menu"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <Icons.Menu size={20} />
            </button>
            <div className="topbar-search-box">
              <Icons.Search size={16} />
              <input
                type="text"
                className="topbar-search-input"
                placeholder="Tìm kiếm nhanh đơn, dịch vụ, khách..."
                onKeyDown={e => {
                  if (e.key === 'Enter' && e.target.value.trim()) {
                    setPage('bookings')
                  }
                }}
              />
            </div>
          </div>

          <div className="topbar-actions">
            {/* 1. Nút Đồng bộ */}
            <button
              type="button"
              className={`sync-btn ${syncing ? 'spinning' : ''}`}
              title={lastSyncTime ? `Lần đồng bộ gần nhất: ${lastSyncTime}` : 'Đồng bộ dữ liệu'}
              onClick={reload}
            >
              <span className="sync-icon"><Icons.Refresh size={14} /></span>
              <span>{syncing ? 'Đang đồng bộ...' : 'Đồng bộ'}</span>
            </button>

            {/* 2. Nút Chuông thông báo */}
            <div className="dropdown-wrap">
              <button
                type="button"
                className={`icon-btn-badge ${notifDropdownOpen ? 'active' : ''}`}
                aria-label="Thông báo"
                onClick={() => {
                  setNotifDropdownOpen(!notifDropdownOpen)
                  setUserDropdownOpen(false)
                }}
              >
                <Icons.Bell size={18} />
                {unreadCount > 0 && <span className="unread-badge">{unreadCount > 9 ? '9+' : unreadCount}</span>}
              </button>

              {notifDropdownOpen && (
                <div className="dropdown-menu">
                  <div className="dropdown-header">
                    <h4>Thông báo</h4>
                    <span className="logo-badge">{unreadCount} chưa đọc</span>
                  </div>
                  <div className="notif-preview-list">
                    {notifications.length > 0 ? (
                      notifications.slice(0, 4).map(n => (
                        <div
                          key={n.id}
                          className={`notif-preview-item ${!n.is_read ? 'unread' : ''}`}
                          onClick={() => {
                            setNotifDropdownOpen(false)
                            setPage('notifications')
                          }}
                        >
                          <div className="notif-preview-title">{n.title}</div>
                          <div className="notif-preview-content">{n.content}</div>
                          <div className="notif-preview-time">{dateTime(n.created_at)}</div>
                        </div>
                      ))
                    ) : (
                      <div className="empty-state" style={{ padding: '24px 12px' }}>
                        <p className="empty-state-note">Chưa có thông báo nào mới</p>
                      </div>
                    )}
                  </div>
                  <button
                    type="button"
                    className="dropdown-view-all"
                    onClick={() => {
                      setNotifDropdownOpen(false)
                      setPage('notifications')
                    }}
                  >
                    Xem tất cả thông báo →
                  </button>
                </div>
              )}
            </div>

            {/* 3. Nút Tài khoản / Avatar */}
            <div className="dropdown-wrap">
              <button
                type="button"
                className={`user-account-btn ${userDropdownOpen ? 'active' : ''}`}
                onClick={() => {
                  setUserDropdownOpen(!userDropdownOpen)
                  setNotifDropdownOpen(false)
                }}
              >
                <div className="user-avatar-mini">{clinicInitials}</div>
                <div className="user-name-role">
                  <span className="user-name">{clinicName}</span>
                  <span className="user-role-label">Provider Partner</span>
                </div>
                <Icons.ChevronDown size={14} className="text-muted" />
              </button>

              {userDropdownOpen && (
                <div className="dropdown-menu user-menu">
                  <div className="dropdown-header">
                    <div>
                      <div className="user-name" style={{ fontSize: '13.5px' }}>{clinicName}</div>
                      <span className="text-muted" style={{ fontSize: '11px' }}>{profile.email || 'partner@pawcare.vn'}</span>
                    </div>
                  </div>
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => {
                      setUserDropdownOpen(false)
                      setSettingsModalOpen(true)
                    }}
                  >
                    <Icons.Building size={16} />
                    <span>Thông tin cơ sở</span>
                  </button>
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => {
                      setUserDropdownOpen(false)
                      setPage('wallet')
                    }}
                  >
                    <Icons.Wallet size={16} />
                    <span>Ví & Tài khoản ngân hàng</span>
                  </button>
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => {
                      setUserDropdownOpen(false)
                      setSettingsModalOpen(true)
                    }}
                  >
                    <Icons.Shield size={16} />
                    <span>Cài đặt & Bảo mật</span>
                  </button>
                  <div className="dropdown-divider" />
                  <button
                    type="button"
                    className="dropdown-item danger"
                    onClick={() => {
                      setUserDropdownOpen(false)
                      logout()
                    }}
                  >
                    <Icons.Logout size={16} />
                    <span>Đăng xuất</span>
                  </button>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Content Body */}
        <div className="content">
          {notice && <div className="error-alert">⚠ {notice}</div>}
          {(account?.emailVerified === false || account?.emailVerified === 0) && (
            <div className="approval email-verification-banner" role="status">
              <div><strong>Email chưa được xác minh</strong><span>Xác minh email để tăng độ an toàn cho tài khoản Provider.</span></div>
              <button type="button" className="btn-secondary" disabled={verificationBusy || verificationCooldown > 0} onClick={requestVerification}>
                {verificationBusy ? 'Đang gửi…' : verificationCooldown > 0 ? `Gửi lại sau ${verificationCooldown}s` : 'Gửi email xác minh'}
              </button>
            </div>
          )}
          {content}
        </div>
      </main>

      {/* Account Settings / Profile Modal (UI Preview) */}
      {settingsModalOpen && (
        <div className="modal-overlay" onClick={() => setSettingsModalOpen(false)}>
          <div className="modal-container" onClick={e => e.stopPropagation()} style={{ maxWidth: '540px' }}>
            <div className="modal-header">
              <div>
                <h3 className="modal-title">Hồ sơ cơ sở kinh doanh</h3>
                <p className="modal-subtitle">Thông tin vận hành và tài khoản Provider trên PawCare</p>
              </div>
              <button type="button" className="modal-close-btn" onClick={() => setSettingsModalOpen(false)}>
                <Icons.Close size={18} />
              </button>
            </div>
            <div className="modal-body">
              <ProviderStoreSettings token={token} onClose={() => setSettingsModalOpen(false)} />
              <ChangePassword token={token} onSuccess={handlePasswordChanged} />
              <div className="legacy-settings" aria-hidden="true">
              <div className="form-grid">
                <div className="form-group form-full">
                  <label className="form-label">Tên cơ sở / Đối tác</label>
                  <input type="text" className="form-input" defaultValue={clinicName} readOnly />
                </div>
                <div className="form-group">
                  <label className="form-label">Email quản lý</label>
                  <input type="email" className="form-input" defaultValue={profile.email || 'partner@pawcare.vn'} readOnly />
                </div>
                <div className="form-group">
                  <label className="form-label">Vai trò</label>
                  <input type="text" className="form-input" defaultValue="PROVIDER (Cơ sở đối tác)" readOnly />
                </div>
                <div className="form-group form-full">
                  <label className="form-label">Trạng thái bảo chứng</label>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 14px', background: 'var(--teal-50)', borderRadius: 'var(--radius-md)', border: '1px solid var(--teal-100)' }}>
                    <Icons.Shield size={18} className="text-teal" />
                    <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--teal-700)' }}>Đã xác minh PawCare Escrow Partner</span>
                  </div>
                </div>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-secondary" onClick={() => setSettingsModalOpen(false)}>
                  Đóng
                </button>
              </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

createRoot(document.getElementById('root')).render(<App />)
