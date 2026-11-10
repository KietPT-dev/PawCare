export const providerActions = {
  PENDING_APPROVAL: [['CONFIRMED', 'Chấp nhận'], ['REJECTED', 'Từ chối']],
  CONFIRMED: [['CHECKED_IN', 'Check-in']],
  CHECKED_IN: [['IN_SERVICE', 'Bắt đầu']],
  IN_SERVICE: [['SERVICE_DONE', 'Báo đã hoàn tất dịch vụ']]
}

export const canProviderTransition = (from, to) => (providerActions[from] || []).some(([status]) => status === to)
