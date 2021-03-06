//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension ByteBuffer {
    private func toEndianness<T: FixedWidthInteger> (value: T, endianness: Endianness) -> T {
        switch endianness {
        case .little:
            return value.littleEndian
        case .big:
            return value.bigEndian
        }
    }

    /// Read an integer off this `ByteBuffer`, move the reader index forward by the integer's byte size and return the result.
    ///
    /// - parameters:
    ///     - endianness: The endianness of the integer in this `ByteBuffer` (defaults to big endian).
    ///     - as: the desired `FixedWidthInteger` type (optional parameter)
    /// - returns: An integer value deserialized from this `ByteBuffer` or `nil` if there aren't enough bytes readable.
    public mutating func readInteger<T: FixedWidthInteger>(endianness: Endianness = .big, as: T.Type = T.self) -> T? {
        guard self.readableBytes >= MemoryLayout<T>.size else {
            return nil
        }

        let value: T = self.getInteger(at: self.readerIndex, endianness: endianness)! /* must work as we have enough bytes */
        self.moveReaderIndex(forwardBy: MemoryLayout<T>.size)
        return value
    }

    /// Get the integer at `index` from this `ByteBuffer`. Does not move the reader index.
    ///
    /// - parameters:
    ///     - index: The starting index of the bytes for the integer into the `ByteBuffer`.
    ///     - endianness: The endianness of the integer in this `ByteBuffer` (defaults to big endian).
    ///     - as: the desired `FixedWidthInteger` type (optional parameter)
    /// - returns: An integer value deserialized from this `ByteBuffer` or `nil` if the bytes of interest aren't contained in the `ByteBuffer`.
    public func getInteger<T: FixedWidthInteger>(at index: Int, endianness: Endianness = Endianness.big, as: T.Type = T.self) -> T? {
        precondition(index >= 0, "index must not be negative")
        return self.withVeryUnsafeBytes { ptr in
            guard index <= ptr.count - MemoryLayout<T>.size else {
                return nil
            }
            var value: T = 0
            withUnsafeMutableBytes(of: &value) { valuePtr in
                valuePtr.copyMemory(from: UnsafeRawBufferPointer(start: ptr.baseAddress!.advanced(by: index),
                                                                 count: MemoryLayout<T>.size))
            }
            return toEndianness(value: value, endianness: endianness)
        }
    }

    /// Write `integer` into this `ByteBuffer`, moving the writer index forward appropriately.
    ///
    /// - parameters:
    ///     - integer: The integer to serialize.
    ///     - endianness: The endianness to use, defaults to big endian.
    /// - returns: The number of bytes written.
    @discardableResult
    public mutating func write<T: FixedWidthInteger>(integer: T, endianness: Endianness = .big) -> Int {
        let bytesWritten = self.set(integer: integer, at: self.writerIndex, endianness: endianness)
        self.moveWriterIndex(forwardBy: bytesWritten)
        return Int(bytesWritten)
    }

    /// Write `integer` into this `ByteBuffer` starting at `index`. This does not alter the writer index.
    ///
    /// - parameters:
    ///     - integer: The integer to serialize.
    ///     - index: The index of the first byte to write.
    ///     - endianness: The endianness to use, defaults to big endian.
    /// - returns: The number of bytes written.
    @discardableResult
    public mutating func set<T: FixedWidthInteger>(integer: T, at index: Int, endianness: Endianness = .big) -> Int {
        var value = toEndianness(value: integer, endianness: endianness)
        return Swift.withUnsafeBytes(of: &value) { ptr in
            self.set(bytes: ptr, at: index)
        }
    }
}

extension UInt64 {
    /// Returns the next power of two.
    public func nextPowerOf2() -> UInt64 {
        guard self > 0 else {
            return 1
        }

        var n = self

        n -= 1
        n |= n >> 1
        n |= n >> 2
        n |= n >> 4
        n |= n >> 8
        n |= n >> 16
        n |= n >> 32
        n += 1

        return n
    }
}

extension UInt32 {
    /// Returns the next power of two unless that would overflow in which case UInt32.max is returned.
    public func nextPowerOf2ClampedToMax() -> UInt32 {
        guard self > 0 else {
            return 1
        }

        var n = self

        n -= 1
        n |= n >> 1
        n |= n >> 2
        n |= n >> 4
        n |= n >> 8
        n |= n >> 16
        if n != .max {
            n += 1
        }

        return n
    }

    /// Returns the next power of two.
    public func nextPowerOf2() -> UInt32 {
        guard self > 0 else {
            return 1
        }

        var n = self

        n -= 1
        n |= n >> 1
        n |= n >> 2
        n |= n >> 4
        n |= n >> 8
        n |= n >> 16
        n += 1

        return n
    }
}

/// Endianness refers to the sequential order in which bytes are arranged into larger numerical values when stored in
/// 	memory or when transmitted over digital links.
public enum Endianness {
    /// The endianness of the machine running this program.
    public static let host: Endianness = hostEndianness0()

    private static func hostEndianness0() -> Endianness {
        let number: UInt32 = 0x12345678
        return number == number.bigEndian ? .big : .little
    }

    /// big endian, the most significat byte (MSB) is at the lowest address
    case big

    /// little endian, the least significat byte (LSB) is at the lowest address
    case little
}


