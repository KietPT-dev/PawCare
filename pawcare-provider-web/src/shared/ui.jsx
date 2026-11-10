import { statusLabel } from './format'
export function Status({ value }) { return <span className={`status status-${String(value || '').toLowerCase()}`}>{statusLabel(value)}</span> }
export function Empty({ title, note }) { return <div className="empty"><span>✦</span><b>{title}</b><p>{note}</p></div> }
export function Loading() { return <Empty title="Đang tải dữ liệu" note="Vui lòng chờ trong giây lát…" /> }
export function ErrorState({ error, retry }) { return <div className="error-banner">⚠ {error} {retry && <button className="edit" onClick={retry}>Thử lại</button>}</div> }
export function Metric({ icon, tone, label, value, hint }) { return <section className="metric"><span className={`metric-icon ${tone}`}>{icon}</span><div><small>{label}</small><strong>{value}</strong><em>{hint}</em></div></section> }
