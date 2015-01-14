defmodule BitPay.KeyUtils do
  require Integer

  @doc """
  generates a pem file
  """
  def generate_pem do
    keys |>
    entity_from_keys |>
    der_encode_entity |>
    pem_encode_der
  end

  @doc """
  creates a base58 encoded SIN from a pem file
  """
  def get_sin_from_pem pem do
    compressed_public_key(pem) |> 
    set_version_type |>
    (&(&1 <> write_checksum &1)).() |>
    encode_base58
  end

  @doc """
  retrieves the compressed public key from a pem file
  """
  def compressed_public_key pem do
    entity_from_pem(pem) |>
    extract_coordinates |>
    compress_key
  end

  @doc """
  retrieves the private key as a base16 string from the pem file
  """
  def private_key pem do
    entity_from_pem(pem) |>
    elem(2) |>
    :binary.list_to_bin |>
    Base.encode16
  end

  @doc """
  signs the input with the key retrieved from the pem file
  """
  def sign payload, pem do
    entity = :public_key.pem_decode(pem) |>
             List.first |>
             :public_key.pem_entry_decode
    :public_key.sign(payload, :sha256, entity) |>
             Base.encode16
  end

  defp keys, do: :crypto.generate_key(:ecdh, :secp256k1)

  defp entity_from_keys({public, private}) do
    {:ECPrivateKey, 
      1, 
      :binary.bin_to_list(private), 
      {:namedCurve, {1, 3, 132, 0, 10}}, 
      {0, public}}
  end

  defp der_encode_entity(ec_entity), do: :public_key.der_encode(:ECPrivateKey, ec_entity)  
  defp pem_encode_der(der_encoded), do: :public_key.pem_encode([{:ECPrivateKey, der_encoded, :not_encrypted}]) 

  defp entity_from_pem pem do
    [{_, dncoded, _}] = :public_key.pem_decode(pem)
    :public_key.der_decode(:ECPrivateKey, dncoded)
  end
    
  defp extract_coordinates(ec_entity) do
    elem(ec_entity, 4) |>
    elem(1) |>
    Base.encode16 |>
    split_x_y
  end

  defp split_x_y(uncompressed), do: {String.slice(uncompressed, 2..65), String.slice(uncompressed, 66..-1)}

  defp compress_key({x, y}) do
    convert_y_to_int({x, y}) |> 
    return_compressed_key
  end
  defp convert_y_to_int({x, y}), do: ({x, String.to_integer(y, 16)})
  defp return_compressed_key({x, y}) when Integer.is_even(y), do: "02#{x}"
  defp return_compressed_key({x, y}) when Integer.is_odd(y),  do: "03#{x}"

  defp set_version_type public_key do
    digest(public_key, :sha256) |> 
    digest(:ripemd160) |>
    (&("0F02" <> &1)).()
  end

  defp write_checksum version do
    digest(version, :sha256) |> 
    digest(:sha256) |>
    String.slice(0..7)
  end

  defp digest hex_val, encoding do
    Base.decode16(hex_val) |> 
    elem(1) |>
    (&(:crypto.hash(encoding, &1))).() |>
    Base.encode16
  end

  defp encode_base58 string do
    String.to_integer(string, 16) |>
    (&(encode("", &1, digit_list))).()
  end

  defp encode(output_string, number, _list) when number == 0, do: output_string
  defp encode(output_string, number, list) do
    elem(list, rem(number,58)) <> output_string |>
    encode(div(number, 58), list)
  end

  defp digit_list do
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz" |>
    String.split("") |>
    List.to_tuple
  end
end
