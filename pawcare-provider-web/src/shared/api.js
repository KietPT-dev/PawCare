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

// XMLHttpRequest exposes upload progress; FormData lets the browser set the
// multipart boundary (setting Content-Type here would break the request).
export function uploadFile(path, file, token, onProgress) {
  return new Promise((resolve, reject) => {
    const request = new XMLHttpRequest()
    request.open('POST', `${API_BASE}${path}`)
    if (token) request.setRequestHeader('Authorization', `Bearer ${token}`)
    request.upload.onprogress = event => { if (event.lengthComputable) onProgress?.(Math.round(event.loaded / event.total * 100)) }
    request.onerror = () => reject(new ApiError('Không thể tải ảnh lên. Vui lòng thử lại.'))
    request.onload = () => {
      const body = (() => { try { return JSON.parse(request.responseText || '{}') } catch { return {} } })()
      if (request.status < 200 || request.status >= 300) reject(new ApiError(body.error || `Lỗi ${request.status}`, request.status))
      else resolve(body)
    }
    const form = new FormData(); form.append('file', file); request.send(form)
  })
}
