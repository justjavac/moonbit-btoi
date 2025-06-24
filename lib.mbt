// This file is port from https://github.com/niklasf/rust-btoi/blob/b8cb1769b8cd9c4c4c90836384fa730a50365ec3/src/lib.rs
// Copyright Apache-2.0 niklasf. All rights reserved.

/// Parse integers from ASCII byte arrays.
///
/// Provides functions similar to parsing from strings, but is faster when
/// parsing directly from byte arrays instead of strings.
///
/// # Examples
///
/// Basic usage:
/// - `btoi(b"42".to_array())` returns `Ok(42)`
/// - `btoi(b"-1000".to_array())` returns `Ok(-1000)`

///| Error that can occur when trying to parse an integer.
pub enum ParseIntegerError {
  /// Cannot parse integer without digits.
  Empty
  /// Invalid digit found.
  InvalidDigit
  /// Integer too large to fit in target type.
  PosOverflow
  /// Integer too small to fit in target type.
  NegOverflow
} derive(Eq, Show)

///| Convert a character to its digit value in the given radix.
/// Returns None if the character is not a valid digit in the radix.
fn char_to_digit(ch : Char, radix : Int) -> Int? {
  let code = ch.to_int()
  let digit = if code >= 48 && code <= 57 {
    // '0' to '9'
    code - 48
  } else if code >= 97 && code <= 122 {
    // 'a' to 'z'
    code - 97 + 10
  } else if code >= 65 && code <= 90 {
    // 'A' to 'Z'
    code - 65 + 10
  } else {
    -1
  }
  if digit >= 0 && digit < radix {
    Some(digit)
  } else {
    None
  }
}

///| Create a subarray from bytes starting at given position
fn slice_bytes(bytes : Array[Byte], start : Int) -> Array[Byte] {
  let length = bytes.length() - start
  let result = Array::make(length, b'\x00')
  for i = 0; i < length; i = i + 1 {
    result[i] = bytes[start + i]
  }
  result
}

///| Converts a byte array in a given base to an unsigned integer.
/// Signs are not allowed.
///
/// # Errors
///
/// Returns ParseIntegerError for any of the following conditions:
///
/// * bytes is empty
/// * not all characters of bytes are 0-9, a-z or A-Z
/// * not all characters refer to digits in the given radix
/// * the number overflows the target type
///
/// # Panics
///
/// Panics if radix is not in the range 2..=36.
pub fn btou_radix(
  bytes : Array[Byte],
  radix : Int
) -> Result[UInt, ParseIntegerError] {
  if radix < 2 || radix > 36 {
    abort("radix must lie in the range 2..=36")
  }
  if bytes.length() == 0 {
    return Err(Empty)
  }
  let mut result : UInt = 0
  let base = radix.reinterpret_as_uint()
  for i = 0; i < bytes.length(); i = i + 1 {
    let byte = bytes[i]
    let ch = Int::unsafe_to_char(byte.to_int())
    match char_to_digit(ch, radix) {
      Some(digit) => {
        let digit_val = digit.reinterpret_as_uint()

        // Check for overflow in multiplication
        if result > @uint.max_value / base {
          return Err(PosOverflow)
        }
        result = result * base

        // Check for overflow in addition
        if result > @uint.max_value - digit_val {
          return Err(PosOverflow)
        }
        result = result + digit_val
      }
      None => return Err(InvalidDigit)
    }
  }
  Ok(result)
}

///| Converts a byte array to an unsigned integer. Signs are not allowed.
pub fn btou(bytes : Array[Byte]) -> Result[UInt, ParseIntegerError] {
  btou_radix(bytes, 10)
}

///| Converts a byte array in a given base to a signed integer.
///
/// Numbers may optionally start with a sign (- or +).
pub fn btoi_radix(
  bytes : Array[Byte],
  radix : Int
) -> Result[Int, ParseIntegerError] {
  if radix < 2 || radix > 36 {
    abort("radix must lie in the range 2..=36")
  }
  if bytes.length() == 0 {
    return Err(Empty)
  }
  let (is_negative, digits_start) = match bytes[0] {
    43 => (false, 1) // '+'
    45 => (true, 1) // '-'
    _ => (false, 0)
  }
  if digits_start >= bytes.length() {
    return Err(Empty)
  }
  let digits = slice_bytes(bytes, digits_start)
  if is_negative {
    // For negative numbers, we parse as positive first then negate
    match btou_radix(digits, radix) {
      Ok(val) => {
        let uint_val = val
        // Check if the positive value would overflow when negated
        if uint_val > @int.max_value.reinterpret_as_uint() + 1 {
          Err(NegOverflow)
        } else if uint_val == @int.max_value.reinterpret_as_uint() + 1 {
          // Special case for Int::min_value()
          Ok(@int.min_value)
        } else {
          Ok(-uint_val.reinterpret_as_int())
        }
      }
      Err(Empty) => Err(Empty)
      Err(InvalidDigit) => Err(InvalidDigit)
      Err(_) => Err(NegOverflow)
    }
  } else {
    match btou_radix(digits, radix) {
      Ok(val) => {
        let uint_val = val
        if uint_val > @int.max_value.reinterpret_as_uint() {
          Err(PosOverflow)
        } else {
          Ok(uint_val.reinterpret_as_int())
        }
      }
      Err(e) => Err(e)
    }
  }
}

///| Converts a byte array to a signed integer.
///
/// Numbers may optionally start with a sign (- or +).
pub fn btoi(bytes : Array[Byte]) -> Result[Int, ParseIntegerError] {
  btoi_radix(bytes, 10)
}

///| Converts a byte array in a given base to the closest possible unsigned integer.
/// Signs are not allowed. Uses saturating arithmetic for overflow handling.
pub fn btou_saturating_radix(
  bytes : Array[Byte],
  radix : Int
) -> Result[UInt, ParseIntegerError] {
  if radix < 2 || radix > 36 {
    abort("radix must lie in the range 2..=36")
  }
  if bytes.length() == 0 {
    return Err(Empty)
  }
  let mut result : UInt = 0
  let base = radix.reinterpret_as_uint()
  for i = 0; i < bytes.length(); i = i + 1 {
    let byte = bytes[i]
    let ch = Int::unsafe_to_char(byte.to_int())
    match char_to_digit(ch, radix) {
      Some(digit) => {
        let digit_val = digit.reinterpret_as_uint()

        // Check for overflow in multiplication
        if result > @uint.max_value / base {
          return Ok(@uint.max_value)
        }
        result = result * base

        // Check for overflow in addition
        if result > @uint.max_value - digit_val {
          return Ok(@uint.max_value)
        }
        result = result + digit_val
      }
      None => return Err(InvalidDigit)
    }
  }
  Ok(result)
}

///| Converts a byte array to the closest possible unsigned integer.
/// Signs are not allowed. Uses saturating arithmetic for overflow handling.
pub fn btou_saturating(bytes : Array[Byte]) -> Result[UInt, ParseIntegerError] {
  btou_saturating_radix(bytes, 10)
}

///| Converts a byte array in a given base to the closest possible signed integer.
/// Uses saturating arithmetic for overflow handling.
pub fn btoi_saturating_radix(
  bytes : Array[Byte],
  radix : Int
) -> Result[Int, ParseIntegerError] {
  if radix < 2 || radix > 36 {
    abort("radix must lie in the range 2..=36")
  }
  if bytes.length() == 0 {
    return Err(Empty)
  }
  let (is_negative, digits_start) = match bytes[0] {
    43 => (false, 1) // '+'
    45 => (true, 1) // '-'
    _ => (false, 0)
  }
  if digits_start >= bytes.length() {
    return Err(Empty)
  }
  let digits = slice_bytes(bytes, digits_start)
  if is_negative {
    match btou_saturating_radix(digits, radix) {
      Ok(val) => {
        let uint_val = val
        if uint_val > @int.max_value.reinterpret_as_uint() + 1 {
          Ok(@int.min_value)
        } else if uint_val == @int.max_value.reinterpret_as_uint() + 1 {
          Ok(@int.min_value)
        } else {
          Ok(-uint_val.reinterpret_as_int())
        }
      }
      Err(e) => Err(e)
    }
  } else {
    match btou_saturating_radix(digits, radix) {
      Ok(val) => {
        let uint_val = val
        if uint_val > @int.max_value.reinterpret_as_uint() {
          Ok(@int.max_value)
        } else {
          Ok(uint_val.reinterpret_as_int())
        }
      }
      Err(e) => Err(e)
    }
  }
}

///| Converts a byte array to the closest possible signed integer.
/// Uses saturating arithmetic for overflow handling.
pub fn btoi_saturating(bytes : Array[Byte]) -> Result[Int, ParseIntegerError] {
  btoi_saturating_radix(bytes, 10)
}

// Convenience functions for string input

///|
pub fn btoi_from_string(s : String) -> Result[Int, ParseIntegerError] {
  btoi(s.to_bytes().to_array())
}

///|
pub fn btou_from_string(s : String) -> Result[UInt, ParseIntegerError] {
  btou(s.to_bytes().to_array())
}

///|
pub fn btoi_radix_from_string(
  s : String,
  radix : Int
) -> Result[Int, ParseIntegerError] {
  btoi_radix(s.to_bytes().to_array(), radix)
}

///|
pub fn btou_radix_from_string(
  s : String,
  radix : Int
) -> Result[UInt, ParseIntegerError] {
  btou_radix(s.to_bytes().to_array(), radix)
}
