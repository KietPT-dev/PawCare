import React, { useEffect, useRef } from 'react'
import { statusLabel } from './format'
import { Icons } from './icons'

export function Status({ value }) {
  const statusStr = typeof value === 'object' && value !== null ? (value.status || value.value || '') : String(value || '')
  const v = statusStr.toUpperCase()
  let tone = 'neutral'
  let dotColor = '#64748B'

  if (['CONFIRMED', 'COMPLETED', 'APPROVED', 'AVAILABLE'].includes(v)) {
    tone = 'success'
    dotColor = '#10B981'
  } else if (['PENDING_APPROVAL', 'PENDING', 'SERVICE_DONE', 'BOOKED'].includes(v)) {
    tone = 'warning'
    dotColor = '#F59E0B'
  } else if (['CHECKED_IN', 'IN_SERVICE', 'IN_PROGRESS'].includes(v)) {
    tone = 'info'
    dotColor = '#0EA5E9'
  } else if (['REJECTED', 'CANCELLED', 'BLOCKED'].includes(v)) {
    tone = 'danger'
    dotColor = '#EF4444'
  } else if (['DISPUTED'].includes(v)) {
    tone = 'critical'
    dotColor = '#DC2626'
  }

  return (
    <span className={`status-badge status-${tone}`} title={statusStr}>
      <span className="status-dot" style={{ backgroundColor: dotColor }} />
      <span className="status-text">{statusLabel(statusStr)}</span>
    </span>
  )
}

export function Empty({ title = 'Không có dữ liệu', note = 'Dữ liệu sẽ xuất hiện ở đây khi có hoạt động mới.', icon, action }) {
  return (
    <div className="empty-state">
      <div className="empty-state-icon">
        {icon || <Icons.Paw size={28} className="text-teal" />}
      </div>
      <h4 className="empty-state-title">
        {typeof title === 'object' && title !== null ? JSON.stringify(title) : title}
      </h4>
      <p className="empty-state-note">
        {typeof note === 'object' && note !== null ? JSON.stringify(note) : note}
      </p>
      {action && <div className="empty-state-action">{action}</div>}
    </div>
  )
}

export function Loading({ message = 'Đang tải dữ liệu...' }) {
  return (
    <div className="loading-state">
      <div className="loading-spinner" />
      <p className="loading-text">
        {typeof message === 'object' && message !== null ? (message.message || JSON.stringify(message)) : message}
      </p>
    </div>
  )
}

export function ErrorState({ error, retry }) {
  const errorMsg =
    typeof error === 'object' && error !== null
      ? error.message || JSON.stringify(error)
      : String(error || 'Đã có lỗi xảy ra')

  return (
    <div className="error-alert">
      <div className="error-alert-icon">
        <Icons.AlertCircle size={20} />
      </div>
      <div className="error-alert-content">
        <strong>Đã xảy ra lỗi:</strong> {errorMsg}
      </div>
      {retry && (
        <button type="button" className="error-alert-retry" onClick={retry}>
          <Icons.Refresh size={14} /> Thử lại
        </button>
      )}
    </div>
  )
}

export function Metric({ icon, tone = 'blue', label, value, hint, trend, trendType = 'neutral' }) {
  // Support both string trend (e.g. "+12%") and object trend (e.g. { direction: 'up', text: '+12%' })
  const trendObj = typeof trend === 'object' && trend !== null ? trend : null
  const trendText = trendObj ? trendObj.text : (typeof trend === 'string' || typeof trend === 'number' ? trend : null)
  const trendDir = trendObj ? (trendObj.direction || trendType) : trendType

  return (
    <section className={`kpi-card tone-${tone}`}>
      <div className="kpi-header">
        <span className="kpi-label">{label}</span>
        <div className={`kpi-icon-wrap kpi-tone-${tone}`}>
          {typeof icon === 'string' ? <span className="kpi-text-icon">{icon}</span> : icon}
        </div>
      </div>
      <div className="kpi-body">
        <strong className="kpi-value">
          {typeof value === 'object' && value !== null ? JSON.stringify(value) : value}
        </strong>
        <div className="kpi-footer">
          {trendText && (
            <span className={`kpi-trend kpi-trend-${trendDir}`}>
              {trendDir === 'up' && '↑ '}
              {trendDir === 'down' && '↓ '}
              {trendText}
            </span>
          )}
          {hint && <span className="kpi-hint">{hint}</span>}
        </div>
      </div>
    </section>
  )
}

export function Modal({ isOpen = true, onClose, title, subtitle, children, maxWidth = 520 }) {
  const modalRef = useRef(null)

  useEffect(() => {
    function handleKeyDown(e) {
      if (e.key === 'Escape' && onClose) onClose()
    }
    if (isOpen) {
      window.addEventListener('keydown', handleKeyDown)
      document.body.style.overflow = 'hidden'
    }
    return () => {
      window.removeEventListener('keydown', handleKeyDown)
      document.body.style.overflow = ''
    }
  }, [isOpen, onClose])

  if (!isOpen) return null

  return (
    <div className="modal-overlay" onClick={e => { if (e.target === e.currentTarget && onClose) onClose() }}>
      <div className="modal-container" style={{ maxWidth: `${maxWidth}px` }} ref={modalRef}>
        <div className="modal-header">
          <div>
            <h3 className="modal-title">{title}</h3>
            {subtitle && <p className="modal-subtitle">{subtitle}</p>}
          </div>
          {onClose && (
            <button type="button" className="modal-close-btn" aria-label="Đóng" onClick={onClose}>
              <Icons.Close size={18} />
            </button>
          )}
        </div>
        <div className="modal-body">
          {children}
        </div>
      </div>
    </div>
  )
}

export function Badge({ children, variant = 'neutral', icon, dot = false }) {
  return (
    <span className={`badge badge-${variant}`}>
      {dot && <span className="badge-dot" />}
      {icon && <span className="badge-icon">{icon}</span>}
      {children}
    </span>
  )
}
