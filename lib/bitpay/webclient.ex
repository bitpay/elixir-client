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
  def pair_pos_client code, client do
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
    validate_price(params.price, params.currency) |>
    validate_currency(params.currency) |>
    check_tokens(params, webclient) |>
    create_invoice_with_valid_params(params, webclient)
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
    process_data response.body, response.status, response.success
  end

  @doc """
  Generic Get method to the WebClient endpoint.
  Input: 
    * the endpoint
    * params for the request
    * client making the request

    Response:
      an HTTPotion response object
  """
  def get path, webclient do
    uri = "#{webclient.uri}/#{path}"
    headers = signed_headers uri, webclient.pem
    HTTPotion.get uri, headers, []
  end

  defp pair_pos_client code, true, client do
    response = pair_with_server code, client 
    process_pairing response.body, response.status, response.success
  end

  defp pair_pos_client(_code, false, _client), do: {:error, "pairing code is not legal"}

  defp process_pairing body, _status, true do
    data = body.data |> List.first
    token = data.token
    facade = String.to_atom(data.facade)
    Dict.put(%{}, facade, token)
  end

  defp process_pairing(body, status, false), do: process_response(body, status, false)

  defp check_tokens({:error, message}, _, _), do: {:error, message}
  defp check_tokens({:ok, _}, params, webclient) do
    if params[:token] do
      {:ok, "token passed in"}
    else
      response = get("tokens", webclient) |> parse_response
      process_data(response.body, response.status, response.success) |>
      extract_token
    end
  end

  defp extract_token({:error, message}), do: {:error, message}
  defp extract_token({:ok, data}) do
    Enum.map(data, fn(item) -> item[:pos] || item[:merchant] end) |>
    Enum.filter(fn(i)->i end) |>
    select_token    
  end

  defp select_token([]), do: {:error, "no merchant or pos tokens on server"}
  defp select_token(tokens), do: {:ok, %{token: Enum.at(tokens, 0)}}

  defp create_invoice_with_valid_params({:ok, %{token: token}}, params, webclient) do
    params = Map.merge(params, %{token: token})
    create_invoice_with_valid_params({:ok, "token added to params"}, params, webclient)
  end

  defp create_invoice_with_valid_params({:ok, _}, params, webclient) do
    uri = webclient.uri <> "/invoices"
    body = JSX.encode(params) |> elem(1)
    response = post_to_server(uri, body, signed_headers(uri <> body, webclient.pem))
    process_data response.body, response.status, response.success
  end

  defp create_invoice_with_valid_params({:error, error}, _params, _webclient ), do: {:error, error}
  defp process_data(body, _status, true), do: {:ok, body.data}

  defp process_data(body, status, false), do: process_response(body, status, false)

  defp process_response body, status, false do
    message = body.error
    {:error, "#{status}: #{message}"}
  end

  defp pair_with_server code, webclient do
    uri = webclient.uri <> "/tokens"
    sin = KeyUtils.get_sin_from_pem(webclient.pem)
    body = JSX.encode(["pairingCode": code, "id": sin]) |>
           elem(1)
    post_to_server(uri, body, [])
  end

  defp post_to_server uri, body, headers do
    headers = Enum.concat(["content-type": "application/json", "accept": "application/json", "X-accept-version": "2.0.0"], headers)
    HTTPotion.post(uri, body, headers) |>
    parse_response
  end

  defp signed_headers message, pem do
    x_identity = KeyUtils.compressed_public_key pem
    x_signature = KeyUtils.sign(message, pem)
    [ "x-signature": x_signature, "x-identity": x_identity ]
  end

  defp parse_response response do
    success = HTTPotion.Response.success? response
    body = JSX.decode(response.body, [{:labels, :atom}]) |> elem(1)
    status = response.status_code
    %{status: status, body: body, success: success}
  end

  defp validate_price(price, _currency) when is_integer(price), do: {:ok, "price is valid"}
  defp validate_price(price, _currency) when is_float(price), do: {:ok, "price is valid"}
  defp validate_price(price, currency) when is_list(price), do: validate_price(List.to_string(price), currency)
  defp validate_price(price, "BTC") when is_binary(price), do: invoice_args_errors(price =~ ~r/^\d+(\.\d{1,8})?$/, true)
  defp validate_price(price, _currency) when is_binary(price), do: invoice_args_errors(price =~ ~r/^\d+(\.\d{1,2})?$/, true)

  defp validate_currency({:ok, message}, currency) when is_list(currency), do: validate_currency({:ok, message}, List.to_string(currency))
  defp validate_currency({:ok, _}, currency) when is_binary(currency), do: invoice_args_errors(true, currency =~ ~r/^\p{Lu}{3}$/)

  defp validate_currency({:error, message}, _), do: {:error, message}

  defp invoice_args_errors(true, true), do: {:ok, "no invoice argument error"}
  defp invoice_args_errors(false, _),  do: {:error, "Illegal Argument: Price must be formatted as a float"}
  defp invoice_args_errors(_, false), do: {:error, "Illegal Argument: Currency is invalid."}
end
