// Unified SVG Icon System for PawCare Provider Portal
import React from 'react'

const iconBase = (d, size = 18, className = '', strokeWidth = 2) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={strokeWidth}
    strokeLinecap="round"
    strokeLinejoin="round"
    className={`icon ${className}`}
  >
    {d}
  </svg>
)

export const Icons = {
  Paw: ({ size = 24, className = '' }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className}>
      <circle cx="8.5" cy="5.5" r="2.5" />
      <circle cx="15.5" cy="5.5" r="2.5" />
      <circle cx="4.5" cy="11.5" r="2.5" />
      <circle cx="19.5" cy="11.5" r="2.5" />
      <path d="M12 11c-3.3 0-6 2.5-6 6 0 2.2 1.8 4 4 4 1.1 0 2-.4 2-.9.1.5 1 .9 2 .9 2.2 0 4-1.8 4-4 0-3.5-2.7-6-6-6z" />
    </svg>
  ),
  Dashboard: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <rect x="3" y="3" width="7" height="9" rx="1.5" />
        <rect x="14" y="3" width="7" height="5" rx="1.5" />
        <rect x="14" y="12" width="7" height="9" rx="1.5" />
        <rect x="3" y="16" width="7" height="5" rx="1.5" />
      </>,
      size,
      className
    ),
  Services: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="m12 3-1.9 5.8a2 2 0 0 1-1.3 1.3L3 12l5.8 1.9a2 2 0 0 1 1.3 1.3L12 21l1.9-5.8a2 2 0 0 1 1.3-1.3L21 12l-5.8-1.9a2 2 0 0 1-1.3-1.3L12 3z" />
      </>,
      size,
      className
    ),
  Staff: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
      </>,
      size,
      className
    ),
  Schedules: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
        <line x1="16" y1="2" x2="16" y2="6" />
        <line x1="8" y1="2" x2="8" y2="6" />
        <line x1="3" y1="10" x2="21" y2="10" />
        <circle cx="12" cy="15" r="2" />
      </>,
      size,
      className
    ),
  Bookings: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
        <polyline points="14 2 14 8 20 8" />
        <line x1="16" y1="13" x2="8" y2="13" />
        <line x1="16" y1="17" x2="8" y2="17" />
        <polyline points="10 9 9 9 8 9" />
      </>,
      size,
      className
    ),
  Wallet: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M20 7H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z" />
        <path d="M16 3H4a2 2 0 0 0-2 2v2" />
        <circle cx="16" cy="14" r="1.5" />
      </>,
      size,
      className
    ),
  Reports: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <line x1="18" y1="20" x2="18" y2="10" />
        <line x1="12" y1="20" x2="12" y2="4" />
        <line x1="6" y1="20" x2="6" y2="14" />
        <line x1="3" y1="20" x2="21" y2="20" />
      </>,
      size,
      className
    ),
  Reviews: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
      </>,
      size,
      className
    ),
  Bell: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
        <path d="M13.73 21a2 2 0 0 1-3.46 0" />
      </>,
      size,
      className
    ),
  Chat: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M21 11.5a8.4 8.4 0 0 1-9 8.3 9.4 9.4 0 0 1-4-.9L3 21l1.6-4.1A8.2 8.2 0 0 1 3 12a8.5 8.5 0 0 1 9-8.5 8.5 8.5 0 0 1 9 8Z" />
        <line x1="8" y1="12" x2="16" y2="12" />
      </>,
      size,
      className
    ),
  Refresh: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67" />
      </>,
      size,
      className
    ),
  Search: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <circle cx="11" cy="11" r="8" />
        <line x1="21" y1="21" x2="16.65" y2="16.65" />
      </>,
      size,
      className
    ),
  Plus: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <line x1="12" y1="5" x2="12" y2="19" />
        <line x1="5" y1="12" x2="19" y2="12" />
      </>,
      size,
      className
    ),
  Edit: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
      </>,
      size,
      className
    ),
  Trash: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <polyline points="3 6 5 6 21 6" />
        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
      </>,
      size,
      className
    ),
  Close: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <line x1="18" y1="6" x2="6" y2="18" />
        <line x1="6" y1="6" x2="18" y2="18" />
      </>,
      size,
      className
    ),
  Check: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <polyline points="20 6 9 17 4 12" />
      </>,
      size,
      className
    ),
  CheckCircle: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
        <polyline points="22 4 12 14.01 9 11.01" />
      </>,
      size,
      className
    ),
  AlertCircle: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <circle cx="12" cy="12" r="10" />
        <line x1="12" y1="8" x2="12" y2="12" />
        <line x1="12" y1="16" x2="12.01" y2="16" />
      </>,
      size,
      className
    ),
  Shield: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      </>,
      size,
      className
    ),
  TrendingUp: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" />
        <polyline points="17 6 23 6 23 12" />
      </>,
      size,
      className
    ),
  ArrowRight: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <line x1="5" y1="12" x2="19" y2="12" />
        <polyline points="12 5 19 12 12 19" />
      </>,
      size,
      className
    ),
  ArrowLeft: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <line x1="19" y1="12" x2="5" y2="12" />
        <polyline points="12 19 5 12 12 5" />
      </>,
      size,
      className
    ),
  Mail: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <rect x="2" y="4" width="20" height="16" rx="2" />
        <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
      </>,
      size,
      className
    ),
  Phone: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
      </>,
      size,
      className
    ),
  MapPin: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
        <circle cx="12" cy="10" r="3" />
      </>,
      size,
      className
    ),
  ChevronDown: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <polyline points="6 9 12 15 18 9" />
      </>,
      size,
      className
    ),
  Menu: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <line x1="3" y1="12" x2="21" y2="12" />
        <line x1="3" y1="6" x2="21" y2="6" />
        <line x1="3" y1="18" x2="21" y2="18" />
      </>,
      size,
      className
    ),
  User: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
        <circle cx="12" cy="7" r="4" />
      </>,
      size,
      className
    ),
  Building: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
        <line x1="9" y1="22" x2="9" y2="12" />
        <line x1="15" y1="22" x2="15" y2="12" />
        <line x1="9" y1="6" x2="9.01" y2="6" />
        <line x1="15" y1="6" x2="15.01" y2="6" />
        <line x1="9" y1="10" x2="9.01" y2="10" />
        <line x1="15" y1="10" x2="15.01" y2="10" />
      </>,
      size,
      className
    ),
  Logout: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
        <polyline points="16 17 21 12 16 7" />
        <line x1="21" y1="12" x2="9" y2="12" />
      </>,
      size,
      className
    ),
  Calendar: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
        <line x1="16" y1="2" x2="16" y2="6" />
        <line x1="8" y1="2" x2="8" y2="6" />
        <line x1="3" y1="10" x2="21" y2="10" />
      </>,
      size,
      className
    ),
  Clock: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <circle cx="12" cy="12" r="10" />
        <polyline points="12 6 12 12 16 14" />
      </>,
      size,
      className
    ),
  CreditCard: ({ size = 18, className = '' }) =>
    iconBase(
      <>
        <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
        <line x1="1" y1="10" x2="23" y2="10" />
      </>,
      size,
      className
    ),
}
