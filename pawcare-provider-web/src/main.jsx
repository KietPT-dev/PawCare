import React, { useEffect, useMemo, useState } from 'react'
import { createRoot } from 'react-dom/client'
import './styles.css'

const API = import.meta.env.VITE_API_URL || '/api/v1'
const menu = [
  ['Tổng quan', '⌂'], ['Dịch vụ', '▤'], ['Nhân viên', '♙'], ['Lịch làm việc', '◷'],
  ['Booking', '▣'], ['Khách hàng', '♙'], ['Thú cưng', '♧'], ['Doanh thu', '▥'],
  ['Đánh giá', '☆'], ['Cài đặt', '⚙']
]

async function api(path, options = {}, token) {
  const response = await fetch(API + path, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...(options.headers || {}) }
  })
  const body = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(body.error || `Lỗi ${response.status}`)
  return body
}
const rowsOf = value => Array.isArray(value) ? value : (value?.data || [])

function Login({ onLogin }) {
  const [mode, setMode] = useState('login')
  const [form, setForm] = useState({ email: '', password: '', fullName: '', providerName: '', phone: '', address: '' })
  const [notice, setNotice] = useState('')
  const [error, setError] = useState(''); const [categories,setCategories]=useState([]); const [staffList,setStaffList]=useState([]); const [reload,setReload]=useState(0)
  const [busy, setBusy] = useState(false)
  const field = (key, placeholder, type = 'text') => <input type={type} placeholder={placeholder} value={form[key]} onChange={e => setForm({ ...form, [key]: e.target.value })} />
  async function submit() {
    setBusy(true); setError(''); setNotice('')
    try {
      if (mode === 'login') {
        const result = await api('/auth/login', { method: 'POST', body: JSON.stringify({ email: form.email, password: form.password }) })
        if (result.profile.role !== 'PROVIDER') throw new Error('Tài khoản này không phải Provider')
        onLogin(result.accessToken, result.profile)
      } else {
        await api('/auth/register', { method: 'POST', body: JSON.stringify({ ...form, role: 'PROVIDER', providerType: 'SHOP' }) })
        setNotice('Đăng ký thành công. Hồ sơ cơ sở đang chờ Admin xét duyệt trên Bonita.')
        setMode('login')
      }
    } catch (e) { setError(e.message) } finally { setBusy(false) }
  }
  return <div className="auth-page"><div className="auth-card"><div className="auth-paw">🐾</div><div className="auth-brand">PawCare</div><span className="auth-kicker">Provider portal</span><h1>{mode === 'login' ? 'Chào mừng trở lại' : 'Đăng ký Provider'}</h1><p>{mode === 'login' ? 'Đăng nhập để quản lý cơ sở của bạn.' : 'Tạo tài khoản và gửi hồ sơ để Admin duyệt.'}</p>
    {mode === 'register' && <div className="auth-extra">{field('fullName', 'Họ và tên người đại diện')}{field('providerName', 'Tên cơ sở / cửa hàng')}{field('phone', 'Số điện thoại')}{field('address', 'Địa chỉ cơ sở')}</div>}
    {field('email', 'Email', 'email')}{field('password', 'Mật khẩu (ít nhất 10 ký tự)', 'password')}
    <button className="auth-submit" disabled={busy} onClick={submit}>{busy ? 'Đang xử lý...' : mode === 'login' ? 'Đăng nhập' : 'Gửi hồ sơ đăng ký'} <span>→</span></button>
    {notice && <small className="notice">✓ {notice}</small>}{error && <small className="auth-error">{error}</small>}
    <button className="auth-link" onClick={() => { setMode(mode === 'login' ? 'register' : 'login'); setNotice(''); setError('') }}>{mode === 'login' ? 'Chưa có tài khoản? Đăng ký Provider' : 'Đã có tài khoản? Đăng nhập'}</button>
  </div></div>
}

function Metric({ icon, tone, label, value, hint }) { return <section className="metric"><span className={'metric-icon ' + tone}>{icon}</span><div><small>{label}</small><strong>{value}</strong><em>{hint}</em></div></section> }
function Empty({ title, note, icon = '✦' }) { return <div className="empty"><span>{icon}</span><b>{title}</b><p>{note}</p></div> }
function Status({ children }) { const s = String(children || '').toUpperCase(); const label = ({ PENDING: 'Chờ xác nhận', CONFIRMED: 'Đã xác nhận', CHECKED_IN: 'Đã check-in', COMPLETED: 'Hoàn tất', IN_SERVICE: 'Đang thực hiện', REJECTED: 'Đã từ chối', CANCELLED: 'Đã hủy', AVAILABLE: 'Sẵn sàng', BOOKED: 'Đã kín', BLOCKED: 'Đã khóa' })[s] || children || 'Mới'; return <span className={'status status-' + s.toLowerCase()}>{label}</span> }

function Dashboard({ bookings, schedules, staff, provider, dashboard = {}, revenue = [], onNavigate }) {
  const pending = bookings.filter(x => x.status === 'PENDING').length
  const completed = bookings.filter(x => x.status === 'COMPLETED').length
  const today = new Date().toLocaleDateString('vi-VN', { weekday: 'long', day: 'numeric', month: 'long' })
  const now = new Date(); const dateKey = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`
  const todaySchedules = schedules.filter(x => String(x.start_at || '').slice(0, 10) === dateKey)
  const staffName = id => staff.find(x => String(x.id) === String(id))?.full_name || 'Nhân viên'
  return <>
    {provider?.status === 'PENDING' && <div className="approval"><span>◷</span><div><b>Hồ sơ đang chờ duyệt</b><p>Admin đang xem xét thông tin cơ sở của bạn. Bạn vẫn có thể hoàn thiện dữ liệu vận hành.</p></div></div>}
    <div className="page-intro"><div><h1>Chào buổi sáng! <span>👋</span></h1><p>Đây là tổng quan hoạt động của cơ sở hôm nay.</p></div><span className="date-chip">▣ &nbsp; {today}</span></div>
    <div className="metrics"><Metric icon="▣" tone="blue" label="Tổng lịch hẹn" value={dashboard.total_bookings ?? bookings.length} hint="Tổng lượt đặt"/><Metric icon="◷" tone="orange" label="Booking chờ xác nhận" value={dashboard.pending_bookings ?? pending} hint="Cần xử lý"/><Metric icon="▥" tone="mint" label="Doanh thu hoàn tất" value={`${Number(dashboard.completed_revenue || 0).toLocaleString('vi-VN')} ₫`} hint={`${dashboard.completed_bookings || completed} booking hoàn tất`}/><Metric icon="★" tone="gold" label="Đánh giá trung bình" value={Number(dashboard.average_rating || 0).toFixed(1)} hint={`${dashboard.review_count || 0} đánh giá`}/></div>
    <div className="dashboard-grid"><section className="panel schedule"><div className="panel-title"><h2>Lịch làm việc hôm nay</h2><button onClick={() => onNavigate('Lịch làm việc')}>Xem toàn bộ →</button></div>{todaySchedules.length ? <div className="data-list compact-list">{todaySchedules.map(x => <article key={x.id}><div><b>{String(x.start_at).slice(11,16)} – {String(x.end_at).slice(11,16)}</b><p>{staffName(x.staff_id)} · {x.note || 'Ca làm việc'}</p></div><div className="row-meta"><Status>{x.status}</Status></div></article>)}</div> : <Empty icon="◷" title="Chưa có ca làm hôm nay" note="Tạo ca làm việc để lịch hiển thị tại đây." />}</section>
      <div className="right-stack"><section className="panel upcoming"><div className="panel-title"><h2>Booking sắp tới</h2><button onClick={() => onNavigate('Booking')}>Xem tất cả →</button></div>{bookings.length ? <div className="booking-list">{bookings.slice(0, 4).map((b, i) => <div className="booking-row" key={b.id || i}><time>{b.booking_start?.slice(11, 16) || '—'}</time><div><b>{b.customer_name || 'Khách hàng PawCare'}</b><span>#{b.id}</span></div><div><b>{b.service_name || 'Dịch vụ'}</b><Status>{b.status}</Status></div></div>)}</div> : <Empty icon="◫" title="Chưa có booking sắp tới" note="Booking mới sẽ xuất hiện tại đây." />}</section>
      <section className="panel revenue"><div className="panel-title"><h2>Doanh thu theo booking hoàn tất</h2><button>30 ngày⌄</button></div><div className="chart-area"><div className="chart-bars">{(revenue.length ? revenue.slice(0,7) : [{revenue:0}]).map((x, i) => <i key={i} style={{ height: `${Math.max(8, Math.min(100, Number(x.revenue || 0) / Math.max(...revenue.map(y=>Number(y.revenue||0)),1) * 100))}%` }}><small>{String(x.booking_date || '').slice(5) || '—'}</small></i>)}</div><div className="revenue-total"><small>Tổng doanh thu</small><b>{Number(dashboard.completed_revenue || 0).toLocaleString('vi-VN')} ₫</b><span>↗ Dữ liệu API</span></div></div></section></div></div>
  </>
}

function DataPage({ page, rows, token, categories, staff, onChanged }) {
  const [editing, setEditing] = useState(null); const [message, setMessage] = useState(''); const [query, setQuery] = useState('')
  const configs = {
    'Dịch vụ': { path:'/provider/services', title:'Dịch vụ của bạn', icon:'▤', fields:[['categoryId','Danh mục','select'],['name','Tên dịch vụ'],['description','Mô tả'],['price','Giá (VNĐ)','number'],['durationMinutes','Thời lượng (phút)','number'],['petTypeSupported','Loại thú cưng (VD: DOG,CAT)']] },
    'Nhân viên': { path:'/provider/staff', title:'Đội ngũ nhân viên', icon:'♙', fields:[['fullName','Họ và tên'],['phone','Số điện thoại'],['email','Email','email'],['skills','Kỹ năng / chuyên môn']] },
    'Lịch làm việc': { path:'/provider/schedules', title:'Lịch làm việc', icon:'◷', fields:[['staffId','Nhân viên','staff'],['startAt','Bắt đầu','datetime-local'],['endAt','Kết thúc','datetime-local'],['status','Trạng thái','status'],['note','Ghi chú']] }
  }
  const c=configs[page]
  if (!c) return <><div className="page-intro"><div><h1>{page}</h1><p>Báo cáo và vận hành cơ sở.</p></div></div><section className="panel"><Empty icon="▥" title="Đang hoàn thiện" note="Chức năng này sẽ được kết nối ở bước kế tiếp."/></section></>
  const valueFor = key => editing?.[key] ?? editing?.[key.replace(/[A-Z]/g, m => '_' + m.toLowerCase())] ?? ''
  const visibleRows = rows.filter(row => Object.values(row).some(value => String(value ?? '').toLowerCase().includes(query.trim().toLowerCase())))
  async function save(form) { try { const body=Object.fromEntries(new FormData(form).entries()); if (body.price !== undefined && (!Number.isFinite(Number(body.price)) || Number(body.price) < 0)) throw new Error('Giá dịch vụ phải là số không âm.'); if (body.durationMinutes !== undefined && (!Number.isInteger(Number(body.durationMinutes)) || Number(body.durationMinutes) < 1)) throw new Error('Thời lượng phải ít nhất 1 phút.'); if (body.startAt && body.endAt && new Date(body.endAt) <= new Date(body.startAt)) throw new Error('Thời điểm kết thúc phải sau thời điểm bắt đầu.'); const isEdit=Boolean(editing?.id); await api(c.path+(isEdit?'/'+editing.id:''),{method:isEdit?'PUT':'POST',body:JSON.stringify(body)},token); setEditing(null);setMessage(isEdit?'Đã cập nhật thành công.':'Đã thêm mới thành công.');onChanged() }catch(e){setMessage(e.message)} }
  async function remove(id){if(!confirm('Bạn có chắc muốn xóa mục này?'))return;try{await api(c.path+'/'+id,{method:'DELETE'},token);setMessage('Đã xóa thành công.');onChanged()}catch(e){setMessage(e.message)}}
  return <><div className="page-intro"><div><h1>{c.title}</h1><p>Quản lý thông tin vận hành của cơ sở.</p></div><button className="orange-action" onClick={()=>setEditing({})}>＋ Thêm mới</button></div>{message&&<div className="toast">✓ {message}</div>}<section className="panel data-panel"><div className="panel-title"><h2>{visibleRows.length?`${visibleRows.length} mục đang hiển thị`:'Dữ liệu vận hành'}</h2><label className="table-search">⌕ &nbsp;<input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Tìm kiếm" aria-label="Tìm kiếm"/></label></div>{visibleRows.length?<div className="data-list">{visibleRows.map((row,i)=><article key={row.id||i}><span className="row-icon">{c.icon}</span><div><b>{row.name||row.full_name||staff.find(x=>String(x.id)===String(row.staff_id))?.full_name||`Mục #${row.id}`}</b><p>{row.description||row.email||row.start_at||'Đang hoạt động'}</p></div><div className="row-meta">{row.price?`${Number(row.price).toLocaleString('vi-VN')} ₫`:<Status>{row.status}</Status>}</div><button className="edit" onClick={()=>setEditing(row)}>Sửa</button><button className="more" onClick={()=>remove(row.id)}>Xóa</button></article>)}</div>:<Empty icon={c.icon} title={query?'Không tìm thấy dữ liệu':'Chưa có '+page.toLowerCase()} note={query?'Hãy thử từ khóa khác.':'Bắt đầu bằng nút “Thêm mới”.'}/>}</section>{editing&&<div className="modal-backdrop"><form className="modal" onSubmit={e=>{e.preventDefault();save(e.currentTarget)}}><button type="button" className="modal-close" onClick={()=>setEditing(null)}>×</button><h2>{editing.id?'Cập nhật':'Thêm mới'} {page}</h2><p>Điền thông tin để lưu vào hệ thống.</p>{c.fields.map(([key,label,type])=><label key={key}>{label}{type==='select'?<select name={key} defaultValue={valueFor(key)} required><option value="">Chọn danh mục</option>{categories.map(x=><option value={x.id} key={x.id}>{x.name}</option>)}</select>:type==='staff'?<select name={key} defaultValue={valueFor(key)} required><option value="">Chọn nhân viên</option>{staff.map(x=><option value={x.id} key={x.id}>{x.full_name}</option>)}</select>:type==='status'?<select name={key} defaultValue={valueFor(key)||'AVAILABLE'}><option value="AVAILABLE">Sẵn sàng</option><option value="BOOKED">Đã kín</option><option value="BLOCKED">Đã khóa</option></select>:<input name={key} type={type||'text'} defaultValue={String(valueFor(key)).replace(' ','T').slice(0,16)} min={key==='price'?0:key==='durationMinutes'?1:undefined} step={key==='price'?'1000':key==='durationMinutes'?'1':undefined} required={['name','fullName','price','durationMinutes','startAt','endAt'].includes(key)}/>}</label>)}<button className="auth-submit">Lưu thông tin <span>→</span></button></form></div>}</>
}
function BookingPage({ bookings, token, onChanged }) {
  const [message,setMessage]=useState('')
  const next={PENDING:[['CONFIRMED','Xác nhận'],['REJECTED','Từ chối']],CONFIRMED:[['CHECKED_IN','Check-in']],CHECKED_IN:[['IN_SERVICE','Bắt đầu dịch vụ']],IN_SERVICE:[['COMPLETED','Hoàn tất']]}
  async function change(id,status){try{await api('/bookings/'+id+'/status',{method:'PUT',body:JSON.stringify({status,providerNote:''})},token);setMessage('Đã cập nhật trạng thái booking.');onChanged()}catch(e){setMessage(e.message)}}
  return <><div className="page-intro"><div><h1>Quản lý booking</h1><p>Xác nhận và theo dõi hành trình dịch vụ của khách hàng.</p></div><button className="date-chip">▣ &nbsp; Tất cả trạng thái⌄</button></div>{message&&<div className="toast">✓ {message}</div>}<section className="panel data-panel"><div className="panel-title"><h2>{bookings.length} booking</h2><div className="table-search">⌕ &nbsp; Tìm kiếm khách hàng</div></div>{bookings.length?<div className="booking-table"><div className="booking-head"><span>Thời gian</span><span>Khách hàng & thú cưng</span><span>Dịch vụ</span><span>Trạng thái</span><span>Thao tác</span></div>{bookings.map(b=><div className="booking-line" key={b.id}><span><b>{b.booking_start?.slice(0,10)||'—'}</b><small>{b.booking_start?.slice(11,16)||''}</small></span><span><b>{b.customer_name||'Khách hàng'}</b><small>Booking #{b.id}</small></span><span>{b.service_name||'Dịch vụ'}</span><span><Status>{b.status}</Status></span><span className="booking-actions">{(next[b.status]||[]).map(([to,label])=><button key={to} onClick={()=>change(b.id,to)}>{label}</button>)||'—'}</span></div>)}</div>:<Empty icon="▣" title="Chưa có booking" note="Khi khách hàng đặt lịch, booking sẽ xuất hiện tại đây."/>}</section></>
}
function RevenuePage({ bookings, dashboard = {}, revenue = [] }) { const completed=bookings.filter(x=>x.status==='COMPLETED'); const total=Number(dashboard.completed_revenue ?? completed.reduce((sum,x)=>sum+Number(x.estimated_price||0),0)); return <><div className="page-intro"><div><h1>Báo cáo doanh thu</h1><p>Tổng hợp từ booking hoàn tất trong hệ thống.</p></div><button className="date-chip">30 ngày⌄</button></div><div className="revenue-summary"><Metric icon="▥" tone="mint" label="Doanh thu đã hoàn tất" value={total.toLocaleString('vi-VN')+' ₫'} hint={(dashboard.completed_bookings||completed.length)+' booking hoàn tất'}/><Metric icon="▣" tone="blue" label="Tổng booking" value={dashboard.total_bookings||bookings.length} hint="Tất cả trạng thái"/><Metric icon="◷" tone="orange" label="Đang xử lý" value={dashboard.pending_bookings||bookings.filter(x=>!['COMPLETED','REJECTED'].includes(x.status)).length} hint="Booking hoạt động"/></div><section className="panel revenue-wide"><div className="panel-title"><h2>Doanh thu theo ngày</h2></div><div className="data-list">{revenue.length?revenue.map(x=><article key={x.booking_date}><div><b>{String(x.booking_date).slice(0,10)}</b><p>{x.completed_bookings} booking hoàn tất</p></div><div className="row-meta">{Number(x.revenue||0).toLocaleString('vi-VN')} ₫</div></article>):<Empty title="Chưa có doanh thu" note="Booking hoàn tất sẽ xuất hiện tại đây."/>}</div></section></> }
function SettingsPage({ provider, token, onChanged }) { const [message,setMessage]=useState(''); async function save(f){try{const b=Object.fromEntries(new FormData(f).entries());await api('/provider/me',{method:'PUT',body:JSON.stringify(b)},token);setMessage('Đã cập nhật thông tin cơ sở.');onChanged()}catch(e){setMessage(e.message)}} return <><div className="page-intro"><div><h1>Cài đặt cơ sở</h1><p>Cập nhật thông tin hiển thị của Provider.</p></div></div>{message&&<div className="toast">✓ {message}</div>}<form className="panel settings-form" onSubmit={e=>{e.preventDefault();save(e.currentTarget)}}><label>Tên cơ sở<input name="name" defaultValue={provider?.name||''}/></label><label>Điện thoại<input name="phone" defaultValue={provider?.phone||''}/></label><label>Email<input name="email" defaultValue={provider?.email||''}/></label><label>Địa chỉ<input name="address" defaultValue={provider?.address||''}/></label><label>Khu vực phục vụ<input name="serviceArea" defaultValue={provider?.service_area||''}/></label><label>Mô tả<textarea name="description" defaultValue={provider?.description||''}/></label><button className="orange-action">Lưu thay đổi</button></form></> }

function RelationshipPage({ page, rows }) { const meta={ 'Khách hàng':['Khách hàng của cơ sở','♙'], 'Thú cưng':['Thú cưng đã từng sử dụng dịch vụ','♧'], 'Đánh giá':['Đánh giá từ khách hàng','★'] }[page]; return <><div className="page-intro"><div><h1>{meta[0]}</h1><p>Dữ liệu được tổng hợp từ các booking của cơ sở.</p></div></div><section className="panel data-panel"><div className="panel-title"><h2>{rows.length} mục</h2><div className="table-search">⌕ &nbsp; Tìm kiếm</div></div>{rows.length?<div className="data-list">{rows.map((x,i)=><article key={x.id||i}><span className="row-icon">{meta[1]}</span><div><b>{x.full_name||x.name||x.customer_name||'Khách hàng PawCare'}</b><p>{x.email||x.species||x.service_name||x.comment||'Chưa có thông tin chi tiết'}</p></div><div className="row-meta">{x.rating?`★ ${x.rating}/5`:x.booking_count?`${x.booking_count} booking`:<Status>{x.status}</Status>}</div></article>)}</div>:<Empty icon={meta[1]} title={'Chưa có '+page.toLowerCase()} note="Dữ liệu sẽ xuất hiện khi khách hàng phát sinh booking hoặc đánh giá."/>}</section></> }

function App() {
  const [token, setToken] = useState(localStorage.pawcareProviderToken || '')
  const [profile, setProfile] = useState(JSON.parse(localStorage.pawcareProviderProfile || 'null'))
  const [page, setPage] = useState('Tổng quan')
  const [bookings, setBookings] = useState([])
  const [provider, setProvider] = useState(null)
  const [rows, setRows] = useState([])
  const [dashboard, setDashboard] = useState({})
  const [revenue, setRevenue] = useState([])
  const [schedules, setSchedules] = useState([])
  const [error, setError] = useState(''); const [categories,setCategories]=useState([]); const [staffList,setStaffList]=useState([]); const [reload,setReload]=useState(0)
  const login = (access, p) => { localStorage.pawcareProviderToken = access; localStorage.pawcareProviderProfile = JSON.stringify(p); setToken(access); setProfile(p) }
  useEffect(() => { if (!token) return; api('/bookings', {}, token).then(rowsOf).then(setBookings).catch(() => setBookings([])); api('/provider/me', {}, token).then(setProvider).catch(() => {}); api('/provider/dashboard', {}, token).then(setDashboard).catch(() => setDashboard({})); api('/provider/revenue', {}, token).then(rowsOf).then(setRevenue).catch(() => setRevenue([])); api('/categories').then(setCategories).catch(()=>{}); api('/provider/staff',{},token).then(rowsOf).then(setStaffList).catch(()=>{}); api('/provider/schedules',{},token).then(rowsOf).then(setSchedules).catch(()=>setSchedules([])) }, [token, reload])
  useEffect(() => { if (!token || page === 'Tổng quan') return; const paths = { 'Dịch vụ': '/provider/services', 'Nhân viên': '/provider/staff', 'Lịch làm việc': '/provider/schedules', Booking: '/bookings', 'Khách hàng':'/provider/customers', 'Thú cưng':'/provider/pets', 'Đánh giá':'/provider/reviews' }; if (!paths[page]) { setRows([]); return } api(paths[page], {}, token).then(x => { setRows(rowsOf(x)); setError('') }).catch(e => setError(e.message)) }, [token, page, reload])
  if (!token) return <Login onLogin={login} />
  return <div className="app-shell"><aside className="sidebar"><div className="logo"><span>🐾</span> PawCare</div><div className="clinic-card"><div className="clinic-avatar">{(provider?.name || profile?.fullName || 'P')[0]}</div><div><b>{provider?.name || 'Cơ sở PawCare'}</b><small>{provider?.status === 'PENDING' ? 'Đang chờ duyệt' : 'Provider Portal'}</small></div></div><nav>{menu.map(([name, icon]) => <button className={page === name ? 'selected' : ''} onClick={() => setPage(name)} key={name}><i>{icon}</i>{name}</button>)}</nav><div className="sidebar-bottom"><div className="pet-illustration">🐕</div><p>Cùng mang đến<br/>dịch vụ tốt nhất<br/>cho thú cưng.</p><button className="logout" onClick={() => { localStorage.removeItem('pawcareProviderToken'); localStorage.removeItem('pawcareProviderProfile'); setToken(''); setProfile(null) }}>↪ Đăng xuất</button></div></aside><main><header className="topbar"><div className="search">⌕ <span>Tìm booking, khách hàng, thú cưng...</span></div><div className="top-actions"><button className="bell">♢<i></i></button><div className="profile-mini"><div>{profile?.fullName?.[0] || 'P'}</div><span>{provider?.name || profile?.fullName || 'Provider'}⌄</span></div></div></header><div className="content">{error && <div className="error-banner">⚠ {error}</div>}{page === 'Tổng quan' ? <Dashboard bookings={bookings} schedules={schedules} staff={staffList} provider={provider} dashboard={dashboard} revenue={revenue} onNavigate={setPage} /> : page === 'Booking' ? <BookingPage bookings={bookings} token={token} onChanged={()=>setReload(x=>x+1)} /> : page === 'Doanh thu' ? <RevenuePage bookings={bookings} dashboard={dashboard} revenue={revenue} /> : page === 'Cài đặt' ? <SettingsPage provider={provider} token={token} onChanged={()=>setReload(x=>x+1)} /> : ['Khách hàng','Thú cưng','Đánh giá'].includes(page) ? <RelationshipPage page={page} rows={rows} /> : <DataPage page={page} rows={rows} token={token} categories={categories} staff={staffList} onChanged={()=>setReload(x=>x+1)} />}</div></main></div>
}
createRoot(document.getElementById('root')).render(<App />)
