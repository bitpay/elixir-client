defmodule PairingTest do
  use ExUnit.Case, async: false
  alias BitPay.WebClient, as: WebClient
  @pem System.get_env["BITPAYPEM"] |> String.replace("\\n", "\n")
  @api System.get_env["BITPAYAPI"]

  test 'pairs with the server' do
    :timer.sleep(5000)
    if(is_nil(System.get_env["BITPAYAPI"])) do
      raise ArgumentError, message: "Please set the system variables"
    end
    client = %WebClient{pem: @pem, uri: @api}
    response = BitPay.WebClient.post("tokens", %{facade: "pos", with_facade: :merchant}, client).body.data |> List.first |> Access.get(:pairingCode) |> WebClient.pair_pos_client(client)
    assert response.pos =~ ~r/^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]{20,44}$/
  end

  test 'initiates a client side pairing' do
    :timer.sleep(5000)
    if(is_nil(System.get_env["BITPAYAPI"])) do
      raise ArgumentError, message: "Please set the system variables"
    end
    client = %WebClient{uri: @api}
    {:ok, pairingCode} = BitPay.WebClient.get_pairing_code(client)
    assert String.length(pairingCode) == 7 
  end

  test 'creates an invoice' do
    if(is_nil(System.get_env["BITPAYAPI"])) do
      raise ArgumentError, message: "Please set the system variables"
    end
    client = %WebClient{pem: @pem, uri: @api}
    params = %{ price: 10, currency: "USD" }
    {:ok, invoice} = WebClient.create_invoice(params, client) 
    assert invoice.status == "new"
  end

  test 'retrieves an invoice' do
    invoice_id = "8qnKuf41s1791339gmwB3S"
    client = %WebClient{uri: "https://test.bitpay.com"}
    {:ok, invoice} = WebClient.get_invoice(invoice_id, client)
    assert invoice.id == invoice_id
  end
end
