defmodule KeyUtilsTest do
  use ExUnit.Case
  alias Client.KeyUtils, as: KeyUtils

  @sin "TeyN4LPrXiG5t2yuSamKqP3ynVk3F52iHrX"
  @pem """
  -----BEGIN EC PRIVATE KEY-----
  MHQCAQEEICg7E4NN53YkaWuAwpoqjfAofjzKI7Jq1f532dX+0O6QoAcGBSuBBAAK
  oUQDQgAEjZcNa6Kdz6GQwXcUD9iJ+t1tJZCx7hpqBuJV2/IrQBfue8jh8H7Q/4vX
  fAArmNMaGotTpjdnymWlMfszzXJhlw==
  -----END EC PRIVATE KEY-----
  
  """
  test 'generate pem file generates a valid ec pem file' do
    pem = KeyUtils.generate_pem()
    assert Regex.match?(~r/BEGIN EC PRIVATE KEY.*\n.*\n.*\n.*\n.*END EC PRIVATE KEY/, pem) 
  end

  test 'get_sin_from_pem' do
    sin = KeyUtils.get_sin_from_pem @pem
    assert sin == @sin
  end
end
