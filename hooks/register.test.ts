import { expect, test } from 'claude-code/testing'
import { placeOver } from './register.tsx'

test('video sits centered over the Claude window', () => {
  expect(placeOver('0, 33, 548, 418')).toEqual({ size: 308, left: 120, top: 72 })
  expect(placeOver('0, 0, 1512, 982')).toEqual({ size: 420, left: 546, top: 281 })
})
