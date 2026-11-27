import { useState } from 'react'
import { api } from '../../shared/api'
import { Icons } from '../../shared/icons'

/** Keep only digits so pasted codes such as "123 456" remain convenient. */
export const normalizeVerificationCode = rawInput => String(rawInput || '').replace(/\D/g, '').slice(0, 6)

export default function VerifyEmail({ token: initialToken = '', accessToken = '', onBack, onVerified }) {
  const [manualInput, setManualInput] = useState(normalizeVerificationCode(initialToken))
  const [busy, setBusy] = useState(false)
  const [status, setStatus] = useState('idle') // 'idle' | 'verifying' | 'success' | 'error'
  const [message, setMessage] = useState('')

  async function confirmToken(rawValue) {
    const code = normalizeVerificationCode(rawValue)
    if (!/^\d{6}$/.test(code)) {
      setStatus('error')
      setMessage('Vui lòng nhập đủ 6 chữ số trong email.')
      return
    }
    setBusy(true)
    setStatus('verifying')
    setMessage('')
    try {
      await api('/auth/email-verification/confirm', {
        method: 'POST',
        body: JSON.stringify({ code }),
      }, accessToken)
      setStatus('success')
      setMessage('Email tài khoản Đối tác của bạn đã được xác minh thành công.')
      if (onVerified) onVerified()
    } catch (err) {
      setStatus('error')
      setMessage(err.message || 'Mã xác minh không hợp lệ hoặc đã hết hạn.')
    } finally {
      setBusy(false)
    }
  }

  function handleSubmit(e) {
    e.preventDefault()
    confirmToken(manualInput)
  }

  return (
    <main className="auth-page">
      <div className="auth-card-container">
        <div className="auth-card-header">
          <div className="auth-logo-circle">
            <Icons.Paw size={32} />
          </div>
          <span className="auth-kicker-pill">
            <Icons.Shield size={13} />
            PawCare Partner Portal
          </span>
          <h1 className="auth-title">Xác minh email Đối tác</h1>
          <p className="auth-subtitle">
            Xác nhận địa chỉ email để hoàn tất bảo mật tài khoản cơ sở chăm sóc thú cưng
          </p>
        </div>

        {status === 'verifying' && (
          <div className="auth-verify-state" role="status">
            <Icons.Refresh size={22} className="animate-spin text-teal" />
            <span>Đang xác thực mã xác minh email…</span>
          </div>
        )}

        {status === 'success' && (
          <div className="success-banner auth-banner-block" role="status">
            <div className="auth-banner-title">
              <Icons.CheckCircle size={18} />
              <span>Xác minh email thành công</span>
            </div>
            <p>{message}</p>
          </div>
        )}

        {status === 'error' && (
          <div className="error-alert" style={{ marginBottom: '16px' }}>
            <Icons.AlertCircle size={18} />
            <span>{message}</span>
          </div>
        )}

        {status !== 'success' && status !== 'verifying' && (
          <form className="auth-form" onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label" htmlFor="verify-token-input">
                Mã xác minh gồm 6 chữ số
              </label>
              <div className="auth-input-wrapper">
                <span className="input-icon">
                  <Icons.Mail size={16} />
                </span>
                <input
                  id="verify-token-input"
                  type="text"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  autoFocus
                  className="form-input with-icon"
                  value={manualInput}
                  onChange={e => setManualInput(normalizeVerificationCode(e.target.value))}
                  placeholder="Ví dụ: 123456"
                  maxLength="6"
                  required
                />
              </div>
              <p className="auth-hint">
                Mã có hiệu lực trong 10 phút và chỉ sử dụng được một lần.
              </p>
            </div>

            <button
              type="submit"
              className="btn-primary btn-block auth-btn-submit"
              disabled={busy}
            >
              {busy ? (
                <>
                  <Icons.Refresh size={16} className="animate-spin" />
                  <span>Đang xác minh…</span>
                </>
              ) : (
                <>
                  <span>Xác nhận email</span>
                  <Icons.ArrowRight size={16} />
                </>
              )}
            </button>
          </form>
        )}

        <div className="auth-actions-stack" style={{ marginTop: '18px' }}>
          <button
            type="button"
            className={status === 'success' ? 'btn-primary btn-block auth-btn-submit' : 'btn-secondary btn-block'}
            onClick={onBack}
          >
            {status === 'success' && accessToken
              ? 'Vào PawCare Provider Portal'
              : 'Quay lại đăng nhập'}
          </button>
        </div>

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
