import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// In local development Vite forwards API calls to Spring Boot.
// The browser therefore calls the same origin (/api/...) and avoids CORS issues.
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8081',
        changeOrigin: true
      }
    }
  }
})
