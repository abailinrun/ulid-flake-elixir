defmodule UlidFlake.Utils do
  @encoding "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
  @encoding_map Enum.into(@encoding |> String.graphemes() |> Enum.with_index(), %{})

  def encode(<<timestamp::unsigned-size(43), randomness::unsigned-size(20)>>) do
    value = <<0::size(2), timestamp::unsigned-size(43), randomness::unsigned-size(20)>>
    encode_base32(value, <<>>)
  end
  defp encode_base32(<<index::unsigned-size(5), rest::bitstring>>, acc) do
    <<_::bytes-size(index), char::binary-size(1), _::binary>> = @encoding
    encode_base32(rest, acc <> char)
  end
  defp encode_base32(<<>>, acc), do: acc

  def decode(base32_string) do
    decode_base32(base32_string, 0)
  end
  defp decode_base32(<<>>, acc), do: {:ok, acc}
  defp decode_base32(<<char, rest::binary>>, acc) do
    case Map.fetch(@encoding_map, <<char>>) do
      {:ok, index} -> decode_base32(rest, acc * 32 + index)
      :error -> {:error, :invalid_character}
    end
  end
end
