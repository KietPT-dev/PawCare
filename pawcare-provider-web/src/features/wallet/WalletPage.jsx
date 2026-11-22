import { useEffect, useState, useMemo } from 'react'
import { api, rowsOf } from '../../shared/api'
import { money, dateTime } from '../../shared/format'
import { Empty, ErrorState, Loading, Metric, Status, Badge } from '../../shared/ui'
import { Icons } from '../../shared/icons'

const POPULAR_BANKS = [
  'Vietcombank',
  'MB Bank',
  'Techcombank',
  'ACB',
  'VPBank',
  'VietinBank',
  'BIDV',
]

export default function WalletPage({ token }) {
  const [wallet, setWallet] = useState({})
  const [ledger, setLedger] = useState([])
  const [withdrawals, setWithdrawals] = useState([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')
  const [ledgerSearch, setLedgerSearch] = useState('')

  const [form, setForm] = useState({
    bankName: 'Vietcombank',
    bankAccountNo: '',
    bankAccountName: '',
    amount: '',
  })

  const load = async (isManual = false) => {
    if (isManual) setRefreshing(true)
    else setLoading(true)
    try {
      const [w, p, r] = await Promise.all([
        api('/provider/wallet', {}, token),
        api('/provider/wallet/payouts', {}, token),
        api('/provider/wallet/withdrawals', {}, token),
      ])
      setWallet(w || {})
      setLedger(rowsOf(p))
      setWithdrawals(rowsOf(r))
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

  const filteredLedger = useMemo(() => {
    if (!ledgerSearch) return ledger
    const q = ledgerSearch.toLowerCase()
    return ledger.filter(
      x =>
        String(x.booking_id || '').includes(q) ||
        String(x.service_name || '').toLowerCase().includes(q) ||
        String(x.amount || '').includes(q)
    )
  }, [ledger, ledgerSearch])

  async function withdraw(e) {
    e.preventDefault()
    const withdrawAmount = Number(form.amount)
    const available = Number(wallet.availableBalance || 0)

    if (isNaN(withdrawAmount) || withdrawAmount <= 0) {
      setError('Vui lòng nhập số tiền hợp lệ.')
      return
    }

    if (withdrawAmount > available) {
      setError(`Số dư khả dụng (${money(available)}) không đủ để rút ${money(withdrawAmount)}.`)
      return
    }

    if (!window.confirm(`Xác nhận rút ${money(withdrawAmount)} về ngân hàng ${form.bankName} - STK: ${form.bankAccountNo}?`)) {
      return
    }

    try {
      await api(
        '/wallets/withdraw',
        { method: 'POST', body: JSON.stringify(form) },
        token
      )
      setSuccessMsg(`Yêu cầu rút ${money(withdrawAmount)} đã được gửi thành công và đang chờ xét duyệt!`)
      setForm({
        bankName: 'Vietcombank',
        bankAccountNo: '',
        bankAccountName: '',
        amount: '',
      })
      setTimeout(() => setSuccessMsg(''), 6000)
      load()
    } catch (e) {
      setError(e.message)
    }
  }

  const setAllBalance = () => {
    setForm(prev => ({
      ...prev,
      amount: String(wallet.availableBalance || 0),
    }))
  }

  const setQuickAmount = val => {
    setForm(prev => ({ ...prev, amount: String(val) }))
  }

  return (
    <div className="wallet-page-container">
      {/* Header */}
      <header className="page-header">
        <div className="page-header-left">
          <div className="page-title-row">
            <h1 className="page-title">Ví doanh thu & Tài chính</h1>
            <span className="badge badge-success">
              <span className="badge-dot" />
              Sẵn sàng giao dịch
            </span>
          </div>
          <p className="page-subtitle">
            Quản lý số dư, dòng tiền giải ngân từ Escrow và yêu cầu rút tiền về tài khoản ngân hàng.
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
            <span>{refreshing ? 'Đang làm mới…' : 'Làm mới'}</span>
          </button>
        </div>
      </header>

      {error && <ErrorState error={error} retry={() => load()} />}
      {successMsg && (
        <div className="success-alert" style={{ marginBottom: '20px' }}>
          <Icons.CheckCircle size={18} />
          <span>{successMsg}</span>
        </div>
      )}

      {loading ? (
        <Loading />
      ) : (
        <>
          {/* 4 Financial KPI Cards */}
          <div className="metrics-grid">
            <Metric
              icon={<Icons.Wallet size={24} />}
              tone="mint"
              label="Số dư khả dụng"
              value={money(wallet.availableBalance)}
              hint="Có thể rút về tài khoản ngân hàng ngay"
              trend={{ direction: 'up', text: 'Sẵn sàng rút' }}
            />
            <Metric
              icon={<Icons.Shield size={24} />}
              tone="orange"
              label="Tiền đang phong tỏa"
              value={money(wallet.lockedBalance)}
              hint="Bảo chứng an toàn trong ví Escrow"
              trend={{ direction: 'neutral', text: 'Bảo vệ giao dịch' }}
            />
            <Metric
              icon={<Icons.Clock size={24} />}
              tone="blue"
              label="Chờ giải ngân"
              value={money(wallet.pendingRevenue)}
              hint="Đã xong dịch vụ, chờ khách xác nhận"
              trend={{ direction: 'neutral', text: 'Chờ đối soát' }}
            />
            <Metric
              icon={<Icons.TrendingUp size={24} />}
              tone="gold"
              label="Tổng tích lũy đã nhận"
              value={money(wallet.totalEarned)}
              hint="Tổng doanh thu thực nhận đã giải ngân"
              trend={{ direction: 'up', text: 'Tổng tích lũy' }}
            />
          </div>

          {/* 2-Column Grid */}
          <div className="dashboard-grid">
            {/* Left Column: Ledger / Payout History */}
            <section className="panel">
              <div className="panel-header">
                <div>
                  <h3 className="panel-title">Sổ cái doanh thu (Ledger)</h3>
                  <p className="panel-subtitle">
                    Lịch sử các khoản tiền đã được giải ngân vào ví sau khi trừ phí sàn 10%
                  </p>
                </div>
                <span className="badge badge-neutral">
                  {filteredLedger.length} giao dịch
                </span>
              </div>

              {/* Search Bar */}
              <div className="table-search-row" style={{ marginBottom: '16px' }}>
                <div className="search-input-wrapper">
                  <Icons.Search size={16} />
                  <input
                    type="text"
                    className="search-input"
                    placeholder="Tìm theo mã Booking, tên dịch vụ…"
                    value={ledgerSearch}
                    onChange={e => setLedgerSearch(e.target.value)}
                  />
                  {ledgerSearch && (
                    <button
                      type="button"
                      className="search-clear-btn"
                      onClick={() => setLedgerSearch('')}
                    >
                      <Icons.Close size={14} />
                    </button>
                  )}
                </div>
              </div>

              {filteredLedger.length > 0 ? (
                <div className="ledger-table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Giao dịch / Dịch vụ</th>
                        <th>Thời gian</th>
                        <th style={{ textAlign: 'right' }}>Giá gốc</th>
                        <th style={{ textAlign: 'right' }}>Phí sàn (10%)</th>
                        <th style={{ textAlign: 'right' }}>Thực nhận</th>
                        <th style={{ textAlign: 'center' }}>Trạng thái</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredLedger.map(x => {
                        const gross = Number(x.gross_amount || 0)
                        const fee = gross * 0.1
                        const net = Number(x.amount || gross - fee)
                        return (
                          <tr key={x.id}>
                            <td>
                              <div className="ledger-cell-main">
                                <span className="ledger-booking-id">
                                  #{x.booking_id}
                                </span>
                                <strong className="ledger-service-name">
                                  {x.service_name || 'Dịch vụ'}
                                </strong>
                              </div>
                            </td>
                            <td>
                              <span className="text-secondary text-sm">
                                {dateTime(x.created_at)}
                              </span>
                            </td>
                            <td style={{ textAlign: 'right', fontWeight: 500 }}>
                              {money(gross)}
                            </td>
                            <td style={{ textAlign: 'right', color: 'var(--coral-500)', fontSize: '13px' }}>
                              -{money(fee)}
                            </td>
                            <td style={{ textAlign: 'right' }}>
                              <strong className="text-emerald" style={{ fontSize: '15px' }}>
                                +{money(net)}
                              </strong>
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
                  icon={<Icons.CreditCard size={40} />}
                  title="Chưa có giao dịch giải ngân nào"
                  note="Sau khi bạn hoàn tất dịch vụ và khách hàng xác nhận, tiền sẽ được tự động giải ngân vào ví và ghi vào sổ cái này."
                />
              )}
            </section>

            {/* Right Column: Withdrawal Form + Request History */}
            <div className="wallet-right-column">
              {/* Withdrawal Card */}
              <section className="panel withdrawal-panel">
                <div className="panel-header">
                  <div>
                    <h3 className="panel-title">Rút tiền về ngân hàng</h3>
                    <p className="panel-subtitle">Chuyển tiền từ số dư khả dụng về tài khoản chính chủ</p>
                  </div>
                  <Icons.CreditCard size={20} className="text-primary" />
                </div>

                <form onSubmit={withdraw} className="withdrawal-form">
                  <div className="form-group">
                    <label className="form-label">Chọn ngân hàng thụ hưởng</label>
                    <select
                      className="form-select"
                      value={form.bankName}
                      onChange={e => setForm({ ...form, bankName: e.target.value })}
                      required
                    >
                      {POPULAR_BANKS.map(b => (
                        <option key={b} value={b}>
                          {b}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Số tài khoản ngân hàng</label>
                    <input
                      type="text"
                      className="form-input"
                      placeholder="VD: 1029384756"
                      value={form.bankAccountNo}
                      onChange={e => setForm({ ...form, bankAccountNo: e.target.value })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Tên chủ tài khoản (Viết hoa không dấu)</label>
                    <input
                      type="text"
                      className="form-input"
                      placeholder="VD: NGUYEN VAN A"
                      value={form.bankAccountName}
                      onChange={e => setForm({ ...form, bankAccountName: e.target.value.toUpperCase() })}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <label className="form-label">Số tiền muốn rút (VNĐ)</label>
                      <button
                        type="button"
                        className="btn-text-link"
                        onClick={setAllBalance}
                      >
                        Rút tất cả ({money(wallet.availableBalance)})
                      </button>
                    </div>
                    <input
                      type="number"
                      min="1000"
                      className="form-input"
                      placeholder="Nhập số tiền..."
                      value={form.amount}
                      onChange={e => setForm({ ...form, amount: e.target.value })}
                      required
                    />
                  </div>

                  {/* Quick Amount Chips */}
                  <div className="quick-amount-chips">
                    {[500000, 1000000, 2000000, 5000000].map(val => (
                      <button
                        key={val}
                        type="button"
                        className="chip-btn"
                        onClick={() => setQuickAmount(val)}
                      >
                        {money(val)}
                      </button>
                    ))}
                  </div>

                  <div className="withdrawal-notice">
                    <Icons.Shield size={16} />
                    <span>
                      Miễn phí rút tiền. Hệ thống xử lý chuyển khoản trong vòng 24 giờ làm việc.
                    </span>
                  </div>

                  <button
                    type="submit"
                    className="btn-primary btn-block"
                    disabled={!Number(wallet.availableBalance)}
                  >
                    <Icons.Wallet size={16} />
                    <span>Gửi yêu cầu rút tiền</span>
                  </button>
                </form>
              </section>

              {/* Withdrawal History Card */}
              <section className="panel withdrawal-history-panel" style={{ marginTop: '20px' }}>
                <div className="panel-header">
                  <div>
                    <h3 className="panel-title">Lịch sử yêu cầu rút tiền</h3>
                    <p className="panel-subtitle">Theo dõi trạng thái xét duyệt</p>
                  </div>
                  <span className="badge badge-neutral">
                    {withdrawals.length} yêu cầu
                  </span>
                </div>

                {withdrawals.length > 0 ? (
                  <div className="withdrawal-list">
                    {withdrawals.map(x => (
                      <div key={x.id} className="withdrawal-item">
                        <div className="withdrawal-meta">
                          <strong className="withdrawal-amount">
                            {money(x.amount)}
                          </strong>
                          <span className="withdrawal-bank">
                            {x.bank_name || 'Ngân hàng'}
                          </span>
                          <span className="withdrawal-date">
                            {dateTime(x.created_at)}
                          </span>
                        </div>
                        <div className="withdrawal-status">
                          <Status value={x.status || 'PENDING'} />
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <Empty
                    icon={<Icons.Clock size={32} />}
                    title="Chưa có yêu cầu rút tiền nào"
                    note="Lịch sử các lần rút tiền và trạng thái phê duyệt sẽ hiển thị tại đây."
                  />
                )}
              </section>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
