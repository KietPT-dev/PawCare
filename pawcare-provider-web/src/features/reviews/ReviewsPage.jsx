import { useEffect, useState, useMemo } from 'react'
import { api, rowsOf } from '../../shared/api'
import { dateTime } from '../../shared/format'
import { Empty, ErrorState, Loading, Modal } from '../../shared/ui'
import { Icons } from '../../shared/icons'

export default function ReviewsPage({ token }) {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')
  const [replying, setReplying] = useState(null)
  const [content, setContent] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [ratingFilter, setRatingFilter] = useState('all')

  const load = async (isManual = false) => {
    if (isManual) setRefreshing(true)
    else setLoading(true)
    try {
      setRows(rowsOf(await api('/provider/reviews', {}, token)))
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

  // Aggregate review stats
  const stats = useMemo(() => {
    if (!rows.length) return { avg: 5.0, count: 0, fiveStarPercent: 100 }
    const total = rows.reduce((sum, r) => sum + Number(r.rating || 5), 0)
    const avg = total / rows.length
    const fiveStarCount = rows.filter(r => Number(r.rating || 5) >= 5).length
    return {
      avg: avg.toFixed(1),
      count: rows.length,
      fiveStarPercent: Math.round((fiveStarCount / rows.length) * 100),
    }
  }, [rows])

  const filteredRows = useMemo(() => {
    if (ratingFilter === 'all') return rows
    if (ratingFilter === 'replied') return rows.filter(r => !!r.provider_reply)
    if (ratingFilter === 'unreplied') return rows.filter(r => !r.provider_reply)
    return rows.filter(r => Number(r.rating) === Number(ratingFilter))
  }, [rows, ratingFilter])

  async function reply(e) {
    e.preventDefault()
    if (!content.trim()) return

    setSubmitting(true)
    try {
      await api(
        `/provider/reviews/${replying.id}/reply`,
        { method: 'POST', body: JSON.stringify({ content }) },
        token
      )
      setSuccessMsg('Đã gửi phản hồi đánh giá cho khách hàng thành công!')
      setReplying(null)
      setContent('')
      setTimeout(() => setSuccessMsg(''), 4000)
      load()
    } catch (e) {
      setError(e.message)
    } finally {
      setSubmitting(false)
    }
  }

  const renderStars = rating => {
    const r = Math.round(Number(rating || 5))
    return (
      <div className="star-rating-row" style={{ display: 'inline-flex', gap: '3px' }}>
        {[1, 2, 3, 4, 5].map(star => (
          <span
            key={star}
            style={{
              color: star <= r ? 'var(--amber-500)' : 'var(--slate-200)',
              fontSize: '16px',
            }}
          >
            ★
          </span>
        ))}
      </div>
    )
  }

  return (
    <div className="reviews-page-container">
      {/* Header */}
      <header className="page-header">
        <div className="page-header-left">
          <div className="page-title-row">
            <h1 className="page-title">Đánh giá & Uy tín dịch vụ</h1>
            <span className="badge badge-success">
              <span className="badge-dot" />
              Đã xác thực booking
            </span>
          </div>
          <p className="page-subtitle">
            Phản hồi thực tế từ khách hàng sau khi hoàn tất dịch vụ chăm sóc thú cưng.
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

      {/* Overview Rating Stats Card */}
      <div className="review-stats-card">
        <div className="stats-score-block">
          <div className="score-big">{stats.avg}</div>
          <div className="score-stars">{renderStars(stats.avg)}</div>
          <span className="score-hint">
            Dựa trên {stats.count} lượt đánh giá thực tế
          </span>
        </div>

        <div className="stats-divider" />

        <div className="stats-highlights">
          <div className="highlight-item">
            <strong className="text-emerald">{stats.fiveStarPercent}%</strong>
            <span>Tỷ lệ đánh giá 5 sao</span>
          </div>
          <div className="highlight-item">
            <strong className="text-primary">100%</strong>
            <span>Khách hàng thực tế qua Escrow</span>
          </div>
          <div className="highlight-item">
            <strong className="text-amber">24h</strong>
            <span>Thời gian phản hồi trung bình</span>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="review-filter-toolbar">
        <div className="filter-pills">
          {[
            { id: 'all', label: `Tất cả (${rows.length})` },
            { id: '5', label: '5 sao ★' },
            { id: '4', label: '4 sao ★' },
            { id: 'unreplied', label: 'Chưa phản hồi' },
            { id: 'replied', label: 'Đã phản hồi' },
          ].map(f => (
            <button
              key={f.id}
              type="button"
              className={`filter-pill ${ratingFilter === f.id ? 'active' : ''}`}
              onClick={() => setRatingFilter(f.id)}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      {/* Reviews List */}
      {loading ? (
        <Loading />
      ) : filteredRows.length > 0 ? (
        <div className="review-cards-list">
          {filteredRows.map(x => (
            <div key={x.id} className="review-item-card">
              <div className="review-card-top">
                <div className="review-author-info">
                  <div className="review-avatar">
                    {(x.customer_name || 'K').slice(0, 1).toUpperCase()}
                  </div>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <strong className="customer-name-text">
                        {x.customer_name || 'Khách hàng'}
                      </strong>
                      <span className="badge badge-neutral">
                        #{x.booking_id}
                      </span>
                    </div>
                    <span className="text-secondary text-sm">
                      {dateTime(x.created_at)}
                    </span>
                  </div>
                </div>

                <div className="review-stars-box">
                  {renderStars(x.rating)}
                  <span className="service-tag-chip">
                    🐾 {x.service_name || 'Dịch vụ spa/khám'}
                  </span>
                </div>
              </div>

              <div className="review-comment-body">
                <p className="comment-text">
                  &ldquo;{x.comment || 'Khách hàng không để lại nhận xét bằng chữ.'}&rdquo;
                </p>
              </div>

              {/* Provider Reply Thread */}
              {x.provider_reply && (
                <div className="provider-reply-box">
                  <div className="reply-header">
                    <Icons.Paw size={14} className="text-teal" />
                    <strong>Phản hồi từ Quý Đối tác:</strong>
                  </div>
                  <p className="reply-content">{x.provider_reply}</p>
                </div>
              )}

              <div className="review-card-actions">
                <button
                  type="button"
                  className="btn-secondary btn-sm"
                  onClick={() => {
                    setReplying(x)
                    setContent(x.provider_reply || '')
                  }}
                >
                  <Icons.Edit size={14} />
                  <span>{x.provider_reply ? 'Sửa phản hồi' : 'Gửi phản hồi'}</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <Empty
          icon={<Icons.Reviews size={40} />}
          title="Chưa có đánh giá phù hợp"
          note="Đánh giá từ khách hàng sau khi hoàn tất dịch vụ sẽ xuất hiện tại đây."
        />
      )}

      {/* Reply Modal */}
      {replying && (
        <Modal
          title={`Phản hồi đánh giá của ${replying.customer_name || 'khách hàng'}`}
          subtitle={`Dịch vụ: ${replying.service_name} · Đánh giá: ${replying.rating || 5} sao`}
          onClose={() => setReplying(null)}
          maxWidth="540px"
        >
          <form onSubmit={reply} className="modal-form">
            <div className="modal-callout note-callout" style={{ marginBottom: '16px' }}>
              <strong>Đánh giá của khách:</strong>
              <p style={{ marginTop: '4px', fontStyle: 'italic' }}>
                &ldquo;{replying.comment || 'Không có bình luận chữ.'}&rdquo;
              </p>
            </div>

            <div className="form-group">
              <label className="form-label">
                Nội dung phản hồi từ cơ sở chăm sóc
              </label>
              <textarea
                className="form-textarea"
                rows="4"
                placeholder="Cảm ơn bạn đã tin tưởng dịch vụ chăm sóc thú cưng của chúng tôi..."
                value={content}
                onChange={e => setContent(e.target.value)}
                required
                minLength={2}
              />
            </div>

            <div className="modal-actions-footer">
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setReplying(null)}
                disabled={submitting}
              >
                Hủy bỏ
              </button>
              <button
                type="submit"
                className="btn-primary"
                disabled={submitting}
              >
                <Icons.Check size={16} />
                <span>{submitting ? 'Đang gửi…' : 'Gửi phản hồi'}</span>
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}
