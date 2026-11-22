import { useEffect, useState, useMemo } from 'react'
import { api, rowsOf } from '../../shared/api'
import { dateTime } from '../../shared/format'
import { Empty, ErrorState, Loading } from '../../shared/ui'
import { Icons } from '../../shared/icons'

export default function Notifications({ token, onBooking = () => {} }) {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')
  const [tab, setTab] = useState('all') // 'all', 'unread'

  const load = async (isManual = false) => {
    if (isManual) setRefreshing(true)
    else setLoading(true)
    try {
      setRows(rowsOf(await api('/notifications', {}, token)))
      setError('')
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  useEffect(() => {
    load()
  }, [token])

  async function read(id) {
    try {
      await api(`/notifications/${id}/read`, { method: 'PUT' }, token)
      load()
    } catch (e) {
      setError(e.message)
    }
  }

  async function readAll() {
    try {
      await api('/notifications/read-all', { method: 'PUT' }, token)
      setSuccessMsg('Đã đánh dấu tất cả thông báo là đã đọc!')
      setTimeout(() => setSuccessMsg(''), 3000)
      load()
    } catch (e) {
      setError(e.message)
    }
  }

  const unreadCount = useMemo(() => {
    return rows.filter(r => !r.is_read).length
  }, [rows])

  const filteredRows = useMemo(() => {
    if (tab === 'unread') return rows.filter(r => !r.is_read)
    return rows
  }, [rows, tab])

  const isBookingAction = n =>
    String(n.notification_type || '').includes('BOOKING') ||
    String(n.title || '').match(/tranh chấp|xác nhận|đặt lịch|hoàn tất|hủy/i)

  const getNotificationIcon = n => {
    const t = (n.title || '').toLowerCase()
    if (t.includes('ví') || t.includes('rút tiền') || t.includes('giải ngân')) {
      return <Icons.Wallet size={18} className="text-emerald" />
    }
    if (t.includes('escrow') || t.includes('bảo chứng')) {
      return <Icons.Shield size={18} className="text-teal" />
    }
    if (t.includes('đánh giá') || t.includes('review')) {
      return <Icons.Reviews size={18} className="text-amber" />
    }
    return <Icons.Bell size={18} className="text-primary" />
  }

  return (
    <div className="notifications-page-container">
      {/* Header */}
      <header className="page-header">
        <div className="page-header-left">
          <div className="page-title-row">
            <h1 className="page-title">Trung tâm thông báo</h1>
            {unreadCount > 0 ? (
              <span className="badge badge-warning">
                <span className="badge-dot" />
                {unreadCount} chưa đọc
              </span>
            ) : (
              <span className="badge badge-success">
                <span className="badge-dot" />
                Đã đọc tất cả
              </span>
            )}
          </div>
          <p className="page-subtitle">
            Cập nhật biến động lịch hẹn, trạng thái giải ngân Escrow và phản hồi từ khách hàng.
          </p>
        </div>
        <div className="page-header-actions">
          {unreadCount > 0 && (
            <button
              type="button"
              className="btn-secondary"
              onClick={readAll}
            >
              <Icons.Check size={16} />
              <span>Đọc tất cả</span>
            </button>
          )}
          <button
            type="button"
            className="btn-secondary"
            onClick={() => load(true)}
            disabled={refreshing || loading}
          >
            <Icons.Refresh size={16} className={refreshing ? 'animate-spin' : ''} />
            <span>Làm mới</span>
          </button>
        </div>
      </header>

      {error && <ErrorState error={error} retry={() => load()} />}
      {successMsg && (
        <div className="success-alert" style={{ marginBottom: '16px' }}>
          <Icons.CheckCircle size={18} />
          <span>{successMsg}</span>
        </div>
      )}

      {/* Filter Tabs */}
      <div className="filter-panel" style={{ marginBottom: '16px' }}>
        <div className="filter-pills">
          <button
            type="button"
            className={`filter-pill ${tab === 'all' ? 'active' : ''}`}
            onClick={() => setTab('all')}
          >
            Tất cả ({rows.length})
          </button>
          <button
            type="button"
            className={`filter-pill ${tab === 'unread' ? 'active' : ''}`}
            onClick={() => setTab('unread')}
          >
            Chưa đọc ({unreadCount})
          </button>
        </div>
      </div>

      {/* Notifications List */}
      <section className="panel">
        {loading ? (
          <Loading />
        ) : filteredRows.length > 0 ? (
          <div className="notification-items-list">
            {filteredRows.map(x => (
              <div
                key={x.id}
                className={`notification-row-item ${!x.is_read ? 'unread' : ''}`}
              >
                <div className="notification-icon-wrapper">
                  {getNotificationIcon(x)}
                </div>

                <div className="notification-content-box">
                  <div className="notification-title-line">
                    <strong className="notification-title-text">{x.title}</strong>
                    {!x.is_read && <span className="unread-dot" title="Chưa đọc" />}
                  </div>
                  <p className="notification-desc-text">{x.content}</p>
                  <span className="notification-time-text">
                    <Icons.Clock size={12} />
                    {dateTime(x.created_at)}
                  </span>
                </div>

                <div className="notification-actions-group">
                  {isBookingAction(x) && (
                    <button
                      type="button"
                      className="btn-secondary btn-sm"
                      onClick={onBooking}
                    >
                      <Icons.Bookings size={13} />
                      <span>Xem booking</span>
                    </button>
                  )}
                  {!x.is_read && (
                    <button
                      type="button"
                      className="btn-ghost btn-sm"
                      onClick={() => read(x.id)}
                      title="Đánh dấu đã đọc"
                    >
                      <Icons.Check size={14} />
                      <span>Đã đọc</span>
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <Empty
            icon={<Icons.Bell size={40} />}
            title={
              tab === 'unread'
                ? 'Tuyệt vời! Bạn không có thông báo chưa đọc nào.'
                : 'Chưa có thông báo nào'
            }
            note="Thông báo mới về booking, giải ngân và đánh giá sẽ hiển thị tại đây."
          />
        )}
      </section>
    </div>
  )
}
