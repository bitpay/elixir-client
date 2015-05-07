defmodule PairingTest do
  use ExUnit.Case, async: false
  alias BitPay.WebClient, as: WebClient
  alias BitPay.KeyUtils, as: KeyUtils

  test 'pairs with the server' do
    root_url = System.get_env("RCROOTADDRESS")
    if(is_nil(root_url)) do
      raise ArgumentError, message: "Please set the system variables"
    else
      token = pair_with_server(root_url)
      assert String.length(token.pos) > 0 
    end
  end

  test 'creates an invoice' do
    root_url = System.get_env("RCROOTADDRESS")
    {pem, set_token} = set_or_get_pem_and_token(root_url)
    if(is_nil(pem) || is_nil(set_token) || is_nil(root_url)) do
      raise ArgumentError, message: "Please set the system variables"
    else
      client = %WebClient{uri: root_url, pem: pem}
      params = %{ price: 100, currency: "USD", token: set_token.pos }
      invoice = WebClient.create_invoice(params, client) 
      assert invoice.status == "new"
    end
  end

  test 'retrieves an invoice' do
    invoice_id = "8qnKuf41s1791339gmwB3S"
    client = %WebClient{uri: "https://test.bitpay.com"}
    invoice = WebClient.get_invoice(invoice_id, client)
    assert invoice.id == invoice_id
  end

  defp pair_with_server(root_url) do
    pem = KeyUtils.generate_pem
    pair_with_server root_url, pem
  end

  defp pair_with_server(root_url, pem) do
    claimcode = get_code_from_server
    client = %WebClient{uri: root_url, pem: pem}
    WebClient.pair_pos_client claimcode, client
  end

  defp set_or_get_pem_and_token(root_url) do
    pem_path = "./temp/bitpay.pem"
    token_path = "./temp/tokens.json"
    if(File.exists?(pem_path) && File.exists?(token_path)) do
      pem = File.read(pem_path) |> elem(1)
      set_token = File.read(token_path) |> elem(1) |>
                  JSX.decode([{:labels, :atom}]) |> elem(1)
    else
      pem = KeyUtils.generate_pem
      set_token = pair_with_server(root_url, pem)
      token_json = JSX.encode(set_token) |> elem(1)
      File.mkdir("./temp")
      File.write(pem_path, pem)
      File.write(token_path, token_json)
    end
    {pem, set_token}
  end

  defp get_code_from_server do
    root_url = System.get_env("RCROOTADDRESS")
    user_id = System.get_env("RCTESTUSER")
    user_password = System.get_env("RCTESTPASSWORD")
    if (is_nil(root_url) || is_nil(user_id) || is_nil(user_password) ) do
      raise ArgumentError, message: "Please set the system variables"
    else
      WebDriver.sessions |> Enum.map(&(WebDriver.stop_session(&1)))
      WebDriver.stop_all_browsers
      %WebDriver.Config{name: :testbrowser} |>
      WebDriver.start_browser
      WebDriver.start_session :testbrowser, :session
      WebDriver.Session.set_timeout(:session, "script", 100000)
      WebDriver.Session.set_timeout(:session, "implicit", 100000)
      WebDriver.Session.url :session, root_url <> "/merchant-login"
      WebDriver.Session.url :session
      WebDriver.Session.maximize_window(:session)
      email = WebDriver.Session.element( :session, :name, "email" )
      WebDriver.Element.value(email, user_id)
      password = WebDriver.Session.element(:session, :name, "password" )
      WebDriver.Element.value(password, user_password)
      form = WebDriver.Session.element( :session, :id, "loginForm" )
      WebDriver.Element.submit (form)
      WebDriver.Session.element( :session, :css, ".dashboard-icon" )
      WebDriver.Session.url :session, root_url <> "/api-tokens"
      iconplus = WebDriver.Session.element( :session, :css, ".icon-plus" )
      WebDriver.Element.click(iconplus)
      WebDriver.Session.element( :session, :tag, "button" )
      form = WebDriver.Session.element( :session, :id, "token-new-form" )
      WebDriver.Element.displayed? form
      WebDriver.Element.submit( form )
      claimcode = WebDriver.Session.element( :session, :css, ".token-claimcode" ) |>
      WebDriver.Element.text
      WebDriver.sessions |> Enum.map(&(WebDriver.stop_session(&1)))
      WebDriver.stop_all_browsers
      claimcode
    end
  end
end
