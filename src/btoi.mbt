// This file is ported from
// https://github.com/niklasf/rust-btoi/blob/b8cb1769b8cd9c4c4c90836384fa730a50365ec3/src/lib.rs
// Copyright Apache-2.0 niklasf. All rights reserved.

///|
/// Reports why parsing an integer from ASCII bytes failed.
///
/// `Empty` is returned when the input contains no digits, including sign-only
/// inputs such as `+` and `-`. `InvalidDigit` means at least one byte is not a
/// valid digit for the selected radix. `PosOverflow` and `NegOverflow` indicate
/// that the parsed value does not fit in the destination integer type.
///
/// # Examples
///
/// ```
/// assert_eq(btoi(b"".to_array()), Err(Empty))
/// assert_eq(btoi(b"+".to_array()), Err(Empty))
/// assert_eq(btou_radix(b"ff".to_array(), 10), Err(InvalidDigit))
/// ```
pub enum ParseIntegerError {
  /// Cannot parse integer without digits.
  Empty
  /// Invalid digit found.
  InvalidDigit
  /// Integer too large to fit in target type.
  PosOverflow
  /// Integer too small to fit in target type.
  NegOverflow
} derive(Eq, Debug)

///|
/// Map an ASCII character to a digit value for the chosen radix.
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

///|
/// Copy bytes starting at `start` into a fresh array.
fn slice_bytes(bytes : Array[Byte], start : Int) -> Array[Byte] {
  let length = bytes.length() - start
  let result = Array::make(length, b'\x00')
  for i = 0; i < length; i = i + 1 {
    result[i] = bytes[start + i]
  }
  result
}

///|
/// Parse an unsigned integer from ASCII bytes in the given radix.
///
/// The input must contain at least one digit and may only use ASCII digits or
/// letters that are valid for `radix`. Signs are rejected. Overflow is reported
/// as `PosOverflow`.
///
/// # Panics
///
/// Panics when `radix` is outside `2..=36`.
///
/// # Examples
///
/// ```
/// assert_eq(btou_radix(b"255".to_array(), 10), Ok(255))
/// assert_eq(btou_radix(b"ff".to_array(), 16), Ok(255))
/// assert_eq(btou_radix(b"+42".to_array(), 10), Err(InvalidDigit))
/// ```
pub fn btou_radix(
  bytes : Array[Byte],
  radix : Int,
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

        // Check for overflow in multiplication.
        if result > @uint.MAX_VALUE / base {
          return Err(PosOverflow)
        }
        result = result * base

        // Check for overflow in addition.
        if result > @uint.MAX_VALUE - digit_val {
          return Err(PosOverflow)
        }
        result = result + digit_val
      }
      None => return Err(InvalidDigit)
    }
  }
  Ok(result)
}

///|
/// Parse a base-10 unsigned integer from ASCII bytes.
///
/// This is a convenience wrapper around `btou_radix(bytes, 10)`. The input must
/// not contain a leading sign.
///
/// # Examples
///
/// ```
/// assert_eq(btou(b"42".to_array()), Ok(42))
/// assert_eq(btou(b"0007".to_array()), Ok(7))
/// assert_eq(btou(b"-1".to_array()), Err(InvalidDigit))
/// ```
pub fn btou(bytes : Array[Byte]) -> Result[UInt, ParseIntegerError] {
  btou_radix(bytes, 10)
}

///|
/// Parse a signed integer from ASCII bytes in the given radix.
///
/// The input may start with `+` or `-`. All remaining bytes must be valid
/// digits for `radix`. Positive overflow returns `PosOverflow`, while negative
/// overflow returns `NegOverflow`.
///
/// # Panics
///
/// Panics when `radix` is outside `2..=36`.
///
/// # Examples
///
/// ```
/// assert_eq(btoi_radix(b"7f".to_array(), 16), Ok(127))
/// assert_eq(btoi_radix(b"-101010".to_array(), 2), Ok(-42))
/// assert_eq(btoi_radix(b"-".to_array(), 10), Err(Empty))
/// ```
pub fn btoi_radix(
  bytes : Array[Byte],
  radix : Int,
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
    // Parse the magnitude first, then negate if it still fits.
    match btou_radix(digits, radix) {
      Ok(val) => {
        let uint_val = val
        if uint_val > @int.MAX_VALUE.reinterpret_as_uint() + 1 {
          Err(NegOverflow)
        } else if uint_val == @int.MAX_VALUE.reinterpret_as_uint() + 1 {
          Ok(@int.MIN_VALUE)
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
        if uint_val > @int.MAX_VALUE.reinterpret_as_uint() {
          Err(PosOverflow)
        } else {
          Ok(uint_val.reinterpret_as_int())
        }
      }
      Err(e) => Err(e)
    }
  }
}

///|
/// Parse a base-10 signed integer from ASCII bytes.
///
/// This is a convenience wrapper around `btoi_radix(bytes, 10)`.
///
/// # Examples
///
/// ```
/// assert_eq(btoi(b"42".to_array()), Ok(42))
/// assert_eq(btoi(b"-42".to_array()), Ok(-42))
/// assert_eq(btoi(b"12x".to_array()), Err(InvalidDigit))
/// ```
pub fn btoi(bytes : Array[Byte]) -> Result[Int, ParseIntegerError] {
  btoi_radix(bytes, 10)
}

///|
/// Parse an unsigned integer and saturate to `UInt::max_value` on overflow.
///
/// Empty input and invalid digits still return an error. Only arithmetic
/// overflow changes behavior compared with `btou_radix`.
///
/// # Panics
///
/// Panics when `radix` is outside `2..=36`.
///
/// # Examples
///
/// ```
/// assert_eq(btou_saturating_radix(b"ff".to_array(), 16), Ok(255))
/// assert_eq(btou_saturating_radix(b"999999999999999999999999".to_array(), 10), Ok(@uint.MAX_VALUE))
/// assert_eq(btou_saturating_radix(b"xyz".to_array(), 10), Err(InvalidDigit))
/// ```
pub fn btou_saturating_radix(
  bytes : Array[Byte],
  radix : Int,
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

        // Stop early once the next multiplication would overflow.
        if result > @uint.MAX_VALUE / base {
          return Ok(@uint.MAX_VALUE)
        }
        result = result * base

        // Stop early once the next addition would overflow.
        if result > @uint.MAX_VALUE - digit_val {
          return Ok(@uint.MAX_VALUE)
        }
        result = result + digit_val
      }
      None => return Err(InvalidDigit)
    }
  }
  Ok(result)
}

///|
/// Parse a base-10 unsigned integer with saturating overflow handling.
///
/// This is a convenience wrapper around `btou_saturating_radix(bytes, 10)`.
///
/// # Examples
///
/// ```
/// assert_eq(btou_saturating(b"42".to_array()), Ok(42))
/// assert_eq(btou_saturating(b"999999999999999999999999".to_array()), Ok(@uint.MAX_VALUE))
/// ```
pub fn btou_saturating(bytes : Array[Byte]) -> Result[UInt, ParseIntegerError] {
  btou_saturating_radix(bytes, 10)
}

///|
/// Parse a signed integer and saturate on overflow.
///
/// Positive overflow returns `Int::max_value`, while negative overflow returns
/// `Int::min_value`. Empty input and invalid digits still produce the same
/// errors as `btoi_radix`.
///
/// # Panics
///
/// Panics when `radix` is outside `2..=36`.
///
/// # Examples
///
/// ```
/// assert_eq(btoi_saturating_radix(b"-ff".to_array(), 16), Ok(-255))
/// assert_eq(btoi_saturating_radix(b"999999999999999999999999".to_array(), 10), Ok(@int.MAX_VALUE))
/// assert_eq(btoi_saturating_radix(b"-999999999999999999999999".to_array(), 10), Ok(@int.MIN_VALUE))
/// ```
pub fn btoi_saturating_radix(
  bytes : Array[Byte],
  radix : Int,
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
        if uint_val > @int.MAX_VALUE.reinterpret_as_uint() + 1 {
          Ok(@int.MIN_VALUE)
        } else if uint_val == @int.MAX_VALUE.reinterpret_as_uint() + 1 {
          Ok(@int.MIN_VALUE)
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
        if uint_val > @int.MAX_VALUE.reinterpret_as_uint() {
          Ok(@int.MAX_VALUE)
        } else {
          Ok(uint_val.reinterpret_as_int())
        }
      }
      Err(e) => Err(e)
    }
  }
}

///|
/// Parse a base-10 signed integer with saturating overflow handling.
///
/// This is a convenience wrapper around `btoi_saturating_radix(bytes, 10)`.
///
/// # Examples
///
/// ```
/// assert_eq(btoi_saturating(b"-42".to_array()), Ok(-42))
/// assert_eq(btoi_saturating(b"-999999999999999999999999".to_array()), Ok(@int.MIN_VALUE))
/// ```
pub fn btoi_saturating(bytes : Array[Byte]) -> Result[Int, ParseIntegerError] {
  btoi_saturating_radix(bytes, 10)
}

// Convenience wrappers for string input.

///|
/// Parse a base-10 signed integer from a string.
///
/// The string is UTF-8 encoded and then parsed with `btoi`. This is useful when
/// your input is already a `String` and you do not want to convert it manually.
///
/// # Examples
///
/// ```
/// assert_eq(btoi_from_string("-42"), Ok(-42))
/// assert_eq(btoi_from_string("42x"), Err(InvalidDigit))
/// ```
pub fn btoi_from_string(s : String) -> Result[Int, ParseIntegerError] {
  btoi(@utf8.encode(s).to_array())
}

///|
/// Parse a base-10 unsigned integer from a string.
///
/// The accepted syntax and error behavior are the same as `btou`.
///
/// # Examples
///
/// ```
/// assert_eq(btou_from_string("42"), Ok(42))
/// assert_eq(btou_from_string("-42"), Err(InvalidDigit))
/// ```
pub fn btou_from_string(s : String) -> Result[UInt, ParseIntegerError] {
  btou(@utf8.encode(s).to_array())
}

///|
/// Parse a signed integer from a string in the given radix.
///
/// This is the string-based counterpart of `btoi_radix`.
///
/// # Examples
///
/// ```
/// assert_eq(btoi_radix_from_string("-ff", 16), Ok(-255))
/// assert_eq(btoi_radix_from_string("+101", 2), Ok(5))
/// ```
pub fn btoi_radix_from_string(
  s : String,
  radix : Int,
) -> Result[Int, ParseIntegerError] {
  btoi_radix(@utf8.encode(s).to_array(), radix)
}

///|
/// Parse an unsigned integer from a string in the given radix.
///
/// This is the string-based counterpart of `btou_radix`.
///
/// # Examples
///
/// ```
/// assert_eq(btou_radix_from_string("ff", 16), Ok(255))
/// assert_eq(btou_radix_from_string("102", 2), Err(InvalidDigit))
/// ```
pub fn btou_radix_from_string(
  s : String,
  radix : Int,
) -> Result[UInt, ParseIntegerError] {
  btou_radix(@utf8.encode(s).to_array(), radix)
}
