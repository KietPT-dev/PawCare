import { useEffect, useMemo, useState } from 'react'
import { api } from '../../shared/api'
import { ErrorState, Loading } from '../../shared/ui'

const splitAddress = value => {
  const pieces = String(value || '').split(',').map(x => x.trim()).filter(Boolean)
  return { detail: pieces[0] || '', ward: pieces[1] || '', district: pieces[2] || '', province: pieces.slice(3).join(', ') || '' }
}

export default function ProviderStoreSettings({ token, onClose }) {
  const [provider, setProvider] = useState(null)
  const [form, setForm] = useState({ detail: '', ward: '', district: '', province: '' })
  const [loading, setLoading] = useState(true), [saving, setSaving] = useState(false), [error, setError] = useState(''), [success, setSuccess] = useState('')
  const load = async () => { setLoading(true); try { const value = await api('/provider/me', {}, token); setProvider(value); setForm(splitAddress(value.address)); setError('') } catch (e) { setError(e.message) } finally { setLoading(false) } }
  useEffect(() => { load() }, [token])
  const address = useMemo(() => [form.detail, form.ward, form.district, form.province].filter(Boolean).join(', '), [form])
  const geocodeState = !address ? 'Cần cập nhật địa chỉ' : (provider?.latitude != null && provider?.longitude != null ? 'Đã xác định vị trí' : 'Chưa xác định được vị trí')
  async function save(e) { e.preventDefault(); if (!form.detail || !form.province) { setError('Vui lòng nhập địa chỉ chi tiết và tỉnh/thành.'); return } setSaving(true); try { await api('/provider/me', { method: 'PUT', body: JSON.stringify({ address }) }, token); setSuccess('Đã lưu địa chỉ hoạt động.'); setError(''); await load() } catch (err) { setError(err.message) } finally { setSaving(false) } }
  if (loading) return <Loading />
  return <form onSubmit={save} className="provider-store-settings">
    {error && <ErrorState error={error} retry={load} />}{success && <div className="success-banner">✓ {success}</div>}
    <section className="store-settings-section"><div><h4>Địa chỉ hoạt động</h4><p>Địa chỉ này được gửi theo field <code>address</code> của Provider. Khoảng cách và thứ tự “Gần tôi” do backend quyết định.</p></div><div className="form-grid"><div className="form-group form-full"><label className="form-label" htmlFor="address-detail">Địa chỉ chi tiết</label><input id="address-detail" className="form-input" value={form.detail} onChange={e=>setForm({...form,detail:e.target.value})} placeholder="Số nhà, tên đường" required /></div><div className="form-group"><label className="form-label" htmlFor="address-ward">Phường / xã</label><input id="address-ward" className="form-input" value={form.ward} onChange={e=>setForm({...form,ward:e.target.value})} placeholder="Phường, xã" /></div><div className="form-group"><label className="form-label" htmlFor="address-district">Quận / huyện</label><input id="address-district" className="form-input" value={form.district} onChange={e=>setForm({...form,district:e.target.value})} placeholder="Quận, huyện" /></div><div className="form-group form-full"><label className="form-label" htmlFor="address-province">Tỉnh / thành</label><input id="address-province" className="form-input" value={form.province} onChange={e=>setForm({...form,province:e.target.value})} placeholder="Tỉnh, thành phố" required /></div></div><div className={`location-status ${provider?.latitude != null ? 'success' : 'warning'}`}><b>Vị trí: {geocodeState}</b><span>{provider?.latitude != null ? 'Backend đã có toạ độ cho địa chỉ này.' : 'Lưu địa chỉ không tự geocode trên Web; vui lòng chờ backend cập nhật toạ độ.'}</span></div></section>
    <section className="store-settings-section"><div><h4>Ảnh nền cơ sở</h4><p>Customer Mobile sẽ dùng ảnh cover do backend cung cấp. Khi chưa có ảnh, ứng dụng Customer hiển thị ảnh fallback.</p></div><div className="cover-preview cover-fallback">{provider?.cover_image_url ? <img src={provider.cover_image_url} alt="Ảnh nền cơ sở" /> : <><strong>Chưa có ảnh nền</strong><span>Customer sẽ thấy ảnh fallback PawCare.</span></>}</div><div className="cover-api-note">Tải lên, thay hoặc xoá ảnh hiện chưa khả dụng vì API Provider chưa cung cấp endpoint và giới hạn định dạng/dung lượng.</div></section>
    <div className="modal-actions"><button type="button" className="btn-secondary" onClick={onClose}>Đóng</button><button className="btn-primary" disabled={saving}>{saving ? 'Đang lưu…' : 'Lưu địa chỉ'}</button></div>
  </form>
}
