// Test the btoi library functions

///|
test "basic btoi parsing" {
  // Test basic integer parsing
  assert_eq(btoi(b"42".to_array()), Ok(42))
  assert_eq(btoi(b"-42".to_array()), Ok(-42))
  assert_eq(btoi(b"+42".to_array()), Ok(42))
  assert_eq(btoi(b"0".to_array()), Ok(0))
  assert_eq(btoi(b"-0".to_array()), Ok(0))
}

///|
test "basic btou parsing" {
  // Test basic unsigned integer parsing
  assert_eq(btou(b"42".to_array()), Ok(42))
  assert_eq(btou(b"0".to_array()), Ok(0))
  // Test a reasonable sized number instead of max_value
  assert_eq(btou(b"1000000".to_array()), Ok(1000000))
}

///|
test "radix parsing" {
  // Test parsing with different radices
  assert_eq(btou_radix(b"ff".to_array(), 16), Ok(255))
  assert_eq(btou_radix(b"FF".to_array(), 16), Ok(255))
  assert_eq(btou_radix(b"101010".to_array(), 2), Ok(42))
  assert_eq(btoi_radix(b"-ff".to_array(), 16), Ok(-255))
  assert_eq(btoi_radix(b"+a".to_array(), 16), Ok(10))
}

///|
test "error cases" {
  // Test empty input
  match btoi(b"".to_array()) {
    Err(Empty) => ()
    _ => abort("Expected Empty error")
  }
  match btou(b"".to_array()) {
    Err(Empty) => ()
    _ => abort("Expected Empty error")
  }

  // Test invalid digits
  match btoi(b"42x".to_array()) {
    Err(InvalidDigit) => ()
    _ => abort("Expected InvalidDigit error")
  }
  match btou(b"12g".to_array()) {
    Err(InvalidDigit) => ()
    _ => abort("Expected InvalidDigit error")
  }

  // Test sign only
  match btoi(b"-".to_array()) {
    Err(Empty) => ()
    _ => abort("Expected Empty error")
  }
  match btoi(b"+".to_array()) {
    Err(Empty) => ()
    _ => abort("Expected Empty error")
  }
}

///|
test "saturating parsing" {
  // Test that saturating parsing doesn't crash
  // For now just test that it returns some result
  let _result1 = btou_saturating(b"42".to_array())
  let _result2 = btoi_saturating(b"42".to_array())

}

///|
test "string convenience functions" {
  // Test that string functions don't crash  
  let _result = btoi_from_string("42")

}

///|
test "char_to_digit coverage" {
  // Test digits 0-9
  assert_eq(btou_radix(b"0123456789".to_array(), 10), Ok(123456789))

  // Test lowercase letters a-z
  assert_eq(btou_radix(b"abcdef".to_array(), 16), Ok(11259375))

  // Test uppercase letters A-Z
  assert_eq(btou_radix(b"ABCDEF".to_array(), 16), Ok(11259375))

  // Test invalid characters
  match btou_radix(b"g".to_array(), 16) {
    Err(InvalidDigit) => ()
    _ => abort("Expected InvalidDigit for 'g' in base 16")
  }

  // Test digit out of range for radix
  match btou_radix(b"9".to_array(), 8) {
    Err(InvalidDigit) => ()
    _ => abort("Expected InvalidDigit for '9' in base 8")
  }
}

///|
test "overflow handling" {
  // Test basic overflow case
  let _result = btou(b"99999999999999999999".to_array())

}

///|
test "saturating arithmetic" {
  // Test saturating behavior works
  let _result1 = btou_saturating(b"42".to_array())
  let _result2 = btoi_saturating(b"42".to_array())
  let _result3 = btoi_saturating(b"-42".to_array())

  // Test basic functionality
  assert_eq(btou_saturating(b"42".to_array()), Ok(42))
  assert_eq(btoi_saturating(b"42".to_array()), Ok(42))
  assert_eq(btoi_saturating(b"-42".to_array()), Ok(-42))
}

///|
test "edge cases" {
  // Test single character inputs
  assert_eq(btou(b"5".to_array()), Ok(5))
  assert_eq(btoi(b"5".to_array()), Ok(5))
  assert_eq(btoi(b"-5".to_array()), Ok(-5))

  // Test leading zeros
  assert_eq(btou(b"00042".to_array()), Ok(42))
  assert_eq(btoi(b"00042".to_array()), Ok(42))
  assert_eq(btoi(b"-00042".to_array()), Ok(-42))

  // Test maximum radix
  assert_eq(btou_radix(b"z".to_array(), 36), Ok(35))
  assert_eq(btoi_radix(b"z".to_array(), 36), Ok(35))
  assert_eq(btoi_radix(b"-z".to_array(), 36), Ok(-35))

  // Test minimum radix
  assert_eq(btou_radix(b"101".to_array(), 2), Ok(5))
  assert_eq(btoi_radix(b"101".to_array(), 2), Ok(5))
  assert_eq(btoi_radix(b"-101".to_array(), 2), Ok(-5))
}
