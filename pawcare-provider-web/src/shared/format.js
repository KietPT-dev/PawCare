export const money = value => `${Number(value || 0).toLocaleString('vi-VN')} ₫`
export const dateTime = value => value ? new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value)) : '—'
export const dateOnly = value => value ? new Intl.DateTimeFormat('vi-VN', { dateStyle: 'medium' }).format(new Date(value)) : '—'

export const statusLabel = status => ({
  PENDING_APPROVAL: 'Chờ duyệt · Escrow', CONFIRMED: 'Đã xác nhận', CHECKED_IN: 'Đã check-in', IN_SERVICE: 'Đang thực hiện',
  SERVICE_DONE: 'Chờ Customer xác nhận · Escrow', COMPLETED: 'Đã giải ngân', REJECTED: 'Đã từ chối · Hoàn tiền',
  CANCELLED: 'Đã hủy', DISPUTED: 'Tranh chấp · Escrow', PENDING: 'Chờ duyệt', APPROVED: 'Đã duyệt', AVAILABLE: 'Sẵn sàng', BOOKED: 'Đã kín', BLOCKED: 'Đã khóa'
})[String(status || '').toUpperCase()] || status || 'Mới'
