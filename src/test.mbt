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
  assert_eq(btou(b"4294967295".to_array()), Ok(@uint.max_value))
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
