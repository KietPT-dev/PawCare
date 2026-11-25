import { useEffect, useState, useMemo } from 'react'
import { api, rowsOf } from '../../shared/api'
import { money, dateTime } from '../../shared/format'
import { Empty, ErrorState, Loading, Status, Badge, Modal } from '../../shared/ui'
import { Icons } from '../../shared/icons'
import { providerActions } from './actions'

const STATUS_GROUPS = [
  { id: '', label: 'Tất cả' },
  { id: 'PENDING_APPROVAL', label: 'Cần duyệt' },
  { id: 'CONFIRMED', label: 'Đã xác nhận' },
  { id: 'IN_SERVICE', label: 'Đang chăm sóc' },
  { id: 'SERVICE_DONE', label: 'Chờ khách duyệt' },
  { id: 'COMPLETED', label: 'Đã hoàn tất' },
  { id: 'CANCELLED', label: 'Đã hủy' },
]

export default function BookingsPage({ token, onMutated, onOpenMessages }) {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')

  const [query, setQuery] = useState('')
  const [status, setStatus] = useState('')
  const [date, setDate] = useState('')
  const [detail, setDetail] = useState(null)
  const [note, setNote] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const load = async (isManual = false) => {
    if (isManual) setRefreshing(true)
    else setLoading(true)
    try {
      setRows(rowsOf(await api('/bookings', {}, token)))
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

  const visible = useMemo(() => {
    return rows.filter(x => {
      const matchStatus =
        !status ||
        x.status === status ||
        (status === 'IN_SERVICE' && (x.status === 'IN_SERVICE' || x.status === 'CHECKED_IN'))
      const matchDate =
        !date || String(x.booking_start || '').slice(0, 10) === date
      const matchQuery =
        !query ||
        Object.values(x).join(' ').toLowerCase().includes(query.toLowerCase())
      return matchStatus && matchDate && matchQuery
    })
  }, [rows, status, date, query])

  const open = x => {
    setDetail(x)
    setNote(x.provider_note || '')
  }

  async function transition(next) {
    const isReject = next === 'REJECTED'
    const isDone = next === 'SERVICE_DONE'

    if (
      isReject &&
      !window.confirm(
        'Từ chối booking này? Số tiền bảo chứng trong Escrow sẽ được hoàn trả 100% về ví của khách hàng.'
      )
    ) {
      return
    }

    if (
      isDone &&
      !window.confirm(
        'Báo đã hoàn tất dịch vụ? Khách hàng sẽ nhận thông báo để xác nhận hài lòng trước khi tiền Escrow được giải ngân vào ví đối tác.'
      )
    ) {
      return
    }

    setSubmitting(true)
    try {
      await api(
        `/bookings/${detail.id}/status`,
        {
          method: 'PUT',
          body: JSON.stringify({
            status: next,
            providerNote: note,
            note,
            cancelReason: isReject ? note : null,
          }),
        },
        token
      )
      setSuccessMsg(`Cập nhật trạng thái Booking #${detail.id} thành công!`)
      setDetail(null)
      setTimeout(() => setSuccessMsg(''), 5000)
      await load()
      if (onMutated) onMutated()
    } catch (e) {
      setError(e.message)
    } finally {
      setSubmitting(false)
    }
  }

  async function openConversation() {
    try {
      await api(`/bookings/${detail.id}/conversation`, { method: 'POST' }, token)
      onOpenMessages?.()
    } catch (e) { setError(e.message) }
  }

  return (
    <div className="bookings-page-container">
      {/* Header */}
      <header className="page-header">
        <div className="page-header-left">
          <div className="page-title-row">
            <h1 className="page-title">Quản lý Lịch hẹn & Booking</h1>
            <span className="badge badge-primary">
              <Icons.Shield size={12} />
              Bảo chứng Escrow
            </span>
          </div>
          <p className="page-subtitle">
            Theo dõi tiến trình phục vụ khách hàng. Provider báo hoàn tất dịch vụ, tiền sẽ được giải ngân sau khi khách xác nhận.
          </p>
        </div>
        <div className="page-header-actions">
          <button
            type="button"
            className="btn-secondary"
            onClick={() => load(true)}
            disabled={refreshing || loading}
          >
            <Icons.Refresh size={16} className={refreshing ? 'animate-spin' : ''} />
            <span>{refreshing ? 'Đang cập nhật…' : 'Làm mới'}</span>
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

      {/* Filter Toolbar */}
      <section className="panel filter-panel">
        <div className="bookings-filter-bar">
          {/* Search Box */}
          <div className="search-input-wrapper">
            <Icons.Search size={16} />
            <input
              type="text"
              className="search-input"
              placeholder="Tìm theo mã đơn, khách hàng, tên pet, dịch vụ…"
              value={query}
              onChange={e => setQuery(e.target.value)}
            />
            {query && (
              <button
                type="button"
                className="search-clear-btn"
                onClick={() => setQuery('')}
              >
                <Icons.Close size={14} />
              </button>
            )}
          </div>

          {/* Date Picker */}
          <div className="date-input-wrapper">
            <Icons.Calendar size={15} />
            <input
              type="date"
              className="form-input date-input"
              value={date}
              onChange={e => setDate(e.target.value)}
            />
            {date && (
              <button
                type="button"
                className="search-clear-btn"
                onClick={() => setDate('')}
                title="Xóa lọc ngày"
              >
                <Icons.Close size={13} />
              </button>
            )}
          </div>

          {/* Status Tabs */}
          <div className="status-tabs">
            {STATUS_GROUPS.map(g => (
              <button
                key={g.id}
                type="button"
                className={`filter-pill ${status === g.id ? 'active' : ''}`}
                onClick={() => setStatus(g.id)}
              >
                {g.label}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* Table Section */}
      <section className="panel">
        <div className="panel-header">
          <div>
            <h3 className="panel-title">Danh sách lịch hẹn</h3>
            <p className="panel-subtitle">Hiển thị {visible.length} / {rows.length} booking</p>
          </div>
        </div>

        {loading ? (
          <Loading />
        ) : visible.length > 0 ? (
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Mã & Khách hàng</th>
                  <th>Thú cưng</th>
                  <th>Dịch vụ</th>
                  <th>Lịch hẹn</th>
                  <th style={{ textAlign: 'right' }}>Giá dịch vụ</th>
                  <th style={{ textAlign: 'center' }}>Trạng thái</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {visible.map(b => (
                  <tr key={b.id}>
                    <td>
                      <div className="booking-customer-cell">
                        <div className="customer-avatar-box">
                          {(b.customer_name || 'K').slice(0, 1).toUpperCase()}
                        </div>
                        <div>
                          <strong className="customer-name-text">
                            {b.customer_name || 'Khách hàng'}
                          </strong>
                          <span className="booking-code-chip">
                            #{b.id}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="pet-info-cell">
                        <span className="pet-icon">🐾</span>
                        <strong className="pet-name-text">
                          {b.pet_name || 'Thú cưng'}
                        </strong>
                      </div>
                    </td>
                    <td>
                      <div className="service-info-cell">
                        <strong className="service-name-text">{b.service_name}</strong>
                        {b.staff_name && (
                          <span className="staff-assigned-tag">
                            <Icons.Staff size={12} />
                            {b.staff_name}
                          </span>
                        )}
                      </div>
                    </td>
                    <td>
                      <div className="booking-time-cell">
                        <Icons.Clock size={14} className="text-secondary" />
                        <span>{dateTime(b.booking_start)}</span>
                      </div>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <strong className="booking-price-text">
                        {money(b.final_price || b.estimated_price)}
                      </strong>
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <Status value={b.status} />
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div className="table-actions-group">
                        <button
                          type="button"
                          className="btn-secondary btn-sm"
                          onClick={() => open(b)}
                        >
                          Chi tiết
                        </button>
                        {providerActions[b.status]?.map(([next, label]) => (
                          <button
                            key={next}
                            type="button"
                            className={`btn-sm ${
                              next === 'REJECTED'
                                ? 'btn-danger'
                                : 'btn-primary'
                            }`}
                            onClick={() => open(b)}
                          >
                            {label}
                          </button>
                        ))}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <Empty
            icon={<Icons.Bookings size={40} />}
            title="Không tìm thấy lịch hẹn phù hợp"
            note="Hãy thử xóa bộ lọc tìm kiếm hoặc kiểm tra lại ngày được chọn."
            action={
              (query || status || date) && (
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => {
                    setQuery('')
                    setStatus('')
                    setDate('')
                  }}
                >
                  <Icons.Refresh size={14} />
                  <span>Xóa bộ lọc</span>
                </button>
              )
            }
          />
        )}
      </section>

      {/* Booking Detail Modal */}
      {detail && (
        <Modal
          title={`Chi tiết Booking #${detail.id}`}
          subtitle={`Tạo lúc ${dateTime(detail.created_at || detail.booking_start)}`}
          onClose={() => setDetail(null)}
          maxWidth="640px"
        >
          <div className="booking-detail-modal-content">
            {/* Escrow Status Ribbon */}
            <div className="booking-modal-status-banner">
              <div className="status-banner-left">
                <span className="status-label-prefix">Trạng thái hiện tại:</span>
                <Status value={detail.status} />
              </div>
              <span className="badge badge-primary">
                <Icons.Shield size={13} />
                Tiền giữ an toàn trong Escrow
              </span>
            </div>

            {/* Lifecycle Timeline */}
            <div className="lifecycle-timeline">
              <div
                className={`timeline-node ${
                  ['PENDING_APPROVAL', 'CONFIRMED', 'CHECKED_IN', 'IN_SERVICE', 'SERVICE_DONE', 'COMPLETED'].includes(
                    detail.status
                  )
                    ? 'active'
                    : ''
                }`}
              >
                <div className="node-dot" />
                <span className="node-text">Đặt lịch</span>
              </div>
              <div className="timeline-connector" />
              <div
                className={`timeline-node ${
                  ['CONFIRMED', 'CHECKED_IN', 'IN_SERVICE', 'SERVICE_DONE', 'COMPLETED'].includes(
                    detail.status
                  )
                    ? 'active'
                    : ''
                }`}
              >
                <div className="node-dot" />
                <span className="node-text">Xác nhận</span>
              </div>
              <div className="timeline-connector" />
              <div
                className={`timeline-node ${
                  ['CHECKED_IN', 'IN_SERVICE', 'SERVICE_DONE', 'COMPLETED'].includes(
                    detail.status
                  )
                    ? 'active'
                    : ''
                }`}
              >
                <div className="node-dot" />
                <span className="node-text">Chăm sóc</span>
              </div>
              <div className="timeline-connector" />
              <div
                className={`timeline-node ${
                  ['SERVICE_DONE', 'COMPLETED'].includes(detail.status)
                    ? 'active'
                    : ''
                }`}
              >
                <div className="node-dot" />
                <span className="node-text">Chờ xác nhận</span>
              </div>
              <div className="timeline-connector" />
              <div
                className={`timeline-node ${
                  detail.status === 'COMPLETED' ? 'active' : ''
                }`}
              >
                <div className="node-dot" />
                <span className="node-text">Giải ngân</span>
              </div>
            </div>

            {/* Details Grid */}
            <div className="booking-modal-grid">
              <div className="detail-item">
                <span className="detail-label">Khách hàng</span>
                <strong className="detail-value">
                  {detail.customer_name || 'Khách hàng'}
                </strong>
              </div>
              <div className="detail-item">
                <span className="detail-label">Thú cưng</span>
                <strong className="detail-value">
                  🐾 {detail.pet_name || 'Thú cưng'}
                </strong>
              </div>
              <div className="detail-item">
                <span className="detail-label">Dịch vụ thực hiện</span>
                <strong className="detail-value">{detail.service_name}</strong>
              </div>
              <div className="detail-item">
                <span className="detail-label">Nhân viên phụ trách</span>
                <strong className="detail-value">
                  {detail.staff_name || 'Chưa phân công'}
                </strong>
              </div>
              <div className="detail-item">
                <span className="detail-label">Thời gian bắt đầu</span>
                <strong className="detail-value">
                  {dateTime(detail.booking_start)}
                </strong>
              </div>
              <div className="detail-item">
                <span className="detail-label">Chi phí dự kiến</span>
                <strong className="detail-value text-emerald">
                  {money(detail.estimated_price)}
                </strong>
              </div>
            </div>

            {/* Customer Note */}
            <div className="modal-callout note-callout">
              <div className="callout-header">
                <Icons.AlertCircle size={15} />
                <strong>Ghi chú từ khách hàng:</strong>
              </div>
              <p className="callout-text">
                {detail.customer_note || 'Không có ghi chú thêm từ khách hàng.'}
              </p>
            </div>

            {/* Escrow Notice */}
            {detail.status === 'SERVICE_DONE' && (
              <div className="modal-callout escrow-callout">
                <div className="callout-header">
                  <Icons.Shield size={16} />
                  <strong>Trạng thái bảo chứng Escrow:</strong>
                </div>
                <p className="callout-text">
                  Dịch vụ đã được bạn báo hoàn tất. Tiền đang được giữ an toàn tại tài khoản Escrow.
                  Khách hàng sẽ kiểm tra và xác nhận để giải ngân về ví doanh thu của bạn.
                </p>
              </div>
            )}

            {/* Provider Note Input */}
            <div className="form-group" style={{ marginTop: '16px' }}>
              <label className="form-label">
                Ghi chú nội bộ của Provider / Lý do cập nhật
              </label>
              <textarea
                className="form-textarea"
                rows="3"
                placeholder="Nhập ghi chú hoặc dặn dò cho khách hàng/nhân viên..."
                value={note}
                onChange={e => setNote(e.target.value)}
              />
            </div>

            {/* Modal Actions */}
            <div className="modal-actions-footer">
              <button type="button" className="btn-secondary" onClick={openConversation} disabled={submitting}>
                Nhắn tin với khách
              </button>
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setDetail(null)}
                disabled={submitting}
              >
                Đóng
              </button>
              {providerActions[detail.status]?.map(([next, label]) => (
                <button
                  key={next}
                  type="button"
                  className={`btn-primary ${
                    next === 'REJECTED' ? 'btn-danger' : ''
                  }`}
                  onClick={() => transition(next)}
                  disabled={submitting}
                >
                  {submitting ? 'Đang xử lý…' : label}
                </button>
              ))}
            </div>
          </div>
        </Modal>
      )}
    </div>
  )
}
