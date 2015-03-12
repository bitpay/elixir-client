defmodule BitPay.WebClient do
  @moduledoc """
  Convenience methods for the BitPay REST API.
  """
  require IEx
  alias BitPay.KeyUtils, as: KeyUtils
  @doc """
  The module struct contains two fields:

    - uri: the api uri, which defaults to https://bitpay.com
    - pem: a pem file containing the public and private keys, which can be generated from the BitPay.KeyUtils module.
  """
  defstruct uri: "https://bitpay.com", pem: KeyUtils.generate_pem

  @doc """
  creates a token on the server corresponding to the WebClients public and private keys

  Input:

    * a pairing code from the server
    * a WebClient

  Response: a key/value pair such as `%{pos: 92hgkeit92392gjgj}`
  """
  def pair_pos_client code, client \\ %BitPay.WebClient{} do
    pair_pos_client code, (code =~ ~r/^\p{Xan}{7}$/), client
  end

  @doc """
  Sends a post request to the server that creates a new invoice.

  Input: 
    
   * a params map that must contain a price and a currency
   * a WebClient struct. The web client struct must be paired with BitPay.

  Response: A map corresponding to the data section of the JSON response from the server.
  """
  def create_invoice params, webclient do
    validate_invoice_args params.price, params.currency
    uri = webclient.uri <> "/invoices"
    body = JSX.encode(params) |> elem(1)
    x_identity = KeyUtils.compressed_public_key webclient.pem
    x_signature = KeyUtils.sign(uri <> body, webclient.pem)
    response = post_to_server(uri, body, ["content-type": "application/json", "accept": "application/json", "X-accept-version": "2.0.0", "x-identity": x_identity, "x-signature": x_signature ])
    process_invoice response.body, response.status, response.success
  end

  @doc """
  Retrieves an invoice from the BitPay server.

  Input:

    * an invoice id
    * a WebClient

  Response:
    a map corresponding to the data section of the JSON response from the server.
  """
  def get_invoice(id, webclient) do
    uri = webclient.uri <> "/invoices/" <> id
    response = HTTPotion.get(uri) |>
               parse_response
    process_invoice response.body, response.status, response.success
  end

  defp pair_pos_client code, true, client do
    response = pair_with_server code, client 
    process_pairing response.body, response.status, response.success
  end

  defp pair_pos_client(_code, false, _client),
    do: raise(BitPay.ArgumentError, message: "pairing code is not legal")

  defp process_pairing body, _status, true do
    data = body.data |> List.first
    token = data.token
    facade = String.to_atom(data.facade)
    Dict.put(%{}, facade, token)
  end

  defp process_pairing(body, status, false), do: process_response(body, status, false)

  defp process_invoice(body, _status, true), do: body.data

  defp process_invoice(body, status, false), do: process_response(body, status, false)

  defp process_response body, status, false do
    message = body.error
    raise BitPay.BitPayError, message: "#{status}: #{message}"
  end

  defp pair_with_server code, webclient do
    uri = webclient.uri <> "/tokens"
    sin = KeyUtils.get_sin_from_pem(webclient.pem)
    body = JSX.encode(["pairingCode": code, "id": sin]) |>
           elem(1)
    post_to_server(uri, body, ["content-type": "application/json", "accept": "application/json", "X-accept-version": "2.0.0"])
  end

  defp post_to_server uri, body, headers do
    HTTPotion.post(uri, body, headers) |>
    parse_response
  end

  defp parse_response response do
    success = HTTPotion.Response.success? response
    body = JSX.decode(response.body, [{:labels, :atom}]) |> elem(1)
    status = response.status_code
    %{status: status, body: body, success: success}
  end

  defp validate_invoice_args(price, currency) do
    price_correct = is_integer(price) || is_float(price) || (is_binary(price) && price =~ ~r/^\d+(\.\d\d)?$/) || (is_list(price) && List.to_string(price) =~ ~r/^\d+(\.\d\d)?$/)
    currency_correct = currency =~ ~r/^\p{Lu}{3}$/
    invoice_args_errors(price_correct, currency_correct)
  end

  defp invoice_args_errors(false, _),  do: raise(BitPay.ArgumentError, message: "Illegal Argument: Price must be formatted as a float")
  defp invoice_args_errors(_, false), do: raise(BitPay.ArgumentError, message: "Illegal Argument: Currency is invalid.")
  defp invoice_args_errors(_, _), do: true

end
