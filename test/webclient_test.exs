defmodule WebClientTest do
  use ExUnit.Case, async: false
  alias BitPay.WebClient, as: WebClient
  import Mock

  test 'post method does not try to get token if public facade input' do
    client = %WebClient{}
    with_mock HTTPotion, [post: fn("https://bitpay.com/testpoint", _body,  _headers) -> %HTTPotion.Response{status_code: 200, body: "{\"data\":[{\"policies\":[{\"policy\":\"id\",\"method\":\"unclaimed\",\"params\":[]}],\"resource\":\"4e2rQDFK6Y1X4eU5ugw8AYy9FFih6jRicv6dxeccgS8r\",\"token\":\"BHMA5LMxUdEvePuAaEPmuW5tPYbGpw65jirDHzbXLfkt\",\"facade\":\"pos\",\"dateCreated\":1440003119142,\"pairingExpiration\":1440089519142,\"pairingCode\":\"8GSQvjb\"}]}" } end] do
      response = WebClient.post("testpoint", %{with_facade: :public}, client)
      assert response.body.data |> List.first |> Access.get(:token) == "BHMA5LMxUdEvePuAaEPmuW5tPYbGpw65jirDHzbXLfkt"
    end
  end

  test 'get_pairing_code makes a public call to the tokens endpoint' do
    client = %WebClient{}
    with_mock HTTPotion, [post: fn("https://bitpay.com/tokens", _body,  _headers) -> %HTTPotion.Response{status_code: 200, body: "{\"data\":[{\"policies\":[{\"policy\":\"id\",\"method\":\"unclaimed\",\"params\":[]}],\"resource\":\"4e2rQDFK6Y1X4eU5ugw8AYy9FFih6jRicv6dxeccgS8r\",\"token\":\"BHMA5LMxUdEvePuAaEPmuW5tPYbGpw65jirDHzbXLfkt\",\"facade\":\"pos\",\"dateCreated\":1440003119142,\"pairingExpiration\":1440089519142,\"pairingCode\":\"8GSQvjb\"}]}" } end] do
      {:ok, pairingCode} = WebClient.get_pairing_code(client)
      assert pairingCode == "8GSQvjb"
    end
  end

  test 'get_pairing_code accepts "merchant" or "pos" arguments' do
    client = %WebClient{}
    with_mock HTTPotion, [post: fn("https://bitpay.com/tokens", _body,  _headers) -> %HTTPotion.Response{status_code: 200, body: "{\"data\":[{\"policies\":[{\"policy\":\"id\",\"method\":\"unclaimed\",\"params\":[]}],\"resource\":\"4e2rQDFK6Y1X4eU5ugw8AYy9FFih6jRicv6dxeccgS8r\",\"token\":\"BHMA5LMxUdEvePuAaEPmuW5tPYbGpw65jirDHzbXLfkt\",\"facade\":\"pos\",\"dateCreated\":1440003119142,\"pairingExpiration\":1440089519142,\"pairingCode\":\"8GSQvjb\"}]}" } end] do
      {:ok, pairingCode} = WebClient.get_pairing_code(client, :merchant)
      assert pairingCode == "8GSQvjb"
    end
  end
  test 'post method gets specified token if input' do
    client = %WebClient{}
    with_mock HTTPotion, [get: fn("https://bitpay.com/tokens", _body, _headers) -> %HTTPotion.Response{status_code: 228, body: "{\"data\":[{\"testfacade\":\"EBtD6Dae9VXvK8ky7zYkCMfwZCzcsGsDiEfqmZB3Et9K\"},{\"pos/invoice\":\"ED2H47jWZbQKnPTwRLeZcfQ7eN9NyiRFVnRexmoWLScu\"}]}"} end, post: fn("https://bitpay.com/testpoint", _body,  _headers) -> %HTTPotion.Response{status_code: 200, body: "{\"data\":[{\"policies\":[{\"policy\":\"id\",\"method\":\"unclaimed\",\"params\":[]}],\"resource\":\"4e2rQDFK6Y1X4eU5ugw8AYy9FFih6jRicv6dxeccgS8r\",\"token\":\"BHMA5LMxUdEvePuAaEPmuW5tPYbGpw65jirDHzbXLfkt\",\"facade\":\"pos\",\"dateCreated\":1440003119142,\"pairingExpiration\":1440089519142,\"pairingCode\":\"8GSQvjb\"}]}" } end] do
      response = WebClient.post("testpoint", %{with_facade: :testfacade}, client)
      assert response.body.data |> List.first |> Access.get(:token) == "BHMA5LMxUdEvePuAaEPmuW5tPYbGpw65jirDHzbXLfkt"
    end

  end

  test 'get method' do
    with_mock HTTPotion, [get: fn("https://bitpay.com/blocks", _body, _headers) -> %HTTPotion.Response{status_code: 228, body: "{\"data\":[{\"pos\":\"EBtD6Dae9VXvK8ky7zYkCMfwZCzcsGsDiEfqmZB3Et9K\"},{\"pos/invoice\":\"ED2H47jWZbQKnPTwRLeZcfQ7eN9NyiRFVnRexmoWLScu\"}]}"} end] do
      assert WebClient.get("blocks", %WebClient{}).status == 228
    end 
  end

  test 'pairing short circuits with invalid code' do
    illegal_pairing_codes() |> Enum.each fn(item) -> 
      assert WebClient.pair_pos_client(item, %WebClient{}) == {:error, "pairing code is not legal"} 
    end
  end

  test 'pairing handles errors gracefully' do
    with_mock HTTPotion, [post: fn("https://bitpay.com/tokens", _body, _headers) ->
        %HTTPotion.Response{status_code: 403,
          body: "{\n  \"error\": \"this is a 403 error\"\n}"} end] do
            assert {:error, "403: this is a 403 error"} ==  WebClient.pair_pos_client "aBD3fhg", %WebClient{}
          end
  end

  test "create invoice fails gracefully with improper price" do
    params = %{price: "100,00", currency: "USD", token: "anything"}
    assert {:error, "Illegal Argument: Price must be formatted as a float"} == WebClient.create_invoice(params, %BitPay.WebClient{})
  end

  test "create invoice retrieves tokens from server" do
    params = %{price: 100, currency: "USD"}
    with_mock HTTPotion, [get: fn("https://bitpay.com/tokens", _body, _headers) -> %HTTPotion.Response{status_code: 228, body: "{\"data\":[{\"pos\":\"EBtD6Dae9VXvK8ky7zYkCMfwZCzcsGsDiEfqmZB3Et9K\"},{\"pos/invoice\":\"ED2H47jWZbQKnPTwRLeZcfQ7eN9NyiRFVnRexmoWLScu\"}]}"} end, post: fn("https://bitpay.com/invoices", _body, _headers) -> %HTTPotion.Response{status_code: 200, body: "{\"facade\":\"pos/invoice\",\"data\":{\"url\":\"https://test.bitpay.com/invoice?id=A41p1sHqruaA38YaKC83L7\",\"status\":\"new\",\"btcPrice\":\"0.388736\",\"btcDue\":\"0.388736\",\"price\":100,\"currency\":\"USD\",\"exRates\":{\"USD\":257.24390946963365},\"invoiceTime\":1439829619654,\"expirationTime\":1439830519654,\"currentTime\":1439829619916,\"guid\":\"ebf5fe06-b738-4d51-bb9c-f5dcd6613124\",\"id\":\"A41p1sHqruaA38YaKC83L7\",\"btcPaid\":\"0.000000\",\"rate\":257.24,\"exceptionStatus\":false,\"paymentUrls\":{\"BIP21\":\"bitcoin:mtzuBK37L5CxsvPVfP1E711gk6h7VJQ3rJ?amount=0.388736\",\"BIP72\":\"bitcoin:mtzuBK37L5CxsvPVfP1E711gk6h7VJQ3rJ?amount=0.388736&r=https://test.bitpay.com/i/A41p1sHqruaA38YaKC83L7\",\"BIP72b\":\"bitcoin:?r=https://test.bitpay.com/i/A41p1sHqruaA38YaKC83L7\",\"BIP73\":\"https://test.bitpay.com/i/A41p1sHqruaA38YaKC83L7\"},\"token\":\"8CWU2YMJSozc2SKoYJygRkuqmyiuCAQSQrShMpzGT4f77BPABLt9EovsxkmVkUWvPE\"}}" } end] do
    {:ok, response} = WebClient.create_invoice(params, %WebClient{})
    assert 1439829619916 ==  response.currentTime
            end
  end

  test "create invoice handles BTC" do
    params = %{price: "0.004", currency: "BTC", token: "anything"}
    with_mock HTTPotion, [post: fn("https://bitpay.com/invoices", _body, _headers) ->
        %HTTPotion.Response{status_code: 200,
          body: "{\"facade\":\"pos/invoice\",\"data\":{\"url\":\"https://test.bitpay.com/invoice?id=A41p1sHqruaA38YaKC83L7\",\"status\":\"new\",\"btcPrice\":\"0.388736\",\"btcDue\":\"0.388736\",\"price\":100,\"currency\":\"USD\",\"exRates\":{\"USD\":257.24390946963365},\"invoiceTime\":1439829619654,\"expirationTime\":1439830519654,\"currentTime\":1439829619916,\"guid\":\"ebf5fe06-b738-4d51-bb9c-f5dcd6613124\",\"id\":\"A41p1sHqruaA38YaKC83L7\",\"btcPaid\":\"0.000000\",\"rate\":257.24,\"exceptionStatus\":false,\"paymentUrls\":{\"BIP21\":\"bitcoin:mtzuBK37L5CxsvPVfP1E711gk6h7VJQ3rJ?amount=0.388736\",\"BIP72\":\"bitcoin:mtzuBK37L5CxsvPVfP1E711gk6h7VJQ3rJ?amount=0.388736&r=https://test.bitpay.com/i/A41p1sHqruaA38YaKC83L7\",\"BIP72b\":\"bitcoin:?r=https://test.bitpay.com/i/A41p1sHqruaA38YaKC83L7\",\"BIP73\":\"https://test.bitpay.com/i/A41p1sHqruaA38YaKC83L7\"},\"token\":\"8CWU2YMJSozc2SKoYJygRkuqmyiuCAQSQrShMpzGT4f77BPABLt9EovsxkmVkUWvPE\"}}" } end] do
          {:ok, response} = WebClient.create_invoice(params, %BitPay.WebClient{})
          assert 1439829619916 ==  response.currentTime
        end
    end

    test "create invoice fails gracefully with improper currency" do
      params = %{price: 100.00, currency: "USDa", token: "anything"}
      assert {:error, "Illegal Argument: Currency is invalid."} == WebClient.create_invoice(params, %BitPay.WebClient{})
    end

    defp illegal_pairing_codes do
      ["abcdefgh", "habcdefg", "abcd-fg"]
    end
  end
