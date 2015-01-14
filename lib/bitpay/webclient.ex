defmodule BitPay.WebClient do
  require IEx
  alias BitPay.KeyUtils, as: KeyUtils
  defstruct uri: "https://bitpay.com", pem: KeyUtils.generate_pem

  def pair_pos_client code, client \\ %BitPay.WebClient{} do
    pair_pos_client code, (code =~ ~r/^\p{Xan}{7}$/), client
  end

  defp pair_pos_client code, true, client do
    response = pair_with_server code, client 
    success = HTTPotion.Response.success? response
    process_pairing response.body, response.status_code, response.headers, success
  end

  defp pair_pos_client(_code, false, _client),
    do: raise(BitPay.ArgumentError, message: "pairing code is not legal")

  defp process_pairing body, _status, _headers, true do
    data = (JSX.decode(body) |> 
           elem(1))["data"] |> 
           List.first
    token = data["token"]
    facade = String.to_atom(data["facade"])
    Dict.put(%{}, facade, token)
  end

  defp process_pairing body, status, _headers, false do   
    message = (JSX.decode(body) |> elem(1))["error"]
    raise BitPay.BitPayError, message: "#{status}: #{message}"
  end

  defp pair_with_server code, webclient do
    uri = webclient.uri <> "/tokens"
    sin = KeyUtils.get_sin_from_pem(webclient.pem)
    body = JSX.encode(["pairingCode": code, "id": sin]) |>
           elem(1)
    HTTPotion.post(uri, body, ["content-type": "application/json", "accept": "application/json", "X-accept-version": "2.0.0"])
  end
end
