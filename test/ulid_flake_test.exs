defmodule UlidFlakeTest do
  import Bitwise
  use ExUnit.Case
  doctest UlidFlake

  setup do
    {:ok, pid} = UlidFlake.start_link(nil)
    on_exit(fn -> send(pid, :stop) end)
    :ok
  end

  test "generate a new Ulid-Flake" do
    {:ok, flake} = UlidFlake.generate()
    assert is_map(flake)
    assert flake.value >= 0
    assert String.length(UlidFlake.to_base32(flake)) == 13
    assert String.length(UlidFlake.to_hex(flake)) == 16
    assert String.length(UlidFlake.to_bin(flake)) >= 56
  end

  test "generate Ulid-Flake with entropy" do
    UlidFlake.Config.set_entropy_size(2)
    {:ok, flake} = UlidFlake.generate()
    assert is_map(flake)
    assert String.length(UlidFlake.to_base32(flake)) == 13
    assert String.length(UlidFlake.to_hex(flake)) == 16
    assert String.length(UlidFlake.to_bin(flake)) >= 56
  end

  test "generate Ulid-Flake with out of range entropy size" do
    assert {:error, :invalid_entropy_size} = UlidFlake.Config.set_entropy_size(0)
    assert {:error, :invalid_entropy_size} = UlidFlake.Config.set_entropy_size(4)
  end

  test "generate Ulid-Flake with large entropy" do
    UlidFlake.Config.set_entropy_size(3)
    overflow_occurred = Enum.any?(1..3, fn _ ->
      case UlidFlake.generate() do
        {:error, :overflow} -> true
        _ -> false
      end
    end)
    assert overflow_occurred
  end

  test "parse a valid Ulid-Flake" do
    {:ok, flake} = UlidFlake.generate()
    base32 = UlidFlake.to_base32(flake)
    {:ok, parsed_flake} = UlidFlake.parse(base32)
    assert flake == parsed_flake
    assert flake.value == parsed_flake.value
    assert UlidFlake.timestamp(flake) == UlidFlake.timestamp(parsed_flake)
    assert UlidFlake.randomness(flake) == UlidFlake.randomness(parsed_flake)
  end

  test "extract timestamp and randomness" do
    {:ok, flake} = UlidFlake.generate()
    timestamp = UlidFlake.timestamp(flake)
    randomness = UlidFlake.randomness(flake)
    assert timestamp >= 0
    assert randomness >= 0
  end

  test "fails to parse an invalid length Ulid-Flake string" do
    assert {:error, :invalid_length} = UlidFlake.parse("123456789012")
  end

  test "fails to parse an invalid character Ulid-Flake string" do
    assert {:error, :invalid_character} = UlidFlake.parse("invalid-chars")
  end

  test "convert Ulid-Flake to base32" do
    {:ok, flake} = UlidFlake.generate()
    base32 = UlidFlake.to_base32(flake)
    assert String.length(base32) == 13
  end

  test "convert Ulid-Flake to integer" do
    {:ok, flake} = UlidFlake.generate()
    int_value = UlidFlake.to_integer(flake)
    assert int_value == flake.value
  end

  test "convert Ulid-Flake to hex and binary" do
    {:ok, flake} = UlidFlake.generate()
    hex_value = UlidFlake.to_hex(flake)
    bin_value = UlidFlake.to_bin(flake)
    assert String.starts_with?(hex_value, "0x")
    assert String.starts_with?(bin_value, "0b")
  end

  test "returns various representations" do
    {:ok, flake} = UlidFlake.generate()

    base32 = UlidFlake.to_base32(flake)
    integer = UlidFlake.to_integer(flake)
    timestamp = UlidFlake.timestamp(flake)
    randomness = UlidFlake.randomness(flake)
    hex = UlidFlake.to_hex(flake)
    bin = UlidFlake.to_bin(flake)

    IO.puts("\nUlid-Flake:")
    IO.puts("Base32: #{base32}")
    IO.puts("Integer: #{integer}")
    IO.puts("Timestamp: #{timestamp}")
    IO.puts("Randomness: #{randomness}")
    IO.puts("Hex: #{hex}")
    IO.puts("Binary: #{bin}")

    assert is_binary(base32)
    assert is_integer(integer)
    assert is_integer(timestamp)
    assert is_integer(randomness)
    assert is_binary(hex)
    assert is_binary(bin)
  end

  test "instantiate Ulid-Flake with int value" do
    {:ok, flake} = UlidFlake.from_int(0)
    assert flake.value == 0

    {:ok, flake} = UlidFlake.from_int(1)
    assert flake.value == 1

    {:ok, flake} = UlidFlake.from_int(9223372036854775807)
    assert flake.value == 9223372036854775807
  end

  test "instantiate Ulid-Flake with out of range int value" do
    assert {:error, :overflow} = UlidFlake.from_int(-1)
    assert {:error, :overflow} = UlidFlake.from_int(9223372036854775808)
  end

  test "parse Ulid-Flake with invalid base32" do
    assert {:error, :invalid_character} = UlidFlake.parse("invalid-flake")
    assert {:error, :invalid_character} = UlidFlake.parse("00CMH8K1E1E1I")
    assert {:error, :invalid_character} = UlidFlake.parse("00CMH8K1E1E1L")
    assert {:error, :invalid_character} = UlidFlake.parse("00CMH8K1E1E1O")
    assert {:error, :invalid_character} = UlidFlake.parse("00CMH8K1E1E1U")
    assert {:error, :invalid_length} = UlidFlake.parse("invalid-char")
    assert {:error, :invalid_length} = UlidFlake.parse("00CMH8K1E")
    assert {:error, :invalid_length} = UlidFlake.parse("00CMH8K1E1E1E2")
    assert {:error, :invalid_ulid} = UlidFlake.parse("8000000000000")
  end

  test "monotonically increasing Ulid-Flake" do
    {:ok, initial_flake} = UlidFlake.generate()
    new_flakes = Enum.map(1..10, fn _ -> UlidFlake.generate() end)
    Enum.reduce(new_flakes, initial_flake, fn {:ok, new_flake}, last_flake ->
      assert new_flake.value > last_flake.value
      new_flake
    end)
  end

  test "create Ulid-Flake from integer" do
    {:ok, flake} = UlidFlake.generate()
    int_value = UlidFlake.to_integer(flake)
    {:ok, flake_from_int} = UlidFlake.from_int(int_value)
    assert flake.value == flake_from_int.value
    assert UlidFlake.timestamp(flake) == UlidFlake.timestamp(flake_from_int)
    assert UlidFlake.randomness(flake) == UlidFlake.randomness(flake_from_int)
  end

  test "create Ulid-Flake from integer with out of range value" do
    assert {:error, :overflow} = UlidFlake.from_int(-1)
    assert {:error, :overflow} = UlidFlake.from_int(9223372036854775808)
  end

  test "create Ulid-Flake from string" do
    {:ok, flake} = UlidFlake.generate()
    base32 = UlidFlake.to_base32(flake)
    {:ok, flake_from_str} = UlidFlake.from_str(base32)
    assert flake.value == flake_from_str.value
    assert UlidFlake.timestamp(flake) == UlidFlake.timestamp(flake_from_str)
    assert UlidFlake.randomness(flake) == UlidFlake.randomness(flake_from_str)
  end

  test "create Ulid-Flake from Unix epoch time" do
    custom_epoch = ~U[2024-01-01 00:00:00Z]
    {:ok, flake} = UlidFlake.generate()
    ulid_flake_timestamp = UlidFlake.timestamp(flake)
    unix_timestamp = DateTime.to_unix(custom_epoch) + div(ulid_flake_timestamp, 1000)
    {:ok, flake_from_unix_epoch} = UlidFlake.from_unix_epoch_time(unix_timestamp)
    assert_in_delta UlidFlake.timestamp(flake), UlidFlake.timestamp(flake_from_unix_epoch), 1000
    assert UlidFlake.randomness(flake) != UlidFlake.randomness(flake_from_unix_epoch)
  end

  test "create Ulid-Flake from Unix epoch time before custom epoch" do
    custom_epoch = ~U[2024-01-01 00:00:00Z]
    {:ok, flake} = UlidFlake.generate()
    ulid_flake_timestamp = UlidFlake.timestamp(flake)
    unix_timestamp = DateTime.to_unix(custom_epoch) - div(ulid_flake_timestamp, 1000)
    assert {:error, :overflow} = UlidFlake.from_unix_epoch_time(unix_timestamp)
  end

  test "create Ulid-Flake from Unix epoch time after max timestamp" do
    max_timestamp = (1 <<< 43) - 1
    custom_epoch = ~U[2024-01-01 00:00:00Z]
    unix_timestamp = DateTime.to_unix(custom_epoch) + div(max_timestamp, 1000)
    assert {:error, :overflow} = UlidFlake.from_unix_epoch_time(unix_timestamp+1)
  end

  test "create Ulid-Flake from Unix epoch time with invalid Unix time" do
    assert {:error, :invalid_time} = UlidFlake.from_unix_epoch_time("invalid-time")
  end
end
