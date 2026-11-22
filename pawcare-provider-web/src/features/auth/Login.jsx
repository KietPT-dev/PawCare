import { useState } from 'react'
import { api } from '../../shared/api'
import { Icons } from '../../shared/icons'

export default function Login({ onLogin }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  async function submit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      const session = await api('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      })
      if (session.profile?.role !== 'PROVIDER') {
        throw new Error('Tài khoản này không có quyền truy cập Provider Portal (Role must be PROVIDER).')
      }
      onLogin(session)
    } catch (e) {
      setError(e.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <main className="auth-page">
      <div className="auth-card-container">
        {/* Brand Header */}
        <div className="auth-card-header">
          <div className="auth-logo-circle">
            <Icons.Paw size={32} />
          </div>
          <span className="auth-kicker-pill">
            <Icons.Shield size={13} />
            PawCare Partner Portal
          </span>
          <h1 className="auth-title">Đăng nhập Đối tác</h1>
          <p className="auth-subtitle">
            Hệ thống quản lý dịch vụ, lịch hẹn và ví doanh thu cơ sở chăm sóc thú cưng
          </p>
        </div>

        {/* Login Form */}
        <form className="auth-form" onSubmit={submit}>
          {error && (
            <div className="error-alert" style={{ marginBottom: '18px' }}>
              <Icons.AlertCircle size={18} />
              <span>{error}</span>
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Email tài khoản Đối tác</label>
            <div className="auth-input-wrapper">
              <span className="input-icon">
                <Icons.User size={16} />
              </span>
              <input
                aria-label="Email"
                required
                type="email"
                className="form-input with-icon"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="partner@pawcare.vn"
                autoComplete="email"
              />
            </div>
          </div>

          <div className="form-group">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <label className="form-label">Mật khẩu</label>
              <button
                type="button"
                className="btn-text-link"
                onClick={() => alert('Vui lòng liên hệ Admin PawCare (hotline: 1900-PAWCARE) hoặc ứng dụng PawCare Mobile để đặt lại mật khẩu.')}
              >
                Quên mật khẩu?
              </button>
            </div>
            <div className="auth-input-wrapper">
              <span className="input-icon">
                <Icons.Shield size={16} />
              </span>
              <input
                aria-label="Mật khẩu"
                required
                type={showPassword ? 'text' : 'password'}
                className="form-input with-icon with-action"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                autoComplete="current-password"
              />
              <button
                type="button"
                className="input-action-btn"
                onClick={() => setShowPassword(!showPassword)}
                title={showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
              >
                {showPassword ? 'Ẩn' : 'Hiện'}
              </button>
            </div>
          </div>

          <button
            type="submit"
            className="btn-primary btn-block auth-btn-submit"
            disabled={busy}
          >
            {busy ? (
              <>
                <Icons.Refresh size={16} className="animate-spin" />
                <span>Đang xác thực…</span>
              </>
            ) : (
              <>
                <span>Đăng nhập vào Portal</span>
                <Icons.ArrowRight size={16} />
              </>
            )}
          </button>
        </form>

        {/* Escrow Trust Footer */}
        <div className="auth-card-footer">
          <div className="auth-trust-badge">
            <Icons.Shield size={16} className="text-teal" />
            <span>Được bảo vệ và bảo chứng bởi PawCare Escrow System</span>
          </div>
        </div>
      </div>
    </main>
  )
}
