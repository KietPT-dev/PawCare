import { useEffect, useState } from 'react'
import { api } from '../../shared/api'
import { Icons } from '../../shared/icons'
import { extractVerificationToken } from './VerifyEmail'

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/
const PHONE_RE = /^\+?\d{9,13}$/

export const passwordIsValid = value =>
  typeof value === 'string' &&
  value.length >= 10 &&
  /[A-Za-z]/.test(value) &&
  /\d/.test(value)

export function validateRegisterForm(form) {
  const errors = {}
  const fullName = String(form.fullName || '').trim()
  const providerName = String(form.providerName || '').trim()
  const providerType = String(form.providerType || 'SHOP').toUpperCase()
  const email = String(form.email || '').trim().toLowerCase()
  const phone = String(form.phone || '').replace(/[\s.-]/g, '').trim()
  const address = String(form.address || '').trim()
  const password = String(form.password || '')
  const confirmPassword = String(form.confirmPassword || '')

  if (!fullName) {
    errors.fullName = 'Vui lòng nhập họ và tên người đại diện.'
  } else if (fullName.length < 2) {
    errors.fullName = 'Họ và tên cần ít nhất 2 ký tự.'
  }

  if (providerType === 'SHOP' && !providerName) {
    errors.providerName = 'Vui lòng nhập tên cơ sở / Spa / phòng khám.'
  }

  if (!email) {
    errors.email = 'Vui lòng nhập email đăng nhập.'
  } else if (!EMAIL_RE.test(email)) {
    errors.email = 'Địa chỉ email chưa đúng định dạng.'
  }

  if (phone && !PHONE_RE.test(phone)) {
    errors.phone = 'Số điện thoại cần 9–13 chữ số hợp lệ.'
  }

  if (!password) {
    errors.password = 'Vui lòng tạo mật khẩu.'
  } else if (!passwordIsValid(password)) {
    errors.password = 'Mật khẩu cần ít nhất 10 ký tự, bao gồm chữ cái và số.'
  }

  if (!confirmPassword) {
    errors.confirmPassword = 'Vui lòng nhập lại mật khẩu để xác nhận.'
  } else if (password !== confirmPassword) {
    errors.confirmPassword = 'Xác nhận mật khẩu chưa khớp.'
  }

  return {
    valid: Object.keys(errors).length === 0,
    errors,
    payload: {
      fullName,
      email,
      password,
      phone: phone || undefined,
      address: address || undefined,
      role: 'PROVIDER',
      providerName: providerName || fullName,
      providerType: providerType === 'INDIVIDUAL' ? 'INDIVIDUAL' : 'SHOP',
    },
  }
}

function mapRegisterApiError(err) {
  const msg = String((err && err.message) || '')
  if (err?.status === 409 || /already registered/i.test(msg)) {
    return 'Email này đã được đăng ký tài khoản trên PawCare. Vui lòng đăng nhập hoặc dùng email khác.'
  }
  return msg || 'Không thể đăng ký tài khoản lúc này. Vui lòng thử lại.'
}

export default function Register({ onBack, onComplete }) {
  const [form, setForm] = useState({
    providerType: 'SHOP',
    fullName: '',
    providerName: '',
    email: '',
    phone: '',
    address: '',
    password: '',
    confirmPassword: '',
  })
  const [fieldErrors, setFieldErrors] = useState({})
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)
  const [busy, setBusy] = useState(false)
  const [serverError, setServerError] = useState('')

  // Step 2 state: post-registration email verification using real Core endpoints
  const [step, setStep] = useState('form') // 'form' | 'verify'
  const [registeredSession, setRegisteredSession] = useState(null)
  const [verifyBusy, setVerifyBusy] = useState(false)
  const [confirmBusy, setConfirmBusy] = useState(false)
  const [cooldown, setCooldown] = useState(0)
  const [verifyStatus, setVerifyStatus] = useState('') // 'sent' | 'send-failed' | 'verified'
  const [verifyNotice, setVerifyNotice] = useState('')
  const [verifyError, setVerifyError] = useState('')
  const [tokenInput, setTokenInput] = useState('')

  useEffect(() => {
    if (!cooldown) return undefined
    const timer = window.setInterval(() => {
      setCooldown(prev => Math.max(0, prev - 1))
    }, 1000)
    return () => window.clearInterval(timer)
  }, [cooldown])

  function updateField(key, value) {
    setForm(prev => ({ ...prev, [key]: value }))
    if (fieldErrors[key]) {
      setFieldErrors(prev => {
        const next = { ...prev }
        delete next[key]
        return next
      })
    }
    if (serverError) setServerError('')
  }

  async function triggerEmailVerification(accessToken) {
    setVerifyBusy(true)
    setVerifyError('')
    try {
      await api('/auth/email-verification/request', { method: 'POST' }, accessToken)
      setCooldown(60)
      setVerifyStatus('sent')
      setVerifyNotice('PawCare đã gửi hướng dẫn xác minh email tới hộp thư của bạn. Vui lòng kiểm tra và hoàn tất xác nhận.')
    } catch (err) {
      setVerifyStatus('send-failed')
      setVerifyError(err.message || 'Tài khoản đã được tạo nhưng chưa thể gửi email xác minh lúc này. Bạn có thể bấm gửi lại.')
    } finally {
      setVerifyBusy(false)
    }
  }

  async function handleSubmit(e) {
    e.preventDefault()
    const check = validateRegisterForm(form)
    if (!check.valid) {
      setFieldErrors(check.errors)
      return
    }
    setBusy(true)
    setServerError('')
    try {
      const session = await api('/auth/register', {
        method: 'POST',
        body: JSON.stringify(check.payload),
      })
      setRegisteredSession(session)
      setStep('verify')
      await triggerEmailVerification(session.accessToken)
    } catch (err) {
      setServerError(mapRegisterApiError(err))
    } finally {
      setBusy(false)
    }
  }

  async function handleConfirmToken(e) {
    e.preventDefault()
    const cleanToken = extractVerificationToken(tokenInput)
    if (!cleanToken) {
      setVerifyError('Vui lòng nhập mã xác minh hoặc liên kết từ email.')
      return
    }
    setConfirmBusy(true)
    setVerifyError('')
    try {
      await api('/auth/email-verification/confirm', {
        method: 'POST',
        body: JSON.stringify({ token: cleanToken }),
      })
      let nextSession = registeredSession
      if (registeredSession?.accessToken) {
        try {
          const freshProfile = await api('/auth/me', {}, registeredSession.accessToken)
          nextSession = { ...registeredSession, profile: freshProfile }
          setRegisteredSession(nextSession)
        } catch {
          nextSession = {
            ...registeredSession,
            profile: { ...(registeredSession.profile || {}), emailVerified: 1 },
          }
          setRegisteredSession(nextSession)
        }
      }
      setVerifyStatus('verified')
      setVerifyNotice('Email đã được xác minh thành công! Tài khoản Đối tác đang ở trạng thái chờ Admin phê duyệt hồ sơ cơ sở.')
    } catch (err) {
      setVerifyError(err.message || 'Mã hoặc liên kết xác minh không hợp lệ hoặc đã hết hạn.')
    } finally {
      setConfirmBusy(false)
    }
  }

  return (
    <main className="auth-page">
      <div className="auth-card-container auth-card-wide">
        <div className="auth-card-header">
          <div className="auth-logo-circle">
            <Icons.Paw size={32} />
          </div>
          <span className="auth-kicker-pill">
            <Icons.Shield size={13} />
            PawCare Partner Portal
          </span>
          <h1 className="auth-title">
            {step === 'form' ? 'Đăng ký Đối tác' : 'Xác minh email Đối tác'}
          </h1>
          <p className="auth-subtitle">
            {step === 'form'
              ? 'Tạo tài khoản cơ sở chăm sóc thú cưng để quản lý dịch vụ, lịch hẹn và ví doanh thu'
              : `Hoàn tất xác nhận địa chỉ email ${registeredSession?.profile?.email || form.email}`}
          </p>
        </div>

        {/* 2-step progress strip */}
        <div className="auth-steps" aria-label="Tiến trình đăng ký">
          <div className={`auth-step ${step === 'form' ? 'is-active' : 'is-done'}`}>
            <span className="auth-step-num">{step === 'form' ? '1' : '✓'}</span>
            <span>Thông tin Đối tác</span>
          </div>
          <span className="auth-step-sep" />
          <div className={`auth-step ${step === 'verify' ? (verifyStatus === 'verified' ? 'is-done' : 'is-active') : ''}`}>
            <span className="auth-step-num">{verifyStatus === 'verified' ? '✓' : '2'}</span>
            <span>Xác minh email</span>
          </div>
        </div>

        {step === 'form' ? (
          <form className="auth-form" onSubmit={handleSubmit} noValidate>
            {serverError && (
              <div className="error-alert" role="alert">
                <Icons.AlertCircle size={18} />
                <span>{serverError}</span>
              </div>
            )}

            {/* Provider Type Segmented Toggle */}
            <div className="form-group" style={{ marginBottom: '2px' }}>
              <span className="form-label">Loại hình Đối tác</span>
              <div className="auth-type-toggle" role="radiogroup" aria-label="Loại hình Đối tác">
                <button
                  type="button"
                  role="radio"
                  aria-checked={form.providerType === 'SHOP'}
                  className={`auth-type-option ${form.providerType === 'SHOP' ? 'is-selected' : ''}`}
                  onClick={() => updateField('providerType', 'SHOP')}
                >
                  <Icons.Building size={16} />
                  <div>
                    <strong>Cơ sở / Spa / Phòng khám</strong>
                    <span>Đơn vị có địa điểm kinh doanh</span>
                  </div>
                </button>
                <button
                  type="button"
                  role="radio"
                  aria-checked={form.providerType === 'INDIVIDUAL'}
                  className={`auth-type-option ${form.providerType === 'INDIVIDUAL' ? 'is-selected' : ''}`}
                  onClick={() => updateField('providerType', 'INDIVIDUAL')}
                >
                  <Icons.User size={16} />
                  <div>
                    <strong>Cá nhân cung cấp dịch vụ</strong>
                    <span>Groomer / Chăm sóc tự do</span>
                  </div>
                </button>
              </div>
            </div>

            <div className="form-grid">
              <div className="form-group">
                <label className="form-label" htmlFor="reg-fullname">
                  Họ và tên người đại diện <span className="req-mark">*</span>
                </label>
                <div className="auth-input-wrapper">
                  <span className="input-icon">
                    <Icons.User size={16} />
                  </span>
                  <input
                    id="reg-fullname"
                    autoFocus
                    type="text"
                    className={`form-input with-icon ${fieldErrors.fullName ? 'has-error' : ''}`}
                    value={form.fullName}
                    onChange={e => updateField('fullName', e.target.value)}
                    placeholder="Nhập họ và tên"
                    autoComplete="name"
                    required
                  />
                </div>
                {fieldErrors.fullName && <span className="field-error">{fieldErrors.fullName}</span>}
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="reg-provider-name">
                  {form.providerType === 'SHOP' ? 'Tên cơ sở hiển thị' : 'Tên thương hiệu (tùy chọn)'}
                  {form.providerType === 'SHOP' && <span className="req-mark"> *</span>}
                </label>
                <div className="auth-input-wrapper">
                  <span className="input-icon">
                    <Icons.Building size={16} />
                  </span>
                  <input
                    id="reg-provider-name"
                    type="text"
                    className={`form-input with-icon ${fieldErrors.providerName ? 'has-error' : ''}`}
                    value={form.providerName}
                    onChange={e => updateField('providerName', e.target.value)}
                    placeholder={form.providerType === 'SHOP' ? 'Ví dụ: Happy Paws Spa' : 'Để trống sẽ lấy họ tên'}
                  />
                </div>
                {fieldErrors.providerName && <span className="field-error">{fieldErrors.providerName}</span>}
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="reg-email">
                  Email tài khoản Đối tác <span className="req-mark">*</span>
                </label>
                <div className="auth-input-wrapper">
                  <span className="input-icon">
                    <Icons.Mail size={16} />
                  </span>
                  <input
                    id="reg-email"
                    type="email"
                    className={`form-input with-icon ${fieldErrors.email ? 'has-error' : ''}`}
                    value={form.email}
                    onChange={e => updateField('email', e.target.value)}
                    placeholder="Nhập email công việc"
                    autoComplete="email"
                    required
                  />
                </div>
                {fieldErrors.email && <span className="field-error">{fieldErrors.email}</span>}
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="reg-phone">Số điện thoại liên hệ</label>
                <div className="auth-input-wrapper">
                  <span className="input-icon">
                    <Icons.Phone size={16} />
                  </span>
                  <input
                    id="reg-phone"
                    type="tel"
                    className={`form-input with-icon ${fieldErrors.phone ? 'has-error' : ''}`}
                    value={form.phone}
                    onChange={e => updateField('phone', e.target.value)}
                    placeholder="0901234567"
                    autoComplete="tel"
                  />
                </div>
                {fieldErrors.phone && <span className="field-error">{fieldErrors.phone}</span>}
              </div>

              <div className="form-group form-full">
                <label className="form-label" htmlFor="reg-address">Địa chỉ cơ sở</label>
                <div className="auth-input-wrapper">
                  <span className="input-icon">
                    <Icons.MapPin size={16} />
                  </span>
                  <input
                    id="reg-address"
                    type="text"
                    className="form-input with-icon"
                    value={form.address}
                    onChange={e => updateField('address', e.target.value)}
                    placeholder="Số nhà, đường, quận/huyện, tỉnh/thành"
                    autoComplete="street-address"
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="reg-password">
                  Mật khẩu <span className="req-mark">*</span>
                </label>
                <div className="auth-input-wrapper">
                  <span className="input-icon">
                    <Icons.Shield size={16} />
                  </span>
                  <input
                    id="reg-password"
                    type={showPassword ? 'text' : 'password'}
                    className={`form-input with-icon with-action ${fieldErrors.password ? 'has-error' : ''}`}
                    value={form.password}
                    onChange={e => updateField('password', e.target.value)}
                    placeholder="Tạo mật khẩu"
                    autoComplete="new-password"
                    required
                  />
                  <button
                    type="button"
                    className="input-action-btn"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? 'Ẩn' : 'Hiện'}
                  </button>
                </div>
                <span className={fieldErrors.password ? 'field-error' : 'auth-hint'}>
                  {fieldErrors.password || 'Ít nhất 10 ký tự, gồm chữ cái và số.'}
                </span>
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="reg-confirm-password">
                  Xác nhận mật khẩu <span className="req-mark">*</span>
                </label>
                <div className="auth-input-wrapper">
                  <span className="input-icon">
                    <Icons.Shield size={16} />
                  </span>
                  <input
                    id="reg-confirm-password"
                    type={showConfirm ? 'text' : 'password'}
                    className={`form-input with-icon with-action ${fieldErrors.confirmPassword ? 'has-error' : ''}`}
                    value={form.confirmPassword}
                    onChange={e => updateField('confirmPassword', e.target.value)}
                    placeholder="Nhập lại mật khẩu"
                    autoComplete="new-password"
                    required
                  />
                  <button
                    type="button"
                    className="input-action-btn"
                    onClick={() => setShowConfirm(!showConfirm)}
                  >
                    {showConfirm ? 'Ẩn' : 'Hiện'}
                  </button>
                </div>
                {fieldErrors.confirmPassword && (
                  <span className="field-error">{fieldErrors.confirmPassword}</span>
                )}
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
                  <span>Đang tạo tài khoản…</span>
                </>
              ) : (
                <>
                  <span>Đăng ký tài khoản</span>
                  <Icons.ArrowRight size={16} />
                </>
              )}
            </button>

            <div className="auth-switch-row">
              <span className="auth-switch-text">Đã có tài khoản Đối tác?</span>
              <button
                type="button"
                className="auth-register-trigger"
                onClick={onBack}
                disabled={busy}
              >
                Quay lại đăng nhập
              </button>
            </div>
          </form>
        ) : (
          <div className="auth-form">
            {verifyStatus !== 'send-failed' && verifyNotice && (
              <div className="success-banner auth-banner-block" role="status">
                <div className="auth-banner-title">
                  <Icons.CheckCircle size={18} />
                  <span>
                    {verifyStatus === 'verified'
                      ? 'Email đã được xác minh'
                      : 'Tài khoản Đối tác đã được tạo'}
                  </span>
                </div>
                <p>{verifyNotice}</p>
              </div>
            )}

            {verifyError && (
              <div className="error-alert" role="alert">
                <Icons.AlertCircle size={18} />
                <span>{verifyError}</span>
              </div>
            )}

            {verifyStatus !== 'verified' && (
              <>
                <form className="auth-form" onSubmit={handleConfirmToken}>
                  <div className="form-group">
                    <label className="form-label" htmlFor="reg-verify-token">
                      Nhập mã token hoặc liên kết xác minh từ email
                    </label>
                    <div className="auth-input-wrapper">
                      <span className="input-icon">
                        <Icons.Mail size={16} />
                      </span>
                      <input
                        id="reg-verify-token"
                        autoFocus
                        type="text"
                        className="form-input with-icon"
                        value={tokenInput}
                        onChange={e => setTokenInput(e.target.value)}
                        placeholder="Dán liên kết pawcare://... hoặc mã token"
                      />
                    </div>
                    <span className="auth-hint">
                      Mở liên kết xác minh trong email hoặc dán mã token tại đây để kích hoạt trạng thái đã xác minh.
                    </span>
                  </div>

                  <button
                    type="submit"
                    className="btn-primary btn-block auth-btn-submit"
                    disabled={confirmBusy}
                  >
                    {confirmBusy ? (
                      <>
                        <Icons.Refresh size={16} className="animate-spin" />
                        <span>Đang xác nhận email…</span>
                      </>
                    ) : (
                      <>
                        <span>Xác nhận email</span>
                        <Icons.CheckCircle size={16} />
                      </>
                    )}
                  </button>
                </form>

                <div className="auth-actions-stack">
                  <button
                    type="button"
                    className="btn-secondary btn-block"
                    disabled={verifyBusy || cooldown > 0}
                    onClick={() => triggerEmailVerification(registeredSession?.accessToken)}
                  >
                    {verifyBusy
                      ? 'Đang gửi email xác minh…'
                      : cooldown > 0
                        ? `Gửi lại email xác minh sau ${cooldown}s`
                        : 'Gửi lại email xác minh'}
                  </button>
                </div>
              </>
            )}

            <div className="auth-actions-stack">
              <button
                type="button"
                className={verifyStatus === 'verified' ? 'btn-primary btn-block auth-btn-submit' : 'btn-secondary btn-block'}
                onClick={() => {
                  if (onComplete && registeredSession) onComplete(registeredSession)
                  else if (onBack) onBack()
                }}
              >
                {verifyStatus === 'verified' ? 'Vào Provider Portal' : 'Vào Portal (xác minh sau)'}
              </button>

              <button
                type="button"
                className="btn-text-link"
                style={{ alignSelf: 'center', marginTop: '4px' }}
                onClick={onBack}
              >
                <Icons.ArrowLeft size={14} /> Quay lại trang đăng nhập
              </button>
            </div>
          </div>
        )}

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
