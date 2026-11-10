// VITE_API_URL is supplied by each environment.  The fallback only targets the
// local Vite proxy/API path and never embeds a deployed host in the bundle.
export const API_BASE = import.meta.env.VITE_API_URL || '/api/v1'

export class ApiError extends Error {
  constructor(message, status = 0) { super(message); this.status = status }
}

export async function api(path, options = {}, token) {
  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...(options.headers || {}) }
  })
  const body = await response.json().catch(() => ({}))
  if (response.status === 401) window.dispatchEvent(new Event('pawcare:unauthorized'))
  if (!response.ok) throw new ApiError(body.error || `Lỗi ${response.status}`, response.status)
  return body
}

export const rowsOf = value => Array.isArray(value) ? value : (value?.data || [])
