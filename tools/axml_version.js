// Lee versionCode/versionName desde un AndroidManifest.xml binario (AXML).
const fs = require('fs');
const file = process.argv[2];
if (!file) throw new Error('Uso: node axml_version.js <AndroidManifest.xml>');
const b = fs.readFileSync(file);
let off = 0;
const u16 = (o) => b.readUInt16LE(o);
const u32 = (o) => b.readUInt32LE(o);

function readLen8(o) {
  let v = b[o++];
  if (v & 0x80) v = ((v & 0x7f) << 8) | b[o++];
  return [v, o];
}

function parseStrings(o, size) {
  const stringCount = u32(o + 8);
  const flags = u32(o + 16);
  const stringsStart = u32(o + 20);
  const out = [];
  const utf8 = (flags & 0x100) !== 0;
  for (let i = 0; i < stringCount; i++) {
    const rel = u32(o + 28 + i * 4);
    let p = o + stringsStart + rel;
    if (utf8) {
      let len;
      [len, p] = readLen8(p);
      readLen8(p); // encoded length
      out.push(b.slice(p, p + len).toString('utf8'));
    } else {
      const len = u16(p);
      p += 2;
      const chars = [];
      for (let j = 0; j < len; j++) {
        chars.push(b.readUInt16LE(p + j * 2));
      }
      out.push(String.fromCharCode(...chars));
    }
  }
  return out;
}

let strings = [];
const end = b.length;
while (off + 8 <= end) {
  const type = u16(off);
  const headerSize = u16(off + 2);
  const size = u32(off + 4);
  if (size < 8 || off + size > end) break;
  if (type === 0x0003) { off += headerSize; continue; }
  if (type === 0x0001) strings = parseStrings(off, size);
  if (type === 0x0102) {
    const nameIdx = u32(off + 16 + 4);
    const attrStart = u16(off + 16 + 8);
    const attrSize = u16(off + 16 + 10);
    const attrCount = u16(off + 16 + 12);
    const base = off + 16 + attrStart;
    for (let i = 0; i < attrCount; i++) {
      const p = base + i * attrSize;
      const attrName = strings[u32(p + 4)];
      const raw = strings[u32(p + 8)];
      const dataType = b[p + 15];
      const data = u32(p + 16);
      if (attrName === 'versionCode' || attrName === 'versionName') {
        console.log(`${attrName}=${dataType === 0x03 ? raw : data} (type=0x${dataType.toString(16)}, tag=${strings[nameIdx]})`);
      }
    }
  }
  off += size;
}
