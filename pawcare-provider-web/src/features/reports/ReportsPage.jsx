import { useEffect, useState, useMemo } from 'react'
import { api } from '../../shared/api'
import { money } from '../../shared/format'
import { Empty, ErrorState, Loading, Metric, Status, Badge } from '../../shared/ui'
import { Icons } from '../../shared/icons'
import RevenueChart from '../../shared/RevenueChart'

export default function ReportsPage({ token }) {
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [data, setData] = useState(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [activePreset, setActivePreset] = useState('all')

  const load = async (isManual = false) => {
    if (from && to && from > to) {
      setError('Ngày bắt đầu phải trước ngày kết thúc.')
      return
    }
    if (isManual) setRefreshing(true)
    else setLoading(true)

    try {
      const q = new URLSearchParams()
      if (from) q.set('from', from)
      if (to) q.set('to', to)
      const res = await api(`/provider/reports${q.size ? '?' + q : ''}`, {}, token)
      setData(res)
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

  // Quick preset handlers
  const applyPreset = preset => {
    setActivePreset(preset)
    const today = new Date()
    const todayStr = today.toISOString().slice(0, 10)

    if (preset === 'today') {
      setFrom(todayStr)
      setTo(todayStr)
    } else if (preset === '7d') {
      const past = new Date(Date.now() - 7 * 86400000)
      setFrom(past.toISOString().slice(0, 10))
      setTo(todayStr)
    } else if (preset === 'thisMonth') {
      const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
      setFrom(startOfMonth.toISOString().slice(0, 10))
      setTo(todayStr)
    } else if (preset === 'all') {
      setFrom('')
      setTo('')
    }
  }

  const s = data?.summary || {}
  const dailyRows = useMemo(() => {
    return data?.daily || []
  }, [data])

  return (
    <div className="reports-page-container">
      {/* Header */}
      <header className="page-header">
        <div className="page-header-left">
          <div className="page-title-row">
            <h1 className="page-title">Báo cáo tài chính & Đối soát</h1>
            <span className="badge badge-primary">
              <Icons.Shield size={12} />
              Đối soát Escrow
            </span>
          </div>
          <p className="page-subtitle">
            Theo dõi dòng tiền, thống kê doanh thu theo thời gian thực và kiểm tra trạng thái giải ngân.
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

      {/* Date Filter Panel */}
      <section className="panel filter-panel">
        <div className="filter-panel-inner">
          <div className="preset-buttons">
            {[
              { id: 'all', label: 'Tất cả' },
              { id: 'today', label: 'Hôm nay' },
              { id: '7d', label: '7 ngày qua' },
              { id: 'thisMonth', label: 'Tháng này' },
            ].map(p => (
              <button
                key={p.id}
                type="button"
                className={`filter-pill ${activePreset === p.id ? 'active' : ''}`}
                onClick={() => applyPreset(p.id)}
              >
                {p.label}
              </button>
            ))}
          </div>

          <div className="custom-date-inputs">
            <div className="date-input-group">
              <span className="date-label">Từ ngày:</span>
              <input
                type="date"
                className="form-input date-input"
                value={from}
                onChange={e => {
                  setFrom(e.target.value)
                  setActivePreset('custom')
                }}
              />
            </div>
            <div className="date-input-group">
              <span className="date-label">Đến ngày:</span>
              <input
                type="date"
                className="form-input date-input"
                value={to}
                onChange={e => {
                  setTo(e.target.value)
                  setActivePreset('custom')
                }}
              />
            </div>
            <button
              type="button"
              className="btn-primary"
              onClick={() => load()}
            >
              <Icons.Search size={15} />
              <span>Tra cứu</span>
            </button>
          </div>
        </div>
      </section>

      {error && <ErrorState error={error} retry={() => load()} />}

      {loading ? (
        <Loading />
      ) : (
        <>
          {/* Summary Metric Cards */}
          <div className="metrics-grid">
            <Metric
              icon={<Icons.TrendingUp size={24} />}
              tone="mint"
              label="Đã giải ngân về ví"
              value={money(s.settled_revenue)}
              hint={`${s.completed_bookings || 0} booking hoàn tất`}
              trend={{ direction: 'up', text: 'Doanh thu thực nhận' }}
            />
            <Metric
              icon={<Icons.Clock size={24} />}
              tone="orange"
              label="Escrow chờ xác nhận"
              value={money(s.waiting_customer_confirmation)}
              hint="Dịch vụ đã hoàn tất, chờ khách duyệt"
              trend={{ direction: 'neutral', text: 'Đang bảo chứng' }}
            />
            <Metric
              icon={<Icons.Bookings size={24} />}
              tone="blue"
              label="Booking hoàn tất"
              value={s.completed_bookings || 0}
              hint="Số lượt chăm sóc thành công"
              trend={{ direction: 'up', text: '100% tỷ lệ hoàn tất' }}
            />
            <Metric
              icon={<Icons.Wallet size={24} />}
              tone="gold"
              label="Đã rút về tài khoản"
              value={money(data?.withdrawnAmount)}
              hint="Tổng số tiền đã rút thành công"
              trend={{ direction: 'up', text: 'Đã quyết toán' }}
            />
          </div>

          {/* Interactive Chart */}
          <section className="panel chart-panel">
            <RevenueChart
              dailyData={dailyRows}
              title="Biểu đồ phân tích doanh thu theo ngày"
            />
          </section>

          {/* Daily Breakdown Table */}
          <section className="panel">
            <div className="panel-header">
              <div>
                <h3 className="panel-title">Bảng đối soát chi tiết theo ngày</h3>
                <p className="panel-subtitle">
                  Thống kê số lượng booking và doanh thu thực tế được giải ngân theo từng ngày
                </p>
              </div>
              <span className="badge badge-neutral">
                {dailyRows.length} ngày ghi nhận
              </span>
            </div>

            {dailyRows.length > 0 ? (
              <div className="table-responsive">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Ngày đối soát</th>
                      <th style={{ textAlign: 'center' }}>Số booking hoàn tất</th>
                      <th style={{ textAlign: 'right' }}>Tổng doanh thu</th>
                      <th style={{ textAlign: 'right' }}>Trung bình / đơn</th>
                      <th style={{ textAlign: 'center' }}>Trạng thái Escrow</th>
                    </tr>
                  </thead>
                  <tbody>
                    {dailyRows.map(row => {
                      const count = Number(row.completed_bookings || 0)
                      const rev = Number(row.revenue || 0)
                      const avg = count > 0 ? rev / count : 0
                      return (
                        <tr key={row.booking_date}>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                              <Icons.Calendar size={15} className="text-secondary" />
                              <strong style={{ color: 'var(--navy-900)' }}>
                                {row.booking_date}
                              </strong>
                            </div>
                          </td>
                          <td style={{ textAlign: 'center' }}>
                            <span className="badge badge-primary">
                              {count} booking
                            </span>
                          </td>
                          <td style={{ textAlign: 'right' }}>
                            <strong className="text-emerald" style={{ fontSize: '15px' }}>
                              {money(rev)}
                            </strong>
                          </td>
                          <td style={{ textAlign: 'right', color: 'var(--slate-600)' }}>
                            {money(avg)}
                          </td>
                          <td style={{ textAlign: 'center' }}>
                            <span className="badge badge-success">
                              <span className="badge-dot" />
                              Đã giải ngân
                            </span>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            ) : (
              <Empty
                icon={<Icons.Reports size={40} />}
                title="Chưa có dữ liệu doanh thu"
                note="Chưa có booking nào được giải ngân trong khoảng thời gian đã chọn. Hãy thử nới rộng khoảng thời gian tìm kiếm."
              />
            )}
          </section>
        </>
      )}
    </div>
  )
}
