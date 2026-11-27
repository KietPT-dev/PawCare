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
import Register, { validateRegisterForm, passwordIsValid } from '../features/auth/Register'
import VerifyEmail, { extractVerificationToken } from '../features/auth/VerifyEmail'

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

  it('renders Login screen with register trigger cleanly', () => {
    const html = renderToString(React.createElement(Login, { onLogin: () => {}, onRegister: () => {} }))
    expect(html).toContain('Đăng nhập Đối tác')
    expect(html).toContain('PawCare Partner Portal')
    expect(html).toContain('Đăng ký tài khoản')
    expect(html).toContain('Quên mật khẩu?')
  })

  it('renders Register screen cleanly with Provider fields and back button', () => {
    const html = renderToString(React.createElement(Register, { onBack: () => {}, onComplete: () => {} }))
    expect(html).toContain('Đăng ký Đối tác')
    expect(html).toContain('Cơ sở / Spa / Phòng khám')
    expect(html).toContain('Cá nhân cung cấp dịch vụ')
    expect(html).toContain('Xác nhận mật khẩu')
    expect(html).toContain('Quay lại đăng nhập')
  })

  it('validates Provider register form payload accurately against backend contract', () => {
    expect(passwordIsValid('short1')).toBe(false)
    expect(passwordIsValid('onlyletters')).toBe(false)
    expect(passwordIsValid('1234567890')).toBe(false)
    expect(passwordIsValid('PawCare2026!')).toBe(true)

    const invalid = validateRegisterForm({
      providerType: 'SHOP',
      fullName: ' ',
      providerName: '',
      email: 'bad-email',
      phone: '123',
      password: 'weak',
      confirmPassword: 'other',
    })
    expect(invalid.valid).toBe(false)
    expect(invalid.errors.fullName).toBeTruthy()
    expect(invalid.errors.providerName).toBeTruthy()
    expect(invalid.errors.email).toBeTruthy()
    expect(invalid.errors.phone).toBeTruthy()
    expect(invalid.errors.password).toBeTruthy()
    expect(invalid.errors.confirmPassword).toBeTruthy()

    const validShop = validateRegisterForm({
      providerType: 'SHOP',
      fullName: 'Nguyễn Thị Phương Thảo',
      providerName: 'Happy Paws Q1',
      email: 'Partner@PawCare.VN',
      phone: '090 123 4567',
      address: '123 Lê Lợi, Q1',
      password: 'PawCare2026!',
      confirmPassword: 'PawCare2026!',
    })
    expect(validShop.valid).toBe(true)
    expect(validShop.payload).toEqual({
      fullName: 'Nguyễn Thị Phương Thảo',
      email: 'partner@pawcare.vn',
      password: 'PawCare2026!',
      phone: '0901234567',
      address: '123 Lê Lợi, Q1',
      role: 'PROVIDER',
      providerName: 'Happy Paws Q1',
      providerType: 'SHOP',
    })
  })

  it('extracts email verification tokens from deep links and web URLs and renders VerifyEmail', () => {
    expect(extractVerificationToken('abc_token-123')).toBe('abc_token-123')
    expect(extractVerificationToken('pawcare://auth/verify-email?token=tok%2B123%3D')).toBe('tok+123=')
    expect(extractVerificationToken('https://provider.pawcare.vn/verify-email?token=xyz999')).toBe('xyz999')

    const htmlIdle = renderToString(React.createElement(VerifyEmail, { onBack: () => {} }))
    expect(htmlIdle).toContain('Xác minh email Đối tác')
    expect(htmlIdle).toContain('Xác nhận email')

    const htmlVerifying = renderToString(React.createElement(VerifyEmail, { token: 'sample-token', onBack: () => {} }))
    expect(htmlVerifying).toContain('Đang xác thực mã xác minh email')
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
