import React, { useState } from 'react'
import { money } from './format'

export function RevenueChart({
  data = [],
  dailyData,
  title = 'Biến động doanh thu',
  subtitle = 'Doanh thu & khối lượng đơn theo thời gian',
}) {
  const [metric, setMetric] = useState('revenue') // 'revenue' | 'bookings'
  const [hoveredIndex, setHoveredIndex] = useState(null)

  const chartData = (dailyData && dailyData.length ? dailyData : data) || []

  if (!chartData || chartData.length === 0) {
    return (
      <div className="chart-card">
        <div className="chart-header">
          <div>
            <h3 className="chart-title">{title}</h3>
            <p className="chart-subtitle">{subtitle}</p>
          </div>
        </div>
        <div className="chart-empty">
          <div className="chart-empty-icon">📊</div>
          <p className="chart-empty-text">Chưa có đủ dữ liệu để vẽ biểu đồ cho khoảng thời gian này</p>
        </div>
      </div>
    )
  }

  const values = chartData.map(d =>
    metric === 'revenue'
      ? Number(d.revenue || d.amount || d.value || 0)
      : Number(d.completed_bookings || d.bookings || d.count || 0)
  )
  const maxValue = Math.max(...values, 1)

  // Chart dimensions
  const width = 640
  const height = 220
  const padLeft = 60
  const padRight = 20
  const padTop = 20
  const padBottom = 35

  const chartW = width - padLeft - padRight
  const chartH = height - padTop - padBottom

  // Coordinates
  const points = values.map((val, i) => {
    const x = padLeft + (chartData.length > 1 ? (i / (chartData.length - 1)) * chartW : chartW / 2)
    const y = padTop + chartH - (val / maxValue) * chartH
    return { x, y, val, item: chartData[i] }
  })

  // SVG Area path & Line path
  const linePath = points.length > 1
    ? points.reduce((acc, p, i) => `${acc} ${i === 0 ? 'M' : 'L'} ${p.x.toFixed(1)},${p.y.toFixed(1)}`, '')
    : `M ${padLeft},${points[0]?.y || 0} L ${padLeft + chartW},${points[0]?.y || 0}`

  const areaPath = points.length > 1
    ? `${linePath} L ${points[points.length - 1].x.toFixed(1)},${padTop + chartH} L ${points[0].x.toFixed(1)},${padTop + chartH} Z`
    : ''

  const totalRevenue = chartData.reduce((sum, d) => sum + (Number(d.revenue || d.amount || d.value) || 0), 0)
  const totalBookings = chartData.reduce(
    (sum, d) => sum + (Number(d.completed_bookings || d.bookings || d.count) || 0),
    0
  )

  // Y-axis ticks
  const yTicks = [0, 0.25, 0.5, 0.75, 1].map(r => ({
    ratio: r,
    y: padTop + chartH - r * chartH,
    label:
      metric === 'revenue'
        ? r * maxValue >= 1000000
          ? `${(r * maxValue / 1000000).toFixed(1)}M`
          : r * maxValue >= 1000
          ? `${Math.round(r * maxValue / 1000)}k`
          : `${Math.round(r * maxValue)}`
        : `${Math.round(r * maxValue)}`,
  }))

  const activePoint = hoveredIndex !== null ? points[hoveredIndex] : points[points.length - 1]

  return (
    <div className="chart-card">
      <div className="chart-header">
        <div>
          <h3 className="chart-title">{title}</h3>
          <p className="chart-subtitle">{subtitle}</p>
        </div>

        {/* Metric Selector Tabs */}
        <div className="chart-toggle-group">
          <button
            type="button"
            className={`chart-toggle-btn ${metric === 'revenue' ? 'active' : ''}`}
            onClick={() => setMetric('revenue')}
          >
            Doanh thu ({money(totalRevenue)})
          </button>
          <button
            type="button"
            className={`chart-toggle-btn ${metric === 'bookings' ? 'active' : ''}`}
            onClick={() => setMetric('bookings')}
          >
            Số booking ({totalBookings})
          </button>
        </div>
      </div>

      {/* KPI Preview Strip */}
      <div className="chart-summary-strip">
        <div className="chart-stat">
          <span className="stat-label">
            {activePoint ? (activePoint.item?.booking_date || activePoint.item?.date || 'Gần đây nhất') : 'Tổng cộng'}
          </span>
          <span className="stat-val">
            {metric === 'revenue'
              ? money(activePoint?.val || 0)
              : `${activePoint?.val || 0} booking`}
          </span>
        </div>
        <div className="chart-stat">
          <span className="stat-label">Trung bình mỗi ngày</span>
          <span className="stat-val">
            {metric === 'revenue'
              ? money(chartData.length ? totalRevenue / chartData.length : 0)
              : `${(chartData.length ? totalBookings / chartData.length : 0).toFixed(1)} đơn/ngày`}
          </span>
        </div>
        <div className="chart-stat">
          <span className="stat-label">Trạng thái bảo chứng</span>
          <span className="stat-val text-teal">PawCare Escrow Active</span>
        </div>
      </div>

      {/* SVG Canvas */}
      <div className="chart-svg-container">
        <svg
          viewBox={`0 0 ${width} ${height}`}
          className="chart-svg"
          preserveAspectRatio="none"
        >
          <defs>
            <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#0d9488" stopOpacity="0.32" />
              <stop offset="100%" stopColor="#0d9488" stopOpacity="0.0" />
            </linearGradient>
            <linearGradient id="bookingsGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#06b6d4" stopOpacity="0.32" />
              <stop offset="100%" stopColor="#06b6d4" stopOpacity="0.0" />
            </linearGradient>
          </defs>

          {/* Grid lines */}
          {yTicks.map((t, idx) => (
            <g key={idx}>
              <line
                x1={padLeft}
                y1={t.y}
                x2={width - padRight}
                y2={t.y}
                stroke="#E2E8F0"
                strokeWidth="1"
                strokeDasharray="3 3"
              />
              <text
                x={padLeft - 8}
                y={t.y + 4}
                textAnchor="end"
                className="chart-axis-label"
              >
                {t.label}
              </text>
            </g>
          ))}

          {/* Area under curve */}
          {areaPath && (
            <path
              d={areaPath}
              fill={metric === 'revenue' ? 'url(#revenueGrad)' : 'url(#bookingsGrad)'}
            />
          )}

          {/* Main Trend Line */}
          <path
            d={linePath}
            fill="none"
            stroke={metric === 'revenue' ? '#0d9488' : '#06b6d4'}
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Data Points */}
          {points.map((p, i) => (
            <g
              key={i}
              onMouseEnter={() => setHoveredIndex(i)}
              onMouseLeave={() => setHoveredIndex(null)}
              style={{ cursor: 'pointer' }}
            >
              {/* Invisible larger hover target */}
              <circle cx={p.x} cy={p.y} r={12} fill="transparent" />

              <circle
                cx={p.x}
                cy={p.y}
                r={hoveredIndex === i ? 6 : 4}
                fill="#ffffff"
                stroke={metric === 'revenue' ? '#0d9488' : '#06b6d4'}
                strokeWidth={hoveredIndex === i ? 3 : 2}
                className="chart-point"
              />

              {/* X Axis Label */}
              {(chartData.length <= 8 || i % Math.ceil(chartData.length / 6) === 0 || i === chartData.length - 1) && (
                <text
                  x={p.x}
                  y={height - 8}
                  textAnchor="middle"
                  className="chart-axis-label"
                >
                  {p.item?.booking_date
                    ? String(p.item.booking_date).slice(5)
                    : p.item?.date
                    ? String(p.item.date).slice(5)
                    : p.item?.label || `#${i + 1}`}
                </text>
              )}
            </g>
          ))}

          {/* Vertical guideline on hover */}
          {activePoint && hoveredIndex !== null && (
            <line
              x1={activePoint.x}
              y1={padTop}
              x2={activePoint.x}
              y2={padTop + chartH}
              stroke="#0d9488"
              strokeWidth="1"
              strokeDasharray="2 2"
            />
          )}
        </svg>
      </div>
    </div>
  )
}

export default RevenueChart
