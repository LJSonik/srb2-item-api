local bs = {}


---@class ByteStream


---@param bytes UINT8[]
---@return string
function bs.bytesToString(bytes)
	local chars = {}
	local j = 1

	for i = 1, #bytes / 1024 do
		chars[i] = string.char(unpack(bytes, j, j + 1023))
		j = j + 1024
	end

	chars[#bytes / 1024 + 1] = string.char(unpack(bytes, j, #bytes))

	return table.concat(chars)
end

---@param s string
---@return UINT8[]
function bs.stringToBytes(s)
	local bytes = {}
	local j = 1

	for i = 1, #s / 1024 do
		local chunk = {s:byte(j, j + 1024 - 1)}
		for i = 1, 1024 do
			bytes[j] = chunk[i]
			j = j + 1
		end
	end

	local chunk = {s:byte(j, #s)}
	for i = 1, 1024 do
		bytes[j] = chunk[i]
		j = j + 1
	end

	return bytes
end

---@param bytes? UINT8[]
---@return ByteStream
function bs.create(bytes)
	bytes = bytes or {}

	return {
		bytes = bytes,
		byteoffset = 1, bitoffset = 0,
		bytelen = #bytes, bitlen = 0
	}
end

---@param stream ByteStream
---@return ByteStream
function bs.share(stream)
	return {
		bytes = stream.bytes,
		byteoffset = stream.byteoffset, bitoffset = stream.bitoffset,
		bytelen = stream.bytelen, bitlen = stream.bitlen
	}
end

---@param stream ByteStream
---@return integer
function bs.totalBitOffset(stream)
	return 8 * (stream.byteoffset - 1) + stream.bitoffset
end

---@param stream ByteStream
---@return integer
function bs.totalBitLen(stream)
	return 8 * stream.bytelen + stream.bitlen
end

---@param stream ByteStream
---@param byteoffset integer
---@param bitoffset integer
function bs.seek(stream, byteoffset, bitoffset)
	stream.byteoffset = byteoffset
	stream.bitoffset = bitoffset
end

---@param stream ByteStream
function bs.seekStart(stream)
	bs.seek(stream, 1, 0)
end

---@param stream ByteStream
function bs.seekEnd(stream)
	bs.seek(stream, stream.bytelen + 1, stream.bitlen)
end

---@param stream ByteStream
---@return integer
function bs.readBit(stream)
	local byteoffset = stream.byteoffset
	local bitoffset = stream.bitoffset

	if bitoffset < 7 then
		stream.bitoffset = bitoffset + 1
	else
		stream.byteoffset = byteoffset + 1
		stream.bitoffset = 0
	end

	return (stream.bytes[byteoffset] >> (7 - bitoffset)) & 1
end
local readBit = bs.readBit

---@param stream ByteStream
---@param bit integer
function bs.writeBit(stream, bit)
	local bytes = stream.bytes
	local byteoffset = stream.byteoffset
	local bitoffset = stream.bitoffset

	if bitoffset ~= 0 then
		bytes[byteoffset] = bytes[byteoffset] | (bit << (7 - bitoffset))
	else
		bytes[byteoffset] = bit << 7
	end

	if bitoffset < 7 then
		bitoffset = bitoffset + 1
		stream.bitoffset = bitoffset
		stream.bitlen = bitoffset
	else
		stream.byteoffset = byteoffset + 1
		stream.bytelen = byteoffset

		stream.bitoffset = 0
		stream.bitlen = 0
	end
end
local writeBit = bs.writeBit

---@param stream ByteStream
---@return UINT8
function bs.readByte(stream)
	local bytes = stream.bytes

	local highbyteoffset = stream.byteoffset
	local highbitoffset = stream.bitoffset

	stream.byteoffset = highbyteoffset + 1

	if highbitoffset ~= 0 then
		local byte = (bytes[highbyteoffset]
			& (255 >> highbitoffset)) << highbitoffset

		local lowbitoffset = 8 - highbitoffset
		byte = byte | ((bytes[stream.byteoffset]
			& (255 << lowbitoffset)) >> lowbitoffset)

		return byte
	else
		return bytes[highbyteoffset]
	end
end
local readByte = bs.readByte

---@param stream ByteStream
---@param byte UINT8
function bs.writeByte(stream, byte)
	local bytes = stream.bytes

	local highbyteoffset = stream.byteoffset
	local highbitoffset = stream.bitoffset

	stream.byteoffset = highbyteoffset + 1
	stream.bytelen = highbyteoffset

	if highbitoffset ~= 0 then
		bytes[highbyteoffset] = bytes[highbyteoffset]
			| ((byte & (255 << highbitoffset)) >> highbitoffset)

		local lowbitoffset = 8 - highbitoffset
		bytes[stream.byteoffset] = (byte
			& (255 >> lowbitoffset)) << lowbitoffset
	else
		bytes[highbyteoffset] = byte
	end
end
local writeByte = bs.writeByte

---@param stream ByteStream
---@param len integer
---@return integer
function bs.readUInt(stream, len)
	local bytes = stream.bytes
	local byteoffset = stream.byteoffset
	local bitoffset = stream.bitoffset

	if bitoffset + len < 8 and bitoffset ~= 0 then
		stream.bitoffset = bitoffset + len
		return (bytes[byteoffset] >> (8 - bitoffset - len)) & ((1 << len) - 1)
	end

	local n = 0

	if bitoffset ~= 0 then
		local space = 8 - bitoffset
		len = len - space
		n = (bytes[byteoffset] & ((1 << space) - 1)) << len

		byteoffset = byteoffset + 1
		bitoffset = 0
	end

	while len >= 8 do
		len = len - 8
		n = n | (bytes[byteoffset] << len)
		byteoffset = byteoffset + 1
	end

	if len ~= 0 then
		n = n | (bytes[byteoffset] >> (8 - len))
		bitoffset = len
	end

	stream.byteoffset = byteoffset
	stream.bitoffset = bitoffset

	return n
end
local readUInt = bs.readUInt

---@param stream ByteStream
---@param len integer
---@param n integer
function bs.writeUInt(stream, len, n)
	local bytes = stream.bytes
	local byteoffset = stream.byteoffset
	local bitoffset = stream.bitoffset

	if bitoffset + len < 8 and bitoffset ~= 0 then
		bitoffset = bitoffset + len
		bytes[byteoffset] = bytes[byteoffset] | (n << (8 - bitoffset))
		stream.bitoffset = bitoffset
		stream.bitlen = bitoffset
		return
	end

	if bitoffset ~= 0 then
		local space = 8 - bitoffset
		len = len - space
		bytes[byteoffset] = bytes[byteoffset] | (n >> len)

		byteoffset = byteoffset + 1
		bitoffset = 0
	end

	while len >= 8 do
		len = len - 8
		bytes[byteoffset] = (n >> len) & 255
		byteoffset = byteoffset + 1
	end

	if len ~= 0 then
		bytes[byteoffset] = (n << (8 - len)) & 255
		bitoffset = len
	end

	stream.byteoffset = byteoffset
	stream.bitoffset = bitoffset

	stream.bytelen = byteoffset - 1
	stream.bitlen = bitoffset
end
local writeUInt = bs.writeUInt

---@param stream ByteStream
---@return UINT16
function bs.readUInt16(stream)
	return readUInt(stream, 16)
end

---@param stream ByteStream
---@param n UINT16
function bs.writeUInt16(stream, n)
	writeUInt(stream, 16, n)
end

---@param stream ByteStream
---@return INT32
function bs.readInt32(stream)
	return readUInt(stream, 32)
end

---@param stream ByteStream
---@param n INT32
function bs.writeInt32(stream, n)
	writeUInt(stream, 32, n)
end

---@param stream ByteStream
---@param num integer
---@param bytes? UINT8[]
---@param start? integer
---@return UINT8[]
function bs.readBytes(stream, num, bytes, start)
	bytes = bytes or {}
	start = start or 1

	for i = start, start + num - 1 do
		bytes[i] = readByte(stream)
	end

	return bytes
end

---@param stream ByteStream
---@param bytes UINT8[]
---@param start? integer
---@param num? integer
function bs.writeBytes(stream, bytes, start, num)
	start = start or 1
	if num == nil then
		num = #bytes
	end

	for i = start, start + num - 1 do
		writeByte(stream, bytes[i])
	end
end

---@param stream ByteStream
---@return string
function bs.readString(stream)
	local len = readByte(stream)
	if len == 255 then
		len = bs.readInt32(stream)
	end

	return bs.bytesToString(bs.readBytes(stream, len))
end

---@param stream ByteStream
---@param s string
function bs.writeString(stream, s)
	if #s < 255 then
		writeByte(stream, #s)
	else
		writeByte(stream, 255)
		writeInt32(stream, #s)
	end

	bs.writeBytes(stream, bs.stringToBytes(s))
end


return bs
