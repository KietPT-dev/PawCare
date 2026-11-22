import { describe, it, expect } from 'vitest'
import { renderToString } from 'react-dom/server'
import React from 'react'
import { Metric, Status, Empty, ErrorState, Loading, Badge } from './ui'
import { RevenueChart } from './RevenueChart'
import Dashboard from '../features/dashboard/Dashboard'
import WalletPage from '../features/wallet/WalletPage'
import ReportsPage from '../features/reports/ReportsPage'
import BookingsPage from '../features/bookings/BookingsPage'
import OperationsPage from '../features/operations/OperationsPage'
import ReviewsPage from '../features/reviews/ReviewsPage'
import Notifications from '../features/notifications/Notifications'
import Login from '../features/auth/Login'

describe('UI Components Render Tests', () => {
  it('renders Metric with object trend without throwing Objects are not valid as React child error', () => {
    const html = renderToString(
      React.createElement(Metric, {
        label: 'Doanh thu',
        value: '100.000 ₫',
        trend: { direction: 'up', text: '+12.4% so với kỳ trước' },
        hint: '10 booking',
      })
    )
    expect(html).toContain('Doanh thu')
    expect(html).toContain('100.000 ₫')
    expect(html).toContain('+12.4% so với kỳ trước')
    expect(html).toContain('↑')
  })

  it('renders Metric with string trend', () => {
    const html = renderToString(
      React.createElement(Metric, {
        label: 'Booking',
        value: 5,
        trend: 'Tăng 5%',
        trendType: 'up',
      })
    )
    expect(html).toContain('Tăng 5%')
  })

  it('renders ErrorState with Error object and string error', () => {
    const htmlObj = renderToString(
      React.createElement(ErrorState, { error: new Error('Mất kết nối mạng') })
    )
    expect(htmlObj).toContain('Mất kết nối mạng')

    const htmlStr = renderToString(
      React.createElement(ErrorState, { error: 'Lỗi máy chủ 500' })
    )
    expect(htmlStr).toContain('Lỗi máy chủ 500')
  })

  it('renders Status safely with string or object', () => {
    const html1 = renderToString(React.createElement(Status, { value: 'CONFIRMED' }))
    expect(html1).toContain('Đã xác nhận')

    const html2 = renderToString(React.createElement(Status, { value: { status: 'IN_SERVICE' } }))
    expect(html2).toContain('Đang thực hiện')
  })

  it('renders Dashboard without throwing React child error', () => {
    const mockBookings = [
      {
        id: 1,
        booking_start: new Date().toISOString(),
        customer_name: 'Nguyen Van A',
        pet_name: 'Miu',
        service_name: 'Tam say',
        status: 'CONFIRMED',
        estimated_price: 150000,
      },
      {
        id: 2,
        booking_start: new Date().toISOString(),
        customer_name: 'Tran Thi B',
        pet_name: 'Lu',
        service_name: 'Cat tia',
        status: 'PENDING_APPROVAL',
        estimated_price: 200000,
      },
    ]
    const mockDashboard = {
      total_bookings: 2,
      pending_bookings: 1,
      completed_revenue: 150000,
      completed_bookings: 1,
      average_rating: 4.8,
      review_count: 5,
    }

    const html = renderToString(
      React.createElement(Dashboard, {
        bookings: mockBookings,
        dashboard: mockDashboard,
        onNavigate: () => {},
      })
    )
    expect(html).toContain('Xin chào Quý Đối tác!')
    expect(html).toContain('Doanh thu hoàn tất')
    expect(html).toContain('+12.4% so với kỳ trước')
    expect(html).toContain('Tiến trình vận hành Booking')
  })

  it('renders RevenueChart with empty and non-empty daily data', () => {
    const emptyHtml = renderToString(React.createElement(RevenueChart, { data: [] }))
    expect(emptyHtml).toContain('Chưa có đủ dữ liệu')

    const chartHtml = renderToString(
      React.createElement(RevenueChart, {
        dailyData: [
          { booking_date: '2026-11-20', revenue: 100000, completed_bookings: 2 },
          { booking_date: '2026-11-21', revenue: 250000, completed_bookings: 4 },
        ],
      })
    )
    expect(chartHtml).toContain('Biến động doanh thu')
    expect(chartHtml).toContain('350.000')
  })

  it('renders Login screen cleanly', () => {
    const html = renderToString(React.createElement(Login, { onLogin: () => {} }))
    expect(html).toContain('Đăng nhập Đối tác')
    expect(html).toContain('PawCare Partner Portal')
  })

  it('renders WalletPage, ReportsPage, BookingsPage, OperationsPage, ReviewsPage, Notifications', () => {
    // Initial mount renders loading or container without throwing
    expect(() => renderToString(React.createElement(WalletPage, { token: 'mock' }))).not.toThrow()
    expect(() => renderToString(React.createElement(ReportsPage, { token: 'mock' }))).not.toThrow()
    expect(() => renderToString(React.createElement(BookingsPage, { token: 'mock' }))).not.toThrow()
    expect(() => renderToString(React.createElement(OperationsPage, { kind: 'services', token: 'mock' }))).not.toThrow()
    expect(() => renderToString(React.createElement(ReviewsPage, { token: 'mock' }))).not.toThrow()
    expect(() => renderToString(React.createElement(Notifications, { token: 'mock' }))).not.toThrow()
  })
})
