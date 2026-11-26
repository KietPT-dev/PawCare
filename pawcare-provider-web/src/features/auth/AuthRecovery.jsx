import { useState } from 'react'
import { api } from '../../shared/api'

const genericResetMessage = 'Nếu email tồn tại, PawCare đã gửi hướng dẫn đặt lại mật khẩu.'
const passwordIsValid = value => value.length >= 10 && /[A-Za-z]/.test(value) && /\d/.test(value)

function PasswordInput({ label, value, onChange, autoComplete, visible }) {
  return <label className="form-label">{label}<input className="form-input" type={visible ? 'text' : 'password'} value={value} onChange={event => onChange(event.target.value)} autoComplete={autoComplete} required /></label>
}

export function ForgotPassword({ onBack }) {
  const [email, setEmail] = useState(''), [busy, setBusy] = useState(false), [sent, setSent] = useState(false), [error, setError] = useState('')
  async function submit(event) {
    event.preventDefault(); setBusy(true); setError('')
    try { await api('/auth/password-reset/request', { method: 'POST', body: JSON.stringify({ email }) }); setSent(true) }
    catch (_) { setError('Không thể gửi yêu cầu lúc này. Vui lòng kiểm tra kết nối và thử lại.') }
    finally { setBusy(false) }
  }
  return <main className="auth-page"><div className="auth-card-container"><h1 className="auth-title">Đặt lại mật khẩu</h1><p className="auth-subtitle">Nhập email tài khoản Provider để nhận hướng dẫn đặt lại mật khẩu.</p>{sent ? <div className="success-banner">{genericResetMessage}</div> : <form className="auth-form" onSubmit={submit}><label className="form-label">Email tài khoản Provider<input className="form-input" type="email" required autoComplete="email" value={email} onChange={event => setEmail(event.target.value)} /></label>{error && <div className="error-alert">{error}</div>}<button className="btn-primary btn-block" disabled={busy}>{busy ? 'Đang gửi…' : 'Gửi hướng dẫn'}</button></form>}<button type="button" className="btn-text-link" onClick={onBack}>← Quay lại đăng nhập</button></div></main>
}

export function ResetPassword({ token, onBack, onSuccess }) {
  const [newPassword, setNewPassword] = useState(''), [confirmPassword, setConfirmPassword] = useState(''), [showPasswords, setShowPasswords] = useState(false), [busy, setBusy] = useState(false), [error, setError] = useState('')
  async function submit(event) {
    event.preventDefault()
    if (!passwordIsValid(newPassword)) return setError('Mật khẩu cần ít nhất 10 ký tự, gồm chữ và số.')
    if (newPassword !== confirmPassword) return setError('Xác nhận mật khẩu chưa khớp.')
    setBusy(true); setError('')
    try { await api('/auth/password-reset/confirm', { method: 'POST', body: JSON.stringify({ token, newPassword }) }); onSuccess() }
    catch (requestError) { setError(requestError.message || 'Không thể đặt lại mật khẩu. Vui lòng thử lại.') }
    finally { setBusy(false) }
  }
  return <main className="auth-page"><div className="auth-card-container"><h1 className="auth-title">Mật khẩu mới</h1>{!token ? <><p className="auth-subtitle">Bạn cần mở liên kết đặt lại mật khẩu trong email.</p><button type="button" className="btn-text-link" onClick={onBack}>Quay lại đăng nhập</button></> : <><p className="auth-subtitle">Mật khẩu cần ít nhất 10 ký tự, gồm chữ và số.</p><form className="auth-form" onSubmit={submit}><PasswordInput label="Mật khẩu mới" value={newPassword} onChange={setNewPassword} autoComplete="new-password" visible={showPasswords} /><PasswordInput label="Xác nhận mật khẩu mới" value={confirmPassword} onChange={setConfirmPassword} autoComplete="new-password" visible={showPasswords} /><label className="checkbox-label"><input type="checkbox" checked={showPasswords} onChange={event => setShowPasswords(event.target.checked)} /> Hiện mật khẩu</label>{error && <div className="error-alert">{error}</div>}<button className="btn-primary btn-block" disabled={busy}>{busy ? 'Đang đặt lại…' : 'Đặt lại mật khẩu'}</button></form><button type="button" className="btn-text-link" onClick={onBack}>← Quay lại đăng nhập</button></>}</div></main>
}

export function ChangePassword({ token, onSuccess }) {
  const [currentPassword, setCurrentPassword] = useState(''), [newPassword, setNewPassword] = useState(''), [confirmPassword, setConfirmPassword] = useState(''), [showPasswords, setShowPasswords] = useState(false), [busy, setBusy] = useState(false), [error, setError] = useState('')
  async function submit(event) {
    event.preventDefault()
    if (!passwordIsValid(newPassword)) return setError('Mật khẩu mới cần ít nhất 10 ký tự, gồm chữ và số.')
    if (newPassword !== confirmPassword) return setError('Xác nhận mật khẩu chưa khớp.')
    setBusy(true); setError('')
    try { await api('/auth/password', { method: 'PUT', body: JSON.stringify({ currentPassword, newPassword }) }, token); onSuccess() }
    catch (requestError) { setError(requestError.message || 'Không thể đổi mật khẩu. Vui lòng thử lại.') }
    finally { setBusy(false) }
  }
  return <form className="provider-store-settings" onSubmit={submit}><section className="store-settings-section"><h4>Đổi mật khẩu</h4><p className="settings-help">Sau khi đổi mật khẩu, bạn sẽ cần đăng nhập lại để bảo vệ tài khoản.</p><PasswordInput label="Mật khẩu hiện tại" value={currentPassword} onChange={setCurrentPassword} autoComplete="current-password" visible={showPasswords} /><PasswordInput label="Mật khẩu mới" value={newPassword} onChange={setNewPassword} autoComplete="new-password" visible={showPasswords} /><PasswordInput label="Xác nhận mật khẩu mới" value={confirmPassword} onChange={setConfirmPassword} autoComplete="new-password" visible={showPasswords} /><label className="checkbox-label"><input type="checkbox" checked={showPasswords} onChange={event => setShowPasswords(event.target.checked)} /> Hiện mật khẩu</label>{error && <div className="error-alert">{error}</div>}<button className="btn-primary" disabled={busy}>{busy ? 'Đang đổi…' : 'Đổi mật khẩu'}</button></section></form>
}
