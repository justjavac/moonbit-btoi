# moonbit-btoi

Parse integers directly from ASCII byte arrays.

`justjavac/btoi` is a small MoonBit utility for reading signed and unsigned
integers from `Array[Byte]` without converting through `String` first. It also
supports radices `2..=36` and optional saturating overflow behavior.

## Install

```bash
moon add justjavac/btoi
```

## Quick Start

```mbt
assert_eq(@btoi.btoi(b"-42".to_array()), Ok(-42))
assert_eq(@btoi.btou_radix(b"ff".to_array(), 16), Ok(255))
assert_eq(@btoi.btoi_from_string("+17"), Ok(17))
```

## Error Values

- `Empty`: the input has no digits, including `""`, `"+"`, and `"-"`.
- `InvalidDigit`: at least one byte is not valid for the chosen radix.
- `PosOverflow`: the parsed value is too large for the target type.
- `NegOverflow`: the parsed signed value is too small for `Int`.

## Main APIs

- `btoi` / `btou`: parse base-10 bytes.
- `btoi_radix` / `btou_radix`: parse bytes in radix `2..=36`.
- `btoi_saturating` / `btou_saturating`: base-10 parsing with saturating overflow.
- `btoi_from_string` / `btou_from_string`: string convenience wrappers.

More examples live in the API doc comments in `src/btoi.mbt`.
