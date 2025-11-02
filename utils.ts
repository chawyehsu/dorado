declare global {
  interface Uint8Array {
    toHex(): string
  }
}

export function toHexPolyfill() {
  if (!Uint8Array.prototype.toHex) {
    Uint8Array.prototype.toHex = function (this: Uint8Array) {
      let out = ''
      for (const value of this) {
        out += value.toString(16).padStart(2, '0')
      }
      return out
    }
  }
}
