defmodule UlidFlake.Scalable.Config do
  use Agent

  @default_epoch_sec 1704067200 # 2024-01-01 00:00:00 UTC
  @min_entropy_size 1
  @max_entropy_size 2
  @min_scalability_id 0
  @max_scalability_id 31

  def start_link(opts \\ []) do
    Agent.start_link(fn -> default_config(opts || []) end, name: __MODULE__)
  end

  defp default_config(opts) do
    epoch_time = Keyword.get(opts, :epoch_time, @default_epoch_sec)
    entropy_size = Keyword.get(opts, :entropy_size, @min_entropy_size)
    scalability_id = Keyword.get(opts, :scalability_id, @min_scalability_id)
    if DateTime.from_unix(epoch_time) == nil do
      raise ArgumentError, "Invalid epoch time"
    end
    if entropy_size < @min_entropy_size or entropy_size > @max_entropy_size do
      raise ArgumentError, "Invalid entropy size"
    end
    if scalability_id < @min_scalability_id or scalability_id > @max_scalability_id do
      raise ArgumentError, "Invalid scalability identifier"
    end
    %{
      epoch_time: DateTime.from_unix!(epoch_time), # Default epoch time (2024-01-01 00:00:00 UTC)
      entropy_size: entropy_size, # Default entropy size (1 byte)
      scalability_id: scalability_id, # Default scalability identifier (0)
    }
  end

  def set_epoch_time(epoch_time) do
    Agent.update(__MODULE__, fn state -> %{state | epoch_time: epoch_time} end)
  end

  def set_entropy_size(entropy_size) when entropy_size >= @min_entropy_size and entropy_size <= @max_entropy_size do
    Agent.update(__MODULE__, fn state -> %{state | entropy_size: entropy_size} end)
  end
  def set_entropy_size(_entropy_size) do
    {:error, :invalid_entropy_size}
  end

  def set_scalability_id(scalability_id) when scalability_id >= @min_scalability_id and scalability_id <= @max_scalability_id do
    Agent.update(__MODULE__, fn state -> %{state | scalability_id: scalability_id} end)
  end
  def set_scalability_id(_scalability_id) do
    {:error, :invalid_scalability_id}
  end

  def get_config do
    Agent.get(__MODULE__, & &1)
  end
end
