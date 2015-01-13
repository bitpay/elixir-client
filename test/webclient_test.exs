defmodule WebClientTest do
  use ExUnit.Case, async: false
  alias BitPay.WebClient, as: WebClient
  import Mock

  test 'pairing short circuits with invalid code' do
    illegal_pairing_codes() |> Enum.each fn(item) -> 
      assert_raise BitPay.ArgumentError, "pairing code is not legal", fn() -> WebClient.pair_pos_client item end 
    end
  end

  test 'pairing handles errors gracefully' do
      with_mock HTTPotion, [post: fn("https://bitpay.com/tokens", _body, _headers) ->
                          %HTTPotion.Response{status_code: 403,
                                              body: "{\n  \"error\": \"this is a 403 error\"\n}"} end] do
      assert_raise BitPay.BitPayError, "403: this is a 403 error", fn() ->  WebClient.pair_pos_client "aBD3fhg" end
    end
  end

  defp illegal_pairing_codes do
    ["abcdefgh", "habcdefg", "abcd-fg"]
  end
end
