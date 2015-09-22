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
  initiates a 'client side' pairing.

  Input: a WebClient
  
  Response: `{:ok, <pairingCode> }`

  The pairingCode can then be used at /dashboard/merchant/api-tokens to authenticate the token
  """
  def get_pairing_code client do
    post("tokens", %{with_facade: :public}, client)
    |> process_data
    |> extract_pairing_code
  end

  def get_pairing_code client, facade do
    post("tokens", %{with_facade: :public, facade: facade}, client)
    |> process_data
    |> extract_pairing_code
  end

  defp extract_pairing_code({:error, message}), do: {:error, message}
  defp extract_pairing_code({:ok, data}), do: data |> List.first |> Access.get(:pairingCode) |> (&({:ok, &1})).()

  @doc """
  Sends a post request to the server that creates a new invoice.

  Input: 
    
   * a params map that must contain a price and a currency
   * a WebClient struct. The web client struct must be paired with BitPay.

  Response: A map corresponding to the data section of the JSON response from the server.
  """
  def create_invoice params, webclient do
    validate_price(params.price, params.currency)
    |> validate_currency(params.currency)
    |> post("invoices", params, webclient)
    |> process_data
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
    "#{webclient.uri}/invoices/#{id}"
    |> HTTPotion.get
    |> parse_response
    |> process_data
  end

  @doc """
  Generic Get method to the WebClient endpoint + path
  Input: 
    * the path (string)
    * params for the request (as map)
    * WebClient struct

    Response:
    a map containing the response code, successe status as true or false, and the body of the http response
  """
  def get path, webclient do
    uri = "#{webclient.uri}/#{path}"
    headers = signed_headers uri, webclient.pem
    headers = Enum.concat(["content-type": "application/json", "accept": "application/json", "X-accept-version": "2.0.0"], headers)
    HTTPotion.get( uri, headers, []) |>
    parse_response
  end

  @doc """
  Generic post method to the WebClient endpoint + path
  Input:
    * the path (string)
    * params for the request (as map)
    * WebClient struct
  
    Response:
    a map containing the response code, successe status as true or false, and the body of the http response
  """
  def post({:error, message}, _, _, _), do: {:error, message}
  def post({:ok, _}, path, params, webclient), do: post(path, params, webclient)
  def post path, params, webclient do
    check_tokens({:ok, "first in pipe"}, params, webclient)
    |> build_post(path, params, webclient)
    |> post_to_server
  end

  defp build_post({:ok, %{token: token}}, path, params, webclient) do
    params = Map.drop(params, [:with_facade]) |> Map.put(:token, token)
    build_post({:ok, "added token to params"}, path, params, webclient)
  end
  defp build_post({:ok, %{with_facade: :public}}, path, params, webclient) do
    params = Map.drop(params, [:with_facade])
    uri = "#{webclient.uri}/#{path}"
    body = params |> Map.put(:id, KeyUtils.get_sin_from_pem(webclient.pem)) |> JSX.encode!
    headers = []
    {:ok, %{uri: uri, body: body, headers: headers}}
  end
  defp build_post({:ok, _}, path, params, webclient) do
    uri = "#{webclient.uri}/#{path}"
    body = params |> Map.put(:id, KeyUtils.get_sin_from_pem(webclient.pem)) |> JSX.encode!
    headers = signed_headers uri <> body, webclient.pem
    {:ok, %{uri: uri, body: body, headers: headers}}
  end

  defp pair_pos_client(_code, false, _client), do: {:error, "pairing code is not legal"}
  defp pair_pos_client code, true, client do
    post("tokens", %{with_facade: :public, pairingCode: code}, client)
    |> process_data
    |> extract_facade
  end

  defp check_tokens({:error, message}, _, _), do: {:error, message}
  defp check_tokens({:ok, _}, %{token: _token}, _webclient), do: {:ok, "token passed in"}
  defp check_tokens({:ok, _}, %{with_facade: :public}, _webclient), do: {:ok, %{with_facade: :public}}
  defp check_tokens({:ok, _}, %{with_facade: facade}, webclient) do
    get_tokens_from_server(webclient) |>
    extract_token(facade)
  end
  defp check_tokens({:ok, _}, _params, webclient) do
    get_tokens_from_server(webclient) |>
    extract_token
  end

  defp get_tokens_from_server(webclient) do
    response = get("tokens", webclient)
    process_data(response.body, response.status, response.success)
  end

  defp extract_token({:error, message}), do: {:error, message}
  defp extract_token({:ok, data}) do
    Enum.map(data, fn(item) -> item[:pos] || item[:merchant] end)
    |> filter_token
  end
  defp extract_token({:ok, data}, facade) do
    Enum.map(data, fn(item) -> item[facade] end)
    |> filter_token
  end

  defp filter_token(tokens) do
    Enum.filter(tokens, fn(i)->i end)
    |> select_token
  end

  defp extract_facade({:error, message}), do: {:error, message}
  defp extract_facade({:ok, data}) do
    data = data |> List.first
    Dict.put(%{}, data.facade |> String.to_atom, data.token)
  end

  defp select_token([]), do: {:error, "no merchant or pos tokens on server"}
  defp select_token(tokens), do: {:ok, %{token: Enum.at(tokens, 0)}}

  defp process_data({:error, message}), do: {:error, message}
  defp process_data(%{body: body, status: status, success: success}), do: process_data(body, status, success)
  defp process_data(body, _status, true), do: {:ok, body.data}
  defp process_data(body, status, false), do: process_response(body, status, false)

  defp process_response body, status, false do
    message = body.error
    {:error, "#{status}: #{message}"}
  end

  defp post_to_server({:error, message}), do: {:error, message}
  defp post_to_server({:ok, %{uri: uri, body: body, headers: headers}}), do: post_to_server(uri, body, headers)
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
