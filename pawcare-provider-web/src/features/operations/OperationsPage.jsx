import { useEffect, useState, useMemo } from 'react'
import { api, rowsOf } from '../../shared/api'
import { money, dateTime } from '../../shared/format'
import { Empty, ErrorState, Loading, Status, Modal, Badge } from '../../shared/ui'
import { Icons } from '../../shared/icons'

const CONFIGS = {
  services: {
    title: 'Dịch vụ & Bảng giá',
    subtitle: 'Quản lý bảng giá, thời lượng chăm sóc và loại thú cưng hỗ trợ của cơ sở.',
    icon: Icons.Services,
    path: '/provider/services',
    addLabel: 'Thêm dịch vụ mới',
    fields: [
      { key: 'categoryId', label: 'Mã danh mục', type: 'number', placeholder: '1, 2…', required: true },
      { key: 'name', label: 'Tên dịch vụ', type: 'text', placeholder: 'VD: Cắt tỉa lông toàn diện', required: true },
      { key: 'price', label: 'Đơn giá (VNĐ)', type: 'number', placeholder: 'VD: 150000', required: true },
      { key: 'durationMinutes', label: 'Thời lượng (phút)', type: 'number', placeholder: 'VD: 60', required: true },
      { key: 'petTypeSupported', label: 'Loại thú cưng hỗ trợ', type: 'text', placeholder: 'VD: Chó, Mèo', required: false },
      { key: 'description', label: 'Mô tả chi tiết', type: 'textarea', placeholder: 'Mô tả quy trình chăm sóc...', required: false },
    ],
  },
  staff: {
    title: 'Đội ngũ nhân viên',
    subtitle: 'Quản lý thông tin kỹ thuật viên, bác sĩ thú y và chuyên viên spa.',
    icon: Icons.Staff,
    path: '/provider/staff',
    addLabel: 'Thêm nhân viên mới',
    fields: [
      { key: 'fullName', label: 'Họ và tên', type: 'text', placeholder: 'VD: Nguyễn Văn A', required: true },
      { key: 'phone', label: 'Số điện thoại', type: 'tel', placeholder: 'VD: 0901234567', required: false },
      { key: 'email', label: 'Email liên hệ', type: 'email', placeholder: 'VD: staff@pawcare.vn', required: false },
      { key: 'skills', label: 'Kỹ năng chuyên môn', type: 'text', placeholder: 'VD: Grooming, Tắm sấy, Khám tổng quát', required: false },
    ],
  },
  schedules: {
    title: 'Lịch làm việc & Ca trực',
    subtitle: 'Sắp xếp thời gian làm việc của nhân viên và khung giờ nhận booking.',
    icon: Icons.Schedules,
    path: '/provider/schedules',
    addLabel: 'Tạo ca làm việc',
    fields: [
      { key: 'staffId', label: 'Mã nhân viên (Staff ID)', type: 'number', placeholder: 'VD: 1', required: true },
      { key: 'startAt', label: 'Thời gian bắt đầu', type: 'datetime-local', required: true },
      { key: 'endAt', label: 'Thời gian kết thúc', type: 'datetime-local', required: true },
      {
        key: 'status',
        label: 'Trạng thái ca làm',
        type: 'select',
        options: ['AVAILABLE', 'BOOKED', 'BLOCKED'],
        required: true,
      },
      { key: 'note', label: 'Ghi chú ca trực', type: 'text', placeholder: 'VD: Ca sáng thứ 7', required: false },
    ],
  },
}

export default function OperationsPage({ kind, token }) {
  const c = CONFIGS[kind] || CONFIGS.services
  const IconComponent = c.icon

  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')
  const [editing, setEditing] = useState(null)
  const [search, setSearch] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const load = async (isManual = false) => {
    if (isManual) setRefreshing(true)
    else setLoading(true)
    try {
      setRows(rowsOf(await api(c.path, {}, token)))
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
  }, [kind, token])

  const filteredRows = useMemo(() => {
    if (!search) return rows
    const q = search.toLowerCase()
    return rows.filter(r =>
      Object.values(r).join(' ').toLowerCase().includes(q)
    )
  }, [rows, search])

  async function save(e) {
    e.preventDefault()
    const b = Object.fromEntries(new FormData(e.currentTarget))

    if (
      kind === 'services' &&
      (Number(b.price) < 0 || Number(b.durationMinutes) < 1)
    ) {
      setError('Đơn giá không được âm và thời lượng phải tối thiểu 1 phút.')
      return
    }

    if (kind === 'schedules' && new Date(b.endAt) <= new Date(b.startAt)) {
      setError('Thời điểm kết thúc ca phải sau thời điểm bắt đầu.')
      return
    }

    setSubmitting(true)
    try {
      await api(
        `${c.path}${editing?.id ? '/' + editing.id : ''}`,
        {
          method: editing?.id ? 'PUT' : 'POST',
          body: JSON.stringify(b),
        },
        token
      )
      setSuccessMsg(
        `${editing?.id ? 'Cập nhật' : 'Thêm mới'} ${c.title.toLowerCase()} thành công!`
      )
      setEditing(null)
      setTimeout(() => setSuccessMsg(''), 4000)
      load()
    } catch (e) {
      setError(e.message)
    } finally {
      setSubmitting(false)
    }
  }

  async function remove(id) {
    if (
      !window.confirm(
        'Xác nhận xóa mục này? Dữ liệu bị xóa sẽ không thể khôi phục.'
      )
    ) {
      return
    }
    try {
      await api(`${c.path}/${id}`, { method: 'DELETE' }, token)
      setSuccessMsg('Đã xóa thành công mục đã chọn!')
      setTimeout(() => setSuccessMsg(''), 4000)
      load()
    } catch (e) {
      setError(e.message)
    }
  }

  return (
    <div className="operations-page-container">
      {/* Header */}
      <header className="page-header">
        <div className="page-header-left">
          <div className="page-title-row">
            <h1 className="page-title">{c.title}</h1>
            <span className="badge badge-neutral">
              {rows.length} {kind === 'services' ? 'dịch vụ' : kind === 'staff' ? 'nhân sự' : 'ca trực'}
            </span>
          </div>
          <p className="page-subtitle">{c.subtitle}</p>
        </div>
        <div className="page-header-actions">
          <button
            type="button"
            className="btn-secondary"
            onClick={() => load(true)}
            disabled={refreshing || loading}
          >
            <Icons.Refresh size={16} className={refreshing ? 'animate-spin' : ''} />
            <span>Làm mới</span>
          </button>
          <button
            type="button"
            className="btn-primary"
            onClick={() => setEditing({})}
          >
            <Icons.Plus size={16} />
            <span>{c.addLabel}</span>
          </button>
        </div>
      </header>

      {error && <ErrorState error={error} retry={() => load()} />}
      {successMsg && (
        <div className="success-alert" style={{ marginBottom: '16px' }}>
          <Icons.CheckCircle size={18} />
          <span>{successMsg}</span>
        </div>
      )}

      {/* Toolbar / Search */}
      <section className="panel filter-panel">
        <div className="search-input-wrapper">
          <Icons.Search size={16} />
          <input
            type="text"
            className="search-input"
            placeholder={`Tìm kiếm trong ${c.title.toLowerCase()}…`}
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          {search && (
            <button
              type="button"
              className="search-clear-btn"
              onClick={() => setSearch('')}
            >
              <Icons.Close size={14} />
            </button>
          )}
        </div>
      </section>

      {/* Main Content Area */}
      {loading ? (
        <Loading />
      ) : filteredRows.length === 0 ? (
        <Empty
          icon={<IconComponent size={40} />}
          title={`Chưa có ${c.title.toLowerCase()} nào`}
          note={
            search
              ? 'Không tìm thấy kết quả phù hợp với từ khóa tìm kiếm.'
              : `Bắt đầu thêm ${c.title.toLowerCase()} để đưa cơ sở của bạn vào vận hành thực tế.`
          }
          action={
            <button
              type="button"
              className="btn-primary"
              onClick={() => setEditing({})}
            >
              <Icons.Plus size={16} />
              <span>{c.addLabel}</span>
            </button>
          }
        />
      ) : kind === 'services' ? (
        /* Services Grid Layout */
        <div className="service-cards-grid">
          {filteredRows.map(x => (
            <div key={x.id} className="service-card">
              <div className="service-card-header">
                <div className="service-icon-box">
                  <Icons.Paw size={22} />
                </div>
                <div className="service-header-meta">
                  <span className="service-category-pill">
                    Danh mục #{x.category_id || x.categoryId || '1'}
                  </span>
                  <strong className="service-title-text">{x.name}</strong>
                </div>
              </div>

              <p className="service-desc-text">
                {x.description || 'Chưa có mô tả chi tiết cho dịch vụ này.'}
              </p>

              <div className="service-specs-row">
                <div className="spec-item">
                  <Icons.Clock size={14} />
                  <span>{x.duration_minutes || x.durationMinutes || 60} phút</span>
                </div>
                <div className="spec-item">
                  <span>🐾 {x.pet_type_supported || x.petTypeSupported || 'Tất cả'}</span>
                </div>
              </div>

              <div className="service-card-footer">
                <div className="service-price-block">
                  <span className="price-label">Đơn giá niêm yết</span>
                  <strong className="price-amount text-emerald">
                    {money(x.price)}
                  </strong>
                </div>
                <div className="card-actions-group">
                  <button
                    type="button"
                    className="btn-secondary btn-sm"
                    onClick={() => setEditing(x)}
                    title="Chỉnh sửa dịch vụ"
                  >
                    <Icons.Edit size={14} />
                    <span>Sửa</span>
                  </button>
                  <button
                    type="button"
                    className="btn-ghost-danger btn-sm"
                    onClick={() => remove(x.id)}
                    title="Xóa dịch vụ"
                  >
                    <Icons.Trash size={14} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : kind === 'staff' ? (
        /* Staff Grid Layout */
        <div className="staff-cards-grid">
          {filteredRows.map(x => (
            <div key={x.id} className="staff-card">
              <div className="staff-card-header">
                <div className="staff-avatar-circle">
                  {(x.full_name || x.fullName || 'N').slice(0, 1).toUpperCase()}
                </div>
                <div className="staff-meta">
                  <strong className="staff-name-title">
                    {x.full_name || x.fullName || 'Nhân viên'}
                  </strong>
                  <span className="staff-role-pill">Kỹ thuật viên</span>
                </div>
              </div>

              <div className="staff-contacts">
                <div className="contact-item">
                  <Icons.User size={14} className="text-secondary" />
                  <span>{x.email || 'staff@pawcare.vn'}</span>
                </div>
                {x.phone && (
                  <div className="contact-item">
                    <Icons.Clock size={14} className="text-secondary" />
                    <span>{x.phone}</span>
                  </div>
                )}
              </div>

              <div className="staff-skills-box">
                <span className="skills-label">Kỹ năng:</span>
                <div className="skills-tags">
                  {(x.skills || 'Spa, Grooming, Chăm sóc cơ bản')
                    .split(',')
                    .map((s, idx) => (
                      <span key={idx} className="skill-tag">
                        {s.trim()}
                      </span>
                    ))}
                </div>
              </div>

              <div className="staff-card-footer">
                <button
                  type="button"
                  className="btn-secondary btn-sm"
                  onClick={() => setEditing(x)}
                >
                  <Icons.Edit size={14} />
                  <span>Sửa thông tin</span>
                </button>
                <button
                  type="button"
                  className="btn-ghost-danger btn-sm"
                  onClick={() => remove(x.id)}
                  title="Xóa nhân viên"
                >
                  <Icons.Trash size={14} />
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        /* Schedules Table Layout */
        <section className="panel">
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Mã ca trực</th>
                  <th>Nhân viên phụ trách</th>
                  <th>Thời gian bắt đầu</th>
                  <th>Thời gian kết thúc</th>
                  <th style={{ textAlign: 'center' }}>Trạng thái ca</th>
                  <th>Ghi chú</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredRows.map(x => (
                  <tr key={x.id}>
                    <td>
                      <span className="badge badge-neutral">Ca #{x.id}</span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <Icons.User size={15} className="text-secondary" />
                        <strong>Nhân viên #{x.staff_id || x.staffId || '1'}</strong>
                      </div>
                    </td>
                    <td>
                      <div className="booking-time-cell">
                        <Icons.Clock size={14} className="text-secondary" />
                        <span>{dateTime(x.start_at || x.startAt)}</span>
                      </div>
                    </td>
                    <td>
                      <div className="booking-time-cell">
                        <Icons.Clock size={14} className="text-secondary" />
                        <span>{dateTime(x.end_at || x.endAt)}</span>
                      </div>
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <Status value={x.status || 'AVAILABLE'} />
                    </td>
                    <td>
                      <span className="text-secondary text-sm">
                        {x.note || '—'}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div className="table-actions-group">
                        <button
                          type="button"
                          className="btn-secondary btn-sm"
                          onClick={() => setEditing(x)}
                        >
                          <Icons.Edit size={13} />
                          <span>Sửa</span>
                        </button>
                        <button
                          type="button"
                          className="btn-ghost-danger btn-sm"
                          onClick={() => remove(x.id)}
                        >
                          <Icons.Trash size={13} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {/* Add / Edit Modal */}
      {editing && (
        <Modal
          title={`${editing.id ? 'Chỉnh sửa' : 'Thêm mới'} ${c.title}`}
          subtitle="Điền đầy đủ thông tin bên dưới để cập nhật hệ thống"
          onClose={() => setEditing(null)}
          maxWidth="560px"
        >
          <form onSubmit={save} className="modal-form">
            <div className="form-grid">
              {c.fields.map(field => {
                const val =
                  editing[field.key] ||
                  editing[
                    field.key.replace(/[A-Z]/g, m => '_' + m.toLowerCase())
                  ] ||
                  ''
                const formattedVal =
                  field.type === 'datetime-local' && val
                    ? String(val).replace(' ', 'T').slice(0, 16)
                    : val

                if (field.type === 'textarea') {
                  return (
                    <div key={field.key} className="form-group form-full">
                      <label className="form-label">{field.label}</label>
                      <textarea
                        name={field.key}
                        className="form-textarea"
                        rows="3"
                        defaultValue={formattedVal}
                        placeholder={field.placeholder}
                        required={field.required}
                      />
                    </div>
                  )
                }

                if (field.type === 'select') {
                  return (
                    <div key={field.key} className="form-group">
                      <label className="form-label">{field.label}</label>
                      <select
                        name={field.key}
                        className="form-select"
                        defaultValue={formattedVal || field.options[0]}
                      >
                        {field.options.map(opt => (
                          <option key={opt} value={opt}>
                            {opt}
                          </option>
                        ))}
                      </select>
                    </div>
                  )
                }

                return (
                  <div
                    key={field.key}
                    className={`form-group ${
                      field.key === 'name' || field.key === 'fullName'
                        ? 'form-full'
                        : ''
                    }`}
                  >
                    <label className="form-label">{field.label}</label>
                    <input
                      name={field.key}
                      type={field.type}
                      className="form-input"
                      placeholder={field.placeholder}
                      defaultValue={formattedVal}
                      required={field.required}
                    />
                  </div>
                )
              })}
            </div>

            <div className="modal-actions-footer">
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setEditing(null)}
                disabled={submitting}
              >
                Hủy bỏ
              </button>
              <button
                type="submit"
                className="btn-primary"
                disabled={submitting}
              >
                <Icons.Check size={16} />
                <span>{submitting ? 'Đang lưu…' : 'Lưu dữ liệu'}</span>
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}
