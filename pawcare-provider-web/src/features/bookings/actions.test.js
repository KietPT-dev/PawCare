import { describe, expect, it } from 'vitest'
import { canProviderTransition, providerActions } from './actions'

describe('Provider booking actions', () => {
  it('only permits reporting service done from IN_SERVICE', () => {
    expect(canProviderTransition('IN_SERVICE', 'SERVICE_DONE')).toBe(true)
    expect(canProviderTransition('CONFIRMED', 'SERVICE_DONE')).toBe(false)
  })

  it('never exposes direct COMPLETED action to Provider', () => {
    expect(Object.values(providerActions).flat().some(([status]) => status === 'COMPLETED')).toBe(false)
  })
})
