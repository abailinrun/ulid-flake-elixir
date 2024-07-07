<h1 align="left">
	<img width="240" src="https://raw.githubusercontent.com/ulid-flake/spec/main/logo.png" alt="ulid-flake">
</h1>

# Ulid-Flake, A 64-bit ULID variant featuring Snowflake - the elixir implementation

Ulid-Flake is a compact `64-bit` ULID (Universally Unique Lexicographically Sortable Identifier) variant inspired by ULID and Twitter's Snowflake. It features a 1-bit sign bit, a 43-bit timestamp, and a 20-bit randomness. Additionally, it offers a scalable version using the last 5 bits as a scalability identifier (e.g., machineID, podID, nodeID).

herein is proposed Ulid-Flake:

```elixir
{:ok, new_flake} = UlidFlake.generate() # 14246757444195114
UlidFlake.to_string(new_flake) # 00CMXB6TAK4SA
```

## Features

- **Compact and Efficient**: Uses only 64 bits, making it compatible with common integer types like `int64` and `bigint`.
- **Scalability**: Provides 32 configurations for scalability using a distributed system.
- **Lexicographically Sortable**: Ensures lexicographical order.
- **Canonical Encoding**: Encoded as a 13-character string using Crockford's Base32.
- **Monotonicity and Randomness**: Monotonic sort order within the same millisecond with enhanced randomness to prevent predictability.

## Installation

This package can be installed by adding `ulid_flake` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ulid_flake, "~> 1.0.0"}
  ]
end
```

## Documentation

[HexDocs](https://hexdocs.pm/ulid_flake)

## Basic Usage

### Erlang/OTP

```sh
iex -S mix

iex(1)> {:ok, _} = UlidFlake.start_link(nil)
{:ok, #PID<0.174.0>}
iex(2)> {:ok, flakeID} = UlidFlake.generate()
{:ok, %UlidFlake{value: 17089122411459096}}
iex(3)> UlidFlake.to_string(flakeID)
"00F5PEXFDQCGR"
```

### Import

```elixir
Import UlidFlake

# Start the Ulid-Flake process
{:ok, _} = UlidFlake.start_link(nil)

# Configure settings for stand-alone version
UlidFlake.Config.set_epoch_time(~U[2024-01-01 00:00:00Z]) # Custom epoch time, default 2024-01-01
UlidFlake.Config.set_entropy_size(2) # Custom entropy size, 1, 2 or 3, default 1

# Configure settings for scalable version
UlidFlake.Scalable.Config.set_epoch_time(~U[2024-01-01 00:00:00Z]) # Custom epoch time, default 2024-01-01
UlidFlake.Scalable.Config.set_entropy_size(2) # Custom entropy size, 1, 2 or 3, default 1
UlidFlake.Scalable.Config.set_scalability_size(4) # Custom scalability ID (e.g., machineID, podID, nodeID), 1~32, default 0

# Generate a new Ulid-Flake instance
{:ok, new_flake} = UlidFlake.generate()
IO.puts("Base32: #{UlidFlake.to_base32(new_flake)}")
IO.puts("Integer: #{UlidFlake.to_integer(new_flake)}")
IO.puts("Timestamp: #{UlidFlake.timestamp(new_flake)}")
IO.puts("Randomness: #{UlidFlake.randomness(new_flake)}")
IO.puts("Hex: #{UlidFlake.to_hex(new_flake)}")
IO.puts("Binary: #{UlidFlake.to_bin(new_flake)}")
# Base32:     00F2N078MDT7J
# Integer:    16981964897052914
# Timestamp:  16195263764
# Randomness: 452850
# Hex:        0x3C5501D146E8F2
# Bin:        0b111100010101010000000111010001010001101110100011110010
```

## Monotonicity Testing

Stand-alone version:

```elixir
Enum.map(1..5, fn _ ->
  {:ok, new_flake} = UlidFlake.generate()
  IO.puts("Base32: #{UlidFlake.to_base32(new_flake)}")
  IO.puts("Integer: #{UlidFlake.to_integer(new_flake)}")
  IO.puts("Timestamp: #{UlidFlake.timestamp(new_flake)}")
  IO.puts("Randomness: #{UlidFlake.randomness(new_flake)}")
  IO.puts("Hex: #{UlidFlake.to_hex(new_flake)}")
  IO.puts("Binary: #{UlidFlake.to_bin(new_flake)}")
  {:ok, new_flake}
end)

# Base32: 00F5MFHSEYXCM
# Integer: 17086945199879572
# Timestamp: 16295380782
# Randomness: 1013140
# Hex: 0x3CB47C72EF7594
# Binary: 0b111100101101000111110001110010111011110111010110010100

# Base32: 00F5MFHSEYXHB
# Integer: 17086945199879723
# Timestamp: 16295380782
# Randomness: 1013291
# Hex: 0x3CB47C72EF762B
# Binary: 0b111100101101000111110001110010111011110111011000101011

# Base32: 00F5MFHSFPCE0
# Integer: 17086945200648640
# Timestamp: 16295380783
# Randomness: 733632
# Hex: 0x3CB47C72FB31C0
# Binary: 0b111100101101000111110001110010111110110011000111000000

# Base32: 00F5MFHSFPCNY
# Integer: 17086945200648894
# Timestamp: 16295380783
# Randomness: 733886
# Hex: 0x3CB47C72FB32BE
# Binary: 0b111100101101000111110001110010111110110011001010111110

# Base32: 00F5MFHSFPCRA
# Integer: 17086945200648970
# Timestamp: 16295380783
# Randomness: 733962
# Hex: 0x3CB47C72FB330A
# Binary: 0b111100101101000111110001110010111110110011001100001010
```

scalable version:

```elixir
Enum.map(1..5, fn _ ->
  {:ok, new_flake} = UlidFlake.Scalable.generate()
  IO.puts("")
  IO.puts("Base32: #{UlidFlake.Scalable.to_base32(new_flake)}")
  IO.puts("Integer: #{UlidFlake.Scalable.to_integer(new_flake)}")
  IO.puts("Timestamp: #{UlidFlake.Scalable.timestamp(new_flake)}")
  IO.puts("Randomness: #{UlidFlake.Scalable.randomness(new_flake)}")
  IO.puts("Hex: #{UlidFlake.Scalable.to_hex(new_flake)}")
  IO.puts("Binary: #{UlidFlake.Scalable.to_bin(new_flake)}")
  {:ok, new_flake}
end)

# Base32: 00F5MN1MCFT30
# Integer: 17087134008076384
# Timestamp: 16295560844
# Randomness: 16195
# Hex: 0x3CB4A868C7E860
# Binary: 0b111100101101001010100001101000110001111110100001100000

# Base32: 00F5MN1MCFVP0
# Integer: 17087134008078016
# Timestamp: 16295560844
# Randomness: 16246
# Hex: 0x3CB4A868C7EEC0
# Binary: 0b111100101101001010100001101000110001111110111011000000

# Base32: 00F5MN1MCFXA0
# Integer: 17087134008079680
# Timestamp: 16295560844
# Randomness: 16298
# Hex: 0x3CB4A868C7F540
# Binary: 0b111100101101001010100001101000110001111111010101000000

# Base32: 00F5MN1MCG0H0
# Integer: 17087134008082976
# Timestamp: 16295560844
# Randomness: 16401
# Hex: 0x3CB4A868C80220
# Binary: 0b111100101101001010100001101000110010000000001000100000

# Base32: 00F5MN1MCG5K0
# Integer: 17087134008088160
# Timestamp: 16295560844
# Randomness: 16563
# Hex: 0x3CB4A868C81660
# Binary: 0b111100101101001010100001101000110010000001011001100000
```

## Creating Ulid-Flake Instances from other sources

### From Integer

```elixir
{:ok, ulid_flake} := UlidFlake.from_int(1234567890123456789)
fmt.Printf("From Int: %s\n", UlidFlake.to_string(ulid_flake))
```

### From Base32 String

```elixir
{:ok, ulid_flake} := UlidFlake.from_str("01AN4Z07BY79K")
fmt.Printf("From String: %s\n", UlidFlake.to_string(ulid_flake))
```

### From Unix Epoch Time

```elixir
{:ok, ulid_flake} := UlidFlake.from_unix_epoch_time(1672531200)
fmt.Printf("From Unix Time: %s\n", UlidFlake.to_string(ulid_flake))
```

## Specification

Below is the default stand-alone version specification of Ulid-Flake.

<img width="600" alt="ulid-flake-stand-alone" src="https://github.com/ulid-flake/spec/assets/38312944/37d44c3f-1937-4c2e-b7ec-e7c0f0debe25">

*Note: a `1-bit` sign bit is included in the timestamp.*

```text
Stand-alone version (default):

 00CMXB6TA      K4SA

|---------|    |----|
 Timestamp   Randomness
   44-bit      20-bit
   9-char      4-char
```

Also, a scalable version is provided for distributed system using purpose.

<img width="600" alt="ulid-flake-scalable" src="https://github.com/ulid-flake/spec/assets/38312944/e306ebd9-9406-436f-b6cd-a1004745f1b0">

*Note: a `1-bit` sign bit is included in the timestamp.*

```
Scalable version (optional):

 00CMXB6TA      K4S       A

|---------|    |---|     |-|
 Timestamp   Randomness  Scalability
   44-bit      15-bit    5-bit
   9-char      3-char    1-char
```

### Components

Total `64-bit` size for compatibility with common integer (`long int`, `int64` or `bigint`) types.

**Timestamp**
- The first `1-bit` is a sign bit, always set to 0.
- Remaining `43-bit` timestamp in millisecond precision.
- Custom epoch for extended usage span, starting from `2024-01-01T00:00:00.000Z`.
- Usable until approximately `2302-09-27` AD.

**Randomness**
- `20-bit` randomness for stand-alone version. Provides a collision resistance with a p=0.5 expectation of 1,024 trials. (not much)
- `15-bit` randomness for scalable version.
- Initial random value at each millisecond precision unit.
- adopt a `+n` bits entropy incremental mechanism to ensure uniqueness without predictability.

**Scalability (Scalable version ony)**
- Provide a `5-bit` scalability for distributed system using purpose.
- total 32 configurations can be used.

### Sorting

The left-most character must be sorted first, and the right-most character sorted last, ensuring lexicographical order.
The default ASCII character set must be used.

When using the stand-alone version strictly in a stand-alone environment, or using the scalable version in both stand-alone or distributed environment, sort order is guaranteed within the same millisecond. however, when using the stand-alone version in a distributed system, sort order is not guaranteed within the same millisecond.

*Note: within the same millisecond, sort order is guaranteed in the context of an overflow error could occur.*

### Canonical String Representation

```text
Stand-alone version (default):

tttttttttrrrr

where
t is Timestamp (9 characters)
r is Randomness (4 characters)
```

```text
Scalable version (optional):

tttttttttrrrs

where
t is Timestamp (9 characters)
r is Randomness (3 characters)
s is Scalability (1 characters)
```

#### Encoding

Crockford's Base32 is used as shown. This alphabet excludes the letters I, L, O, and U to avoid confusion and abuse.

```
0123456789ABCDEFGHJKMNPQRSTVWXYZ
```

### Optional Long Int Representation

```text
1234567890123456789

(with a maximum 13-character length in string format)
```

### Monotonicity and Overflow Error Handling

#### Randomness

When generating a Ulid-Flake within the same millisecond, the `randomness` component is incremented by a `n-bit` entropy in the least significant bit position (with carrying).
Thus, comparing just incremented `1-bit` one time, the incremented `n-bit` mechanism cloud lead to an overflow error sooner.

when the generation is failed with overflow error, it should be properly handled in the application to wait and create a new one till the next millisecond is coming. The implementation of Ulid-Flake should just return the overflow error, and leave the rest to the application.

#### Timestamp and Over All

Technically, a `13-character` Base32 encoded string can contain 65 bits of information, whereas a Ulid-Flake must only contain 64 bits. Further more, there is a `1-bit` sign bit at the beginning, only 63 bits are actually carrying effective information. Therefore, the largest valid Ulid-Flake encoded in Base32 is `7ZZZZZZZZZZZZ`, which corresponds to an epoch time of `8,796,093,022,207` or `2^43 - 1`.

Any attempt to decode or encode a Ulid-Flake larger than this should be rejected by all implementations and return an overflow error, to prevent overflow bugs.

### Binary Layout and Byte Order

The components are encoded as 16 octets. Each component is encoded with the Most Significant Byte first (network byte order).

```
Stand-alone version (default):

 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      32_bit_int_time_high                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| 12_bit_uint_time_low  |          20_bit_uint_random           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

```
Scalable version (optional):

 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      32_bit_int_time_high                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| 12_bit_uint_time_low  |      15_bit_uint_random     | 5_bit_s |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

# Contributing
We welcome contributions! Please see our CONTRIBUTING.md for guidelines on how to get involved.

# License
This project is licensed under the MIT License. See the LICENSE file for details.

# Acknowledgments

[ULID](https://github.com/ulid/spec)

[Twitter's Snowflake](https://blog.x.com/engineering/en_us/a/2010/announcing-snowflake)

```
██╗░░░██╗██╗░░░░░██╗██████╗░░░░░░░███████╗██╗░░░░░░█████╗░██╗░░██╗███████╗
██║░░░██║██║░░░░░██║██╔══██╗░░░░░░██╔════╝██║░░░░░██╔══██╗██║░██╔╝██╔════╝
██║░░░██║██║░░░░░██║██║░░██║█████╗█████╗░░██║░░░░░███████║█████═╝░█████╗░░
██║░░░██║██║░░░░░██║██║░░██║╚════╝██╔══╝░░██║░░░░░██╔══██║██╔═██╗░██╔══╝░░
╚██████╔╝███████╗██║██████╔╝░░░░░░██║░░░░░███████╗██║░░██║██║░╚██╗███████╗
░╚═════╝░╚══════╝╚═╝╚═════╝░░░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝
```
