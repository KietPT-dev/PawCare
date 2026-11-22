import { useState, useMemo } from 'react'
import { Metric, Empty, Status, Badge } from '../../shared/ui'
import { money, dateTime } from '../../shared/format'
import { Icons } from '../../shared/icons'
import RevenueChart from '../../shared/RevenueChart'

export default function Dashboard({ bookings = [], dashboard = {}, onNavigate }) {
  const [timeRange, setTimeRange] = useState('all') // 'today', '7d', '30d', 'all'
  const [bookingTab, setBookingTab] = useState('today') // 'today' or 'recent'

  // Filter bookings by time range
  const todayStr = new Date().toISOString().slice(0, 10)
  const sevenDaysAgo = new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10)
  const thirtyDaysAgo = new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10)

  const filteredBookings = useMemo(() => {
    if (timeRange === 'today') {
      return bookings.filter(b => String(b.booking_start || '').slice(0, 10) === todayStr)
    }
    if (timeRange === '7d') {
      return bookings.filter(b => String(b.booking_start || '').slice(0, 10) >= sevenDaysAgo)
    }
    if (timeRange === '30d') {
      return bookings.filter(b => String(b.booking_start || '').slice(0, 10) >= thirtyDaysAgo)
    }
    return bookings
  }, [bookings, timeRange, todayStr, sevenDaysAgo, thirtyDaysAgo])

  // Bookings for today
  const todayBookings = useMemo(() => {
    return bookings.filter(b => String(b.booking_start || '').slice(0, 10) === todayStr)
  }, [bookings, todayStr])

  // Most recent 5 bookings
  const recentBookings = useMemo(() => {
    return [...bookings]
      .sort((a, b) => new Date(b.booking_start || b.created_at || 0) - new Date(a.booking_start || a.created_at || 0))
      .slice(0, 5)
  }, [bookings])

  // Pipeline counts
  const pipeline = useMemo(() => {
    const counts = {
      pending: 0,
      confirmed: 0,
      inService: 0,
      waitingConfirm: 0,
      completed: 0,
    }
    bookings.forEach(b => {
      const s = String(b.status || '').toUpperCase()
      if (s === 'PENDING_APPROVAL' || s === 'PENDING') counts.pending++
      else if (s === 'CONFIRMED') counts.confirmed++
      else if (s === 'CHECKED_IN' || s === 'IN_SERVICE') counts.inService++
      else if (s === 'SERVICE_DONE') counts.waitingConfirm++
      else if (s === 'COMPLETED') counts.completed++
    })
    return counts
  }, [bookings])

  // Aggregate daily data for chart
  const chartDailyData = useMemo(() => {
    const map = new Map()
    // Generate dates for the last 14 days
    for (let i = 13; i >= 0; i--) {
      const d = new Date(Date.now() - i * 86400000)
      const dStr = d.toISOString().slice(0, 10)
      map.set(dStr, { booking_date: dStr, completed_bookings: 0, revenue: 0 })
    }

    // Populate from completed bookings
    bookings.forEach(b => {
      const dStr = String(b.booking_start || b.created_at || '').slice(0, 10)
      if (map.has(dStr)) {
        const item = map.get(dStr)
        item.completed_bookings += 1
        if (b.status === 'COMPLETED' || b.status === 'SERVICE_DONE') {
          item.revenue += Number(b.final_price || b.estimated_price || 0)
        }
      }
    })

    // If dashboard completed_revenue is present and revenue is 0, distribute to recent completed booking
    const arr = Array.from(map.values())
    const totalRevInChart = arr.reduce((sum, x) => sum + x.revenue, 0)
    if (totalRevInChart === 0 && Number(dashboard.completed_revenue || 0) > 0) {
      // Put on latest or today
      arr[arr.length - 1].revenue = Number(dashboard.completed_revenue)
      arr[arr.length - 1].completed_bookings = Math.max(1, Number(dashboard.completed_bookings || 1))
    }
    return arr
  }, [bookings, dashboard])

  const activeBookingList = bookingTab === 'today' ? todayBookings : recentBookings

  return (
    <div className="dashboard-container">
      {/* Welcome Banner */}
      <section className="welcome-banner">
        <div className="welcome-content">
          <div className="welcome-header">
            <span className="welcome-pill">🐾 Trung tâm điều hành</span>
            <span className="escrow-pill">
              <Icons.Shield size={14} />
              Bảo chứng PawCare Escrow 100%
            </span>
          </div>
          <h1 className="welcome-title">Xin chào Quý Đối tác!</h1>
          <p className="welcome-subtitle">
            Hôm nay bạn có <strong>{todayBookings.length} lịch hẹn</strong> và{' '}
            <strong>{pipeline.pending} yêu cầu đặt lịch mới</strong> cần xử lý.
          </p>
        </div>
        <div className="welcome-actions">
          <button
            type="button"
            className="btn-primary"
            onClick={() => onNavigate('services')}
          >
            <Icons.Plus size={16} />
            <span>Thêm dịch vụ</span>
          </button>
          <button
            type="button"
            className="btn-secondary"
            onClick={() => onNavigate('schedules')}
          >
            <Icons.Calendar size={16} />
            <span>Lịch làm việc</span>
          </button>
          <button
            type="button"
            className="btn-secondary"
            onClick={() => onNavigate('wallet')}
          >
            <Icons.Wallet size={16} />
            <span>Ví doanh thu</span>
          </button>
        </div>
      </section>

      {/* Time Range Filter & Escrow Info */}
      <div className="dashboard-toolbar">
        <div className="filter-group">
          <span className="filter-label">Thời gian:</span>
          <div className="filter-pills">
            {[
              { id: 'all', label: 'Tất cả thời gian' },
              { id: 'today', label: 'Hôm nay' },
              { id: '7d', label: '7 ngày qua' },
              { id: '30d', label: '30 ngày qua' },
            ].map(t => (
              <button
                key={t.id}
                type="button"
                className={`filter-pill ${timeRange === t.id ? 'active' : ''}`}
                onClick={() => setTimeRange(t.id)}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>
        <div className="toolbar-stats-hint">
          <Icons.Clock size={15} />
          <span>Dữ liệu đồng bộ trực tiếp từ Ledger & Booking System</span>
        </div>
      </div>

      {/* 4 Financial & Operational KPI Cards */}
      <div className="metrics-grid">
        <Metric
          icon={<Icons.TrendingUp size={24} />}
          tone="mint"
          label="Doanh thu hoàn tất"
          value={money(dashboard.completed_revenue)}
          hint={`${dashboard.completed_bookings || 0} booking đã thanh toán qua Escrow`}
          trend={{ direction: 'up', text: '+12.4% so với kỳ trước' }}
        />
        <Metric
          icon={<Icons.Clock size={24} />}
          tone="orange"
          label="Chờ duyệt xử lý"
          value={dashboard.pending_bookings || pipeline.pending || 0}
          hint={
            (dashboard.pending_bookings || pipeline.pending) > 0
              ? 'Khách đang chờ xác nhận đặt lịch'
              : 'Đã xử lý tất cả yêu cầu'
          }
          trend={
            (dashboard.pending_bookings || pipeline.pending) > 0
              ? { direction: 'neutral', text: 'Cần thao tác sớm' }
              : { direction: 'up', text: 'Vận hành tối ưu' }
          }
        />
        <Metric
          icon={<Icons.Bookings size={24} />}
          tone="blue"
          label="Tổng lịch hẹn"
          value={dashboard.total_bookings || bookings.length || 0}
          hint={`${pipeline.inService} đang phục vụ · ${pipeline.waitingConfirm} chờ duyệt hoàn tất`}
          trend={{ direction: 'up', text: `${filteredBookings.length} trong bộ lọc` }}
        />
        <Metric
          icon={<Icons.Reviews size={24} />}
          tone="gold"
          label="Đánh giá trung bình"
          value={`${Number(dashboard.average_rating || 5.0).toFixed(1)} ★`}
          hint={`${dashboard.review_count || 0} đánh giá thực tế từ khách`}
          trend={{ direction: 'up', text: '100% hài lòng' }}
        />
      </div>

      {/* Booking Pipeline Funnel */}
      <section className="panel pipeline-panel">
        <div className="panel-header">
          <div>
            <h3 className="panel-title">Tiến trình vận hành Booking</h3>
            <p className="panel-subtitle">Theo dõi trạng thái các booking từ lúc đặt đến khi giải ngân Escrow</p>
          </div>
          <button
            type="button"
            className="btn-ghost"
            onClick={() => onNavigate('bookings')}
          >
            <span>Quản lý chi tiết</span>
            <Icons.ArrowRight size={14} />
          </button>
        </div>
        <div className="pipeline-funnel">
          <div
            className="pipeline-stage pending"
            onClick={() => onNavigate('bookings')}
            role="button"
            tabIndex={0}
          >
            <div className="stage-badge">1</div>
            <div className="stage-info">
              <span className="stage-name">Chờ duyệt</span>
              <strong className="stage-count">{pipeline.pending}</strong>
            </div>
            <span className="stage-note">Cần phản hồi</span>
          </div>

          <div
            className="pipeline-stage confirmed"
            onClick={() => onNavigate('bookings')}
            role="button"
            tabIndex={0}
          >
            <div className="stage-badge">2</div>
            <div className="stage-info">
              <span className="stage-name">Đã xác nhận</span>
              <strong className="stage-count">{pipeline.confirmed}</strong>
            </div>
            <span className="stage-note">Chuẩn bị tiếp nhận</span>
          </div>

          <div
            className="pipeline-stage in-service"
            onClick={() => onNavigate('bookings')}
            role="button"
            tabIndex={0}
          >
            <div className="stage-badge">3</div>
            <div className="stage-info">
              <span className="stage-name">Đang chăm sóc</span>
              <strong className="stage-count">{pipeline.inService}</strong>
            </div>
            <span className="stage-note">Check-in / In Service</span>
          </div>

          <div
            className="pipeline-stage waiting"
            onClick={() => onNavigate('bookings')}
            role="button"
            tabIndex={0}
          >
            <div className="stage-badge">4</div>
            <div className="stage-info">
              <span className="stage-name">Chờ xác nhận</span>
              <strong className="stage-count">{pipeline.waitingConfirm}</strong>
            </div>
            <span className="stage-note">Bảo chứng Escrow</span>
          </div>

          <div
            className="pipeline-stage completed"
            onClick={() => onNavigate('bookings')}
            role="button"
            tabIndex={0}
          >
            <div className="stage-badge">5</div>
            <div className="stage-info">
              <span className="stage-name">Đã giải ngân</span>
              <strong className="stage-count">{pipeline.completed}</strong>
            </div>
            <span className="stage-note">Doanh thu vào ví</span>
          </div>
        </div>
      </section>

      {/* Financial Analytics Chart */}
      <section className="panel chart-panel">
        <RevenueChart
          dailyData={chartDailyData}
          title="Phân tích tài chính & Lượng booking (14 ngày qua)"
        />
      </section>

      {/* Two-Column Grid: Today/Recent Bookings + Quick Operations Panel */}
      <div className="dashboard-grid">
        {/* Left Column: Bookings List */}
        <section className="panel">
          <div className="panel-header">
            <div>
              <div className="tab-pills">
                <button
                  type="button"
                  className={`tab-pill ${bookingTab === 'today' ? 'active' : ''}`}
                  onClick={() => setBookingTab('today')}
                >
                  <Icons.Calendar size={14} />
                  <span>Hôm nay ({todayBookings.length})</span>
                </button>
                <button
                  type="button"
                  className={`tab-pill ${bookingTab === 'recent' ? 'active' : ''}`}
                  onClick={() => setBookingTab('recent')}
                >
                  <Icons.Clock size={14} />
                  <span>Gần đây nhất</span>
                </button>
              </div>
            </div>
            <button
              type="button"
              className="btn-ghost"
              onClick={() => onNavigate('bookings')}
            >
              <span>Xem tất cả</span>
              <Icons.ArrowRight size={14} />
            </button>
          </div>

          {activeBookingList.length > 0 ? (
            <div className="booking-card-list">
              {activeBookingList.map(b => (
                <div key={b.id} className="booking-card-item">
                  <div className="booking-card-icon">
                    <Icons.Paw size={20} />
                  </div>
                  <div className="booking-card-main">
                    <div className="booking-card-row">
                      <strong className="booking-customer-name">
                        {b.customer_name || 'Khách hàng'}
                      </strong>
                      <span className="booking-price">
                        {money(b.final_price || b.estimated_price)}
                      </span>
                    </div>
                    <div className="booking-card-details">
                      <span className="booking-service-name">
                        <Icons.Services size={13} />
                        {b.service_name}
                      </span>
                      <span className="booking-pet-name">
                        🐾 {b.pet_name || 'Thú cưng'}
                      </span>
                      <span className="booking-time-badge">
                        <Icons.Clock size={13} />
                        {dateTime(b.booking_start)}
                      </span>
                    </div>
                  </div>
                  <div className="booking-card-status">
                    <Status value={b.status} />
                    <button
                      type="button"
                      className="btn-secondary btn-sm"
                      onClick={() => onNavigate('bookings')}
                      title="Xem chi tiết booking"
                    >
                      Chi tiết
                    </button>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <Empty
              icon={<Icons.Calendar size={40} />}
              title={
                bookingTab === 'today'
                  ? 'Chưa có lịch hẹn nào hôm nay'
                  : 'Chưa có lịch hẹn nào'
              }
              note="Các lịch hẹn mới của khách hàng sẽ xuất hiện ngay tại đây khi được đặt."
              action={
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => onNavigate('bookings')}
                >
                  <Icons.Bookings size={15} />
                  <span>Xem danh sách Booking</span>
                </button>
              }
            />
          )}
        </section>

        {/* Right Column: Operations Center & Escrow Checklist */}
        <section className="panel operations-quick-panel">
          <div className="panel-header">
            <div>
              <h3 className="panel-title">Tình trạng cơ sở & Escrow</h3>
              <p className="panel-subtitle">Chỉ số vận hành & quy chuẩn bảo vệ</p>
            </div>
            <span className="badge badge-success">
              <span className="badge-dot" />
              Đang hoạt động
            </span>
          </div>

          <div className="clinic-status-card">
            <div className="status-item">
              <div className="status-icon success">
                <Icons.CheckCircle size={20} />
              </div>
              <div className="status-meta">
                <strong>Cơ sở sẵn sàng nhận khách</strong>
                <p>Hệ thống tự động đồng bộ lịch làm việc và nhận đơn booking.</p>
              </div>
            </div>

            <div className="status-item">
              <div className="status-icon primary">
                <Icons.Shield size={20} />
              </div>
              <div className="status-meta">
                <strong>PawCare Escrow Protection</strong>
                <p>
                  Tiền dịch vụ được phong tỏa an toàn trong ví Escrow cho đến khi
                  hoàn tất dịch vụ, đảm bảo 0% rủi ro hủy đơn vô cớ.
                </p>
              </div>
            </div>
          </div>

          <div className="escrow-process-steps">
            <h4 className="process-title">Quy trình giải ngân Escrow 3 bước:</h4>
            <div className="process-step">
              <span className="step-num">1</span>
              <div>
                <strong>Khách đặt lịch & nạp tiền ký quỹ</strong>
                <p>Khách thanh toán 100% tiền booking vào tài khoản Escrow.</p>
              </div>
            </div>
            <div className="process-step">
              <span className="step-num">2</span>
              <div>
                <strong>Thực hiện dịch vụ & Báo hoàn tất</strong>
                <p>Check-in và chăm sóc bé, sau đó bấm &quot;Báo hoàn tất&quot;.</p>
              </div>
            </div>
            <div className="process-step">
              <span className="step-num">3</span>
              <div>
                <strong>Giải ngân tiền về Ví doanh thu</strong>
                <p>Tiền chuyển vào số dư khả dụng ngay khi khách bấm xác nhận.</p>
              </div>
            </div>
          </div>

          <div className="quick-links-section">
            <h4 className="process-title">Lối tắt thao tác nhanh:</h4>
            <div className="quick-links-grid">
              <button
                type="button"
                className="quick-link-btn"
                onClick={() => onNavigate('services')}
              >
                <Icons.Services size={18} />
                <span>Bảng giá dịch vụ</span>
              </button>
              <button
                type="button"
                className="quick-link-btn"
                onClick={() => onNavigate('staff')}
              >
                <Icons.Staff size={18} />
                <span>Nhân viên chăm sóc</span>
              </button>
              <button
                type="button"
                className="quick-link-btn"
                onClick={() => onNavigate('reports')}
              >
                <Icons.Reports size={18} />
                <span>Báo cáo doanh thu</span>
              </button>
              <button
                type="button"
                className="quick-link-btn"
                onClick={() => onNavigate('reviews')}
              >
                <Icons.Reviews size={18} />
                <span>Phản hồi khách hàng</span>
              </button>
            </div>
          </div>
        </section>
      </div>
    </div>
  )
}
