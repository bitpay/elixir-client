defmodule PairingTest do
  use ExUnit.Case, async: false
  alias BitPay.WebClient, as: WebClient

  test 'pairs with the server' do
    claimcode = get_code_from_server
    client = %WebClient{uri: "https://test.bitpay.com"}
    token = WebClient.pair_pos_client claimcode, client
    assert String.length(token.pos) > 0 
  end

  #  test 'creates an invoice' do
  #    claimcode = get_code_from_server
  #    client = %WebClient{uri: "https://test.bitpay.com"}
  #    token = WebClient.pair_pos_client claimcode, client
  #
  #  end

  defp get_code_from_server do
    WebDriver.sessions |> Enum.map(&(WebDriver.stop_session(&1)))
    WebDriver.stop_all_browsers
    %WebDriver.Config{name: :testbrowser} |>
    WebDriver.start_browser
    WebDriver.start_session :testbrowser, :session
    WebDriver.Session.set_timeout(:session, "script", 100000)
    WebDriver.Session.set_timeout(:session, "implicit", 100000)
    WebDriver.Session.url :session, "https://test.bitpay.com/merchant-login"
    WebDriver.Session.url :session
    WebDriver.Session.maximize_window(:session)
    email = WebDriver.Session.element( :session, :name, "email" )
    WebDriver.Element.value(email, "paul@bitpay.com")
    password = WebDriver.Session.element(:session, :name, "password" )
    WebDriver.Element.value(password, "Password123!")
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
