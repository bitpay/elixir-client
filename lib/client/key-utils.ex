defmodule Client.KeyUtils do
  require Integer

  def generate_pem do
    keys |>
    entity_from_keys |>
    der_encode_entity |>
    pem_encode_der
  end

  def get_sin_from_pem pem do
    version = compressed_public_key(pem) |> 
              set_version_type()
    (version <> write_checksum version) |>
    encode_base58
  end

  ####
  ## This section of code creates the pem file 
  ## Start create_pem
  defp keys, do: :crypto.generate_key(:ecdh, :secp256k1)

  defp entity_from_keys({public, private}) do
    private = :io_lib.format(private, [])
    {:ECPrivateKey, 1, private, {:namedCurve, {1, 3, 132, 0, 10}}, {0, public}}
  end

  defp der_encode_entity(ec_entity), do: :public_key.der_encode(:ECPrivateKey, ec_entity)  
  defp pem_encode_der(der_encoded), do: :public_key.pem_encode([{:ECPrivateKey, der_encoded, :not_encrypted}]) 
  ## End create_pem
  ####

  ####
  ## This section of code extracts the compressed public key from an ECPrivateKey entity
  ## Start compressed_public_key
  def compressed_public_key pem do
    [{_, dncoded, _}] = :public_key.pem_decode(pem)
    :public_key.der_decode(:ECPrivateKey, dncoded) |>
    extract_key_pair |>
    compress_key
  end

  defp extract_key_pair(ec_entity) do
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
  ## End compressed_public_key
  ####

  ####
  ## this section is concerned with creating the SIN
  defp set_version_type public_key do
    hash(public_key, :sha256) |> 
    hash(:ripemd160) |>
    (&("0F02" <> &1)).()
  end

  defp write_checksum version do
    hash(version, :sha256) |> 
    hash(:sha256) |>
    String.slice(0..7)
  end

  defp hash hex_val, encoding do
    decoded = Base.decode16(hex_val) |> elem(1)
    :crypto.hash(encoding, decoded) |> Base.encode16 
  end

  defp encode_base58 string do
    number = String.to_integer(string, 16)
    encode("", number, digit_list)
  end

  defp digit_list do
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz" |>
    String.split("") |>
    List.to_tuple
  end

  defp encode(output_string, number, list) when number <= 0, do: output_string

  defp encode(output_string, number, list) do
    elem(list, rem(number,58)) <> output_string |>
    encode(div(number, 58), list)
  end
  ## End of SIN section
  ####
end
