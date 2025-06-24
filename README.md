# moonbit-btoi

Parse integers from ASCII byte arrays in MoonBit.

This library provides functions similar to Rust's `btoi` crate, offering fast
integer parsing directly from byte arrays instead of strings. It's particularly
useful when working with binary protocols, parsing large amounts of numeric
data, or when performance is critical.

## Features

- 🚀 **Fast parsing**: Direct from byte arrays, avoiding string conversions
- 🔢 **Multiple radix support**: Parse integers in bases 2-36
- 🛡️ **Robust error handling**: Comprehensive error types for different failure
  modes
- ⚡ **Saturating arithmetic**: Optional overflow handling that saturates to
  min/max values
- 🎯 **Type safe**: Strong typing with Result types for error handling
- 📦 **String convenience**: Helper functions for direct string parsing

## Installation

Add `justjavac/btoi` to your dependencies:

```bash
moon update
moon add justjavac/btoi
```

## Quick Start

```moonbit
// Parse basic integers from byte arrays
let result = @btoi.btoi(b"42".to_array())        // Ok(42)
let result = @btoi.btoi(b"-1000".to_array())     // Ok(-1000)
let result = @btoi.btou(b"42".to_array())        // Ok(42)

// Parse with different radix
let hex = @btoi.btou_radix(b"ff".to_array(), 16)  // Ok(255)
let bin = @btoi.btou_radix(b"101010".to_array(), 2) // Ok(42)

// Handle errors gracefully
match @btoi.btoi(b"not_a_number".to_array()) {
  Ok(value) => println("Parsed: \(value)")
  Err(InvalidDigit) => println("Invalid character found")
  Err(Empty) => println("Empty input")
  Err(PosOverflow) => println("Number too large")
  Err(NegOverflow) => println("Number too small")
}
```

## API Reference

### Core Parsing Functions

#### `btoi(bytes: Array[Byte]) -> Result[Int, ParseIntegerError]`

Parse a signed integer from byte array (base 10).

```moonbit
@btoi.btoi(b"42".to_array())   // Ok(42)
@btoi.btoi(b"-42".to_array())  // Ok(-42)
@btoi.btoi(b"+42".to_array())  // Ok(42)
```

#### `btou(bytes: Array[Byte]) -> Result[UInt, ParseIntegerError]`

Parse an unsigned integer from byte array (base 10).

```moonbit
@btoi.btou(b"42".to_array())          // Ok(42)
@btoi.btou(b"4294967295".to_array())  // Ok(@uint.max_value)
```

#### `btoi_radix(bytes: Array[Byte], radix: Int) -> Result[Int, ParseIntegerError]`

Parse a signed integer with specified radix (2-36).

```moonbit
@btoi.btoi_radix(b"ff".to_array(), 16)     // Ok(255)
@btoi.btoi_radix(b"-101010".to_array(), 2) // Ok(-42)
@btoi.btoi_radix(b"zz".to_array(), 36)     // Ok(1295)
```

#### `btou_radix(bytes: Array[Byte], radix: Int) -> Result[UInt, ParseIntegerError]`

Parse an unsigned integer with specified radix (2-36).

```moonbit
@btoi.btou_radix(b"FF".to_array(), 16)     // Ok(255)
@btoi.btou_radix(b"101010".to_array(), 2)  // Ok(42)
@btoi.btou_radix(b"777".to_array(), 8)     // Ok(511)
```

### Saturating Functions

These functions handle overflow by saturating to the maximum or minimum value
instead of returning an error.

#### `btoi_saturating(bytes: Array[Byte]) -> Result[Int, ParseIntegerError]`

Parse with saturating arithmetic (base 10).

```moonbit
// Large number saturates to max value
@btoi.btoi_saturating(b"9999999999".to_array()) // Ok(@int.max_value)

// Large negative number saturates to min value
@btoi.btoi_saturating(b"-9999999999".to_array()) // Ok(@int.min_value)
```

#### `btou_saturating(bytes: Array[Byte]) -> Result[UInt, ParseIntegerError]`

Parse unsigned integer with saturating arithmetic (base 10).

```moonbit
// Large number saturates to max value
@btoi.btou_saturating(b"9999999999".to_array()) // Ok(@uint.max_value)
```

#### `btoi_saturating_radix(bytes: Array[Byte], radix: Int) -> Result[Int, ParseIntegerError]`

#### `btou_saturating_radix(bytes: Array[Byte], radix: Int) -> Result[UInt, ParseIntegerError]`

Saturating versions with custom radix.

### String Convenience Functions

For when you have strings instead of byte arrays:

#### `btoi_from_string(s: String) -> Result[Int, ParseIntegerError]`

#### `btou_from_string(s: String) -> Result[UInt, ParseIntegerError]`

#### `btoi_radix_from_string(s: String, radix: Int) -> Result[Int, ParseIntegerError]`

#### `btou_radix_from_string(s: String, radix: Int) -> Result[UInt, ParseIntegerError]`

```moonbit
@btoi.btoi_from_string("42")        // Ok(42)
@btoi.btoi_radix_from_string("ff", 16) // Ok(255)
```

## Error Handling

The library defines a comprehensive error type:

```moonbit
pub enum ParseIntegerError {
  Empty          // Cannot parse integer without digits
  InvalidDigit   // Invalid digit found
  PosOverflow    // Integer too large to fit in target type
  NegOverflow    // Integer too small to fit in target type
}
```

### Error Examples

```moonbit
// Empty input
@btoi.btoi(b"".to_array())           // Err(Empty)
@btoi.btoi(b"-".to_array())          // Err(Empty) - sign only

// Invalid characters
@btoi.btoi(b"42x".to_array())        // Err(InvalidDigit)
@btoi.btou_radix(b"gg".to_array(), 16) // Err(InvalidDigit) - 'g' not valid in hex

// Overflow
@btoi.btou(b"4294967296".to_array()) // Err(PosOverflow) - exceeds UInt max
@btoi.btoi(b"-2147483649".to_array()) // Err(NegOverflow) - below Int min
```

## Supported Radix

All radix functions support bases from 2 to 36:

- **Digits 0-9** represent values 0-9
- **Letters a-z or A-Z** represent values 10-35 (case insensitive)

```moonbit
// Binary (base 2)
@btoi.btou_radix(b"1010".to_array(), 2)     // Ok(10)

// Octal (base 8)
@btoi.btou_radix(b"777".to_array(), 8)      // Ok(511)

// Hexadecimal (base 16)
@btoi.btou_radix(b"cafe".to_array(), 16)    // Ok(51966)
@btoi.btou_radix(b"CAFE".to_array(), 16)    // Ok(51966) - case insensitive

// Base 36 (maximum)
@btoi.btou_radix(b"zz".to_array(), 36)      // Ok(1295)
```

## Performance

This library is optimized for performance:

- **Zero-copy parsing**: Works directly with byte arrays
- **Overflow detection**: Efficient overflow checking during parsing
- **Branch-friendly**: Optimized control flow for modern CPUs
- **Memory efficient**: Minimal allocations

### When to Use

- Parsing integers from binary protocols
- Processing large amounts of numeric data
- Performance-critical applications
- When working with byte streams
- Custom number formats with different radix

## Examples

### Parsing HTTP Status Codes

```moonbit
fn parse_status_code(bytes : Array[Byte]) -> Result[Int, String] {
  match @btoi.btou(bytes) {
    Ok(code) => {
      if code >= 100 && code <= 599 {
        Ok(code.reinterpret_as_int())
      } else {
        Err("Invalid HTTP status code")
      }
    }
    Err(Empty) => Err("Empty status code")
    Err(InvalidDigit) => Err("Non-numeric character in status code")
    Err(_) => Err("Status code out of range")
  }
}
```

### Parsing IPv4 Addresses

```moonbit
fn parse_ipv4_octet(bytes : Array[Byte]) -> Result[Int, String] {
  match @btoi.btou(bytes) {
    Ok(octet) => {
      if octet <= 255 {
        Ok(octet.reinterpret_as_int())
      } else {
        Err("Octet value too large")
      }
    }
    Err(e) => Err("Invalid octet: \(e)")
  }
}
```

### Color Parsing

```moonbit
fn parse_hex_color(hex : String) -> Result[Int, String] {
  if hex.length() == 6 {
    match @btoi.btou_radix_from_string(hex, 16) {
      Ok(color) => Ok(color.reinterpret_as_int())
      Err(e) => Err("Invalid hex color: \(e)")
    }
  } else {
    Err("Hex color must be 6 characters")
  }
}

// Usage:
// parse_hex_color("ff0000") // Ok(16711680) - red
// parse_hex_color("00ff00") // Ok(65280)    - green  
// parse_hex_color("0000ff") // Ok(255)      - blue
```

## Testing

Run the test suite:

```bash
moon test
```

The library includes comprehensive tests covering:

- Basic parsing functionality
- All supported radix (2-36)
- Error conditions
- Edge cases and overflow behavior
- String convenience functions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

This library is inspired by the Rust [`btoi`](https://github.com/niklasf/rust-btoi)
crate, providing similar functionality for the MoonBit ecosystem.
