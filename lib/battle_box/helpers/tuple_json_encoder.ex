defimpl Jason.Encoder, for: [Tuple] do
  def encode(struct, opts) do
    Jason.Encode.list(Tuple.to_list(struct), opts)
  end
end
