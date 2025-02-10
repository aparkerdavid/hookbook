defprotocol Hookbook.QueryParams.Encoding.Protocol do
  def encode(struct)
  def decode(struct, data)
end

defimpl Hookbook.QueryParams.Encoding.Protocol, for: Date do
  def encode(date), do: Date.to_iso8601(date)
  def decode(_, data), do: Date.from_iso8601!(data)
end

defimpl Hookbook.QueryParams.Encoding.Protocol, for: DateTime do
  def encode(datetime), do: DateTime.to_iso8601(datetime)

  def decode(_, data) do
    {:ok, datetime, _} = DateTime.from_iso8601(data)
    datetime
  end
end

defimpl Hookbook.QueryParams.Encoding.Protocol, for: Time do
  def encode(time), do: Time.to_iso8601(time)

  def decode(_, data) do
    {:ok, time} = Time.from_iso8601(data)
    time
  end
end

defimpl Hookbook.QueryParams.Encoding.Protocol, for: NaiveDateTime do
  def encode(naive_datetime), do: NaiveDateTime.to_iso8601(naive_datetime)

  def decode(_, data) do
    {:ok, naive_datetime} = NaiveDateTime.from_iso8601(data)
    naive_datetime
  end
end
