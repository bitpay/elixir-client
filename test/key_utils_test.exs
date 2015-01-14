defmodule KeyUtilsTest do
  use ExUnit.Case
  alias BitPay.KeyUtils, as: KeyUtils

  @sin "TeyN4LPrXiG5t2yuSamKqP3ynVk3F52iHrX"
  @pem """
  -----BEGIN EC PRIVATE KEY-----
  MHQCAQEEICg7E4NN53YkaWuAwpoqjfAofjzKI7Jq1f532dX+0O6QoAcGBSuBBAAK
  oUQDQgAEjZcNa6Kdz6GQwXcUD9iJ+t1tJZCx7hpqBuJV2/IrQBfue8jh8H7Q/4vX
  fAArmNMaGotTpjdnymWlMfszzXJhlw==
  -----END EC PRIVATE KEY-----
  
  """

  @private_key "283B13834DE77624696B80C29A2A8DF0287E3CCA23B26AD5FE77D9D5FED0EE90"

  test 'generate pem file generates a valid ec pem file' do
    pem = KeyUtils.generate_pem()
    assert Regex.match?(~r/BEGIN EC PRIVATE KEY.*\n.*\n.*\n.*\n.*END EC PRIVATE KEY/, pem) 
  end

  test 'get_sin_from_pem' do
    sin = KeyUtils.get_sin_from_pem @pem
    assert sin == @sin
  end

  test 'get_private_key_from_pem' do
    assert KeyUtils.private_key(@pem) == @private_key
  end

  test 'sign' do
    signature_decoded = KeyUtils.sign("this land is your land", @pem) |> Base.decode16 |> elem(1)
    public_key = :public_key.pem_decode(@pem) |> List.first |> :public_key.pem_entry_decode |> elem(4) |> elem(1)
    verify = :crypto.verify(:ecdsa, :sha256, "this land is your land", signature_decoded, [public_key, :secp256k1])
    assert verify
  end
end
