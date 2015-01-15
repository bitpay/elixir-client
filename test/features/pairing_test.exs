defmodule PairingTest do
  use ExUnit.Case, async: false
  alias BitPay.WebClient, as: WebClient
  alias BitPay.KeyUtils, as: KeyUtils

  test 'pairs with the server' do
    root_url = System.get_env("RCROOTADDRESS")
    if(is_nil(root_url)) do
      raise ArgumentError, message: "Please set the system variables"
    else
      claimcode = get_code_from_server
      client = %WebClient{uri: root_url}
      token = WebClient.pair_pos_client claimcode, client
      assert String.length(token.pos) > 0 
    end
  end

  test 'creates an invoice' do
    root_url = System.get_env("RCROOTADDRESS")
    pem = String.replace(System.get_env("RCPEM"), "\\n", "\n")
    set_token = System.get_env("RCTOKEN")
    if(is_nil(pem) || is_nil(set_token) || is_nil(root_url)) do
      raise ArgumentError, message: "Please set the system variables"
    else
      client = %WebClient{uri: System.get_env("RCROOTADDRESS"), pem: pem}
      token = %{pos: System.get_env("RCTOKEN")}
      params = %{price: 100, currency: "USD", token: token.pos}
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
      WebDriver.Session.url :session, "https://test.bitpay.com/api-tokens"
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
