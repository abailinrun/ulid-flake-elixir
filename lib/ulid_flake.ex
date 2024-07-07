defmodule UlidFlake do
  import Bitwise
  use Agent

  @moduledoc """
  Ulid-Flake is a compact 64-bit ULID variant inspired by ULID and Twitter's Snowflake.
  """

  @default_epoch_sec 1704067200 # 2024-01-01 00:00:00 UTC

  @int_size 63
  @max_int (1 <<< @int_size) - 1

  @timestamp_size 43
  @min_timestamp 0
  @max_timestamp (1 <<< @timestamp_size) - 1

  @randomness_size 20
  @max_randomness (1 <<< @randomness_size) - 1

  @max_entropy_size 3

  @ulid_flake_len 13

  defstruct [:value]

  def start_link(opts) do
    UlidFlake.Config.start_link(opts)
    Agent.start_link(fn -> %{previous_timestamp: 0, previous_randomness: 0} end, name: __MODULE__)
  end

  @doc """
  Generates a new Ulid-Flake identifier.
  """
  def generate() do
    now = DateTime.utc_now()
    %{epoch_time: epoch_time, entropy_size: entropy_size} = UlidFlake.Config.get_config()

    case generate_timestamp(now, epoch_time) do
      {:error, :timestamp_overflow} = err -> err
      timestamp ->
      result =
        Agent.get_and_update(__MODULE__, fn state ->
          cond do
            timestamp < state.previous_timestamp ->
              {{:error, :invalid_timestamp}, state}

            timestamp == state.previous_timestamp ->
              entropy = generate_positive_entropy(entropy_size)
              new_randomness = state.previous_randomness + entropy
              if new_randomness > @max_randomness do
                {{:error, :overflow}, state}
              else
                combined = combine_to_64bit(timestamp, new_randomness)
                if combined > @max_int do
                  {{:error, :overflow}, state}
                else
                  new_state = %{state | previous_timestamp: timestamp, previous_randomness: new_randomness}
                  {{:ok, %UlidFlake{value: combined}}, new_state}
                end
              end

            true ->
              randomness = generate_randomness()
              new_state = %{state | previous_timestamp: timestamp, previous_randomness: randomness}
              combined = combine_to_64bit(timestamp, randomness)
              if combined > @max_int do
                {{:error, :overflow}, state}
              else
                {{:ok, %UlidFlake{value: combined}}, new_state}
              end
          end
        end)

      case result do
        {:ok, ulid_flake} -> {:ok, ulid_flake}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp generate_timestamp(now, epoch_time) do
    timestamp = DateTime.to_unix(now, :millisecond) - DateTime.to_unix(epoch_time, :millisecond)
    if timestamp < @min_timestamp or timestamp > @max_timestamp do
      {:error, :timestamp_overflow}
    else
      timestamp
    end
  end

  defp generate_randomness do
    :crypto.strong_rand_bytes(@max_entropy_size)
    |> :binary.decode_unsigned()
    |> rem(@max_randomness + 1)
  end

  defp generate_entropy(size) do
    :crypto.strong_rand_bytes(size)
    |> :binary.decode_unsigned()
  end
  defp generate_positive_entropy(size) do
    entropy = generate_entropy(size)
    if entropy > 0 do
      entropy
    else
      generate_positive_entropy(size)
    end
  end

  defp combine_to_64bit(timestamp, randomness) do
    sign_bit = 0
    (sign_bit <<< 63) ||| (timestamp <<< 20) ||| randomness
  end

  @doc """
  Returns the timestamp component of the Ulid-Flake identifier.
  """
  def timestamp(%UlidFlake{value: value}) do
    (value >>> 20) &&& @max_timestamp
  end

  @doc """
  Returns the randomness component of the Ulid-Flake identifier.
  """
  def randomness(%UlidFlake{value: value}) do
    value &&& @max_randomness
  end

  @doc """
  Returns the Base32 string representation of the Ulid-Flake identifier.
  """
  def to_base32(%UlidFlake{value: value}) do
    <<_sign_bit::size(1), timestamp::unsigned-size(43), randomness::unsigned-size(20)>> = <<value::signed-size(64)>>
    UlidFlake.Utils.encode(<<timestamp::unsigned-size(43), randomness::unsigned-size(20)>>)
  end

  @doc """
  Returns the Base32 string representation of the Ulid-Flake identifier.
  alias for `to_base32/1`
  """
  def to_string(%UlidFlake{value: value}) do
    to_base32(%UlidFlake{value: value})
  end

  @doc """
  Returns the integer representation of the Ulid-Flake identifier.
  """
  def to_integer(%UlidFlake{value: value}), do: value

  @doc """
  Returns the hexadecimal string representation of the Ulid-Flake identifier.
  """
  def to_hex(%UlidFlake{value: value}) do
    "0x" <> Integer.to_string(value, 16)
  end

  @doc """
  Returns the binary string representation of the Ulid-Flake identifier.
  """
  def to_bin(%UlidFlake{value: value}) do
    "0b" <> Integer.to_string(value, 2)
  end

  @doc """
  Parses a Base32-encoded Ulid-Flake identifier.
  """
  def parse(base32_string) when byte_size(base32_string) != @ulid_flake_len do
    {:error, :invalid_length}
  end
  def parse(base32_string) do
    case UlidFlake.Utils.decode(base32_string) do
      {:ok, value} ->
        if value < 0 or value > @max_int do
          {:error, :invalid_ulid}
        else
          {:ok, %UlidFlake{value: value}}
        end
      {:error, :invalid_character} -> {:error, :invalid_character}
      error -> error
    end
  end

  @doc """
  Creates a Ulid-Flake instance from a Base32 string.
  """
  def from_str(base32_string), do: parse(base32_string)

  @doc """
  Creates a Ulid-Flake instance from an integer.
  """
  def from_int(value) when value >= 0 and value <= @max_int do
    {:ok, %UlidFlake{value: value}}
  end
  def from_int(_value), do: {:error, :overflow}

  @doc """
  Creates a Ulid-Flake instance from a Unix epoch time in seconds.
  """
  def from_unix_epoch_time(unix_time_sec) when is_integer(unix_time_sec) do
    %{epoch_time: epoch_time} = UlidFlake.Config.get_config()
    min_unix_time_sec = (@min_timestamp + DateTime.to_unix(epoch_time) * 1000) / 1000
    max_unix_time_sec = (@max_timestamp + DateTime.to_unix(epoch_time) * 1000) / 1000
    if unix_time_sec < min_unix_time_sec or unix_time_sec > max_unix_time_sec do
      {:error, :overflow}
    else
      timestamp = (unix_time_sec * 1000) - (@default_epoch_sec * 1000)
      randomness = generate_randomness()
      combined = combine_to_64bit(timestamp, randomness)
      if combined > @max_int do
        {:error, :overflow}
      else
        {:ok, %UlidFlake{value: combined}}
      end
    end
  end
  def from_unix_epoch_time(_unix_time_sec), do: {:error, :invalid_time}
end
