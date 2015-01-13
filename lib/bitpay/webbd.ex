defmodule WebD do
  require IEx
  def make_happen do
    WebDriver.sessions |> Enum.map(&(WebDriver.stop_session(&1)))
    WebDriver.stop_all_browsers
    %WebDriver.Config{name: :testbrowser} |>
    WebDriver.start_browser
    WebDriver.start_session :testbrowser, :session
    WebDriver.Session.set_implicit_wait_timeout(:session, 10000)
    WebDriver.Session.url :session, "https://paul.bp:8088/merchant-login"
    WebDriver.Session.url :session
    WebDriver.Session.maximize_window(:session)
    email = WebDriver.Session.element( :session, :name, "email" )
    WebDriver.Element.value(email, "paul@bitpay.com")
    password = WebDriver.Session.element(:session, :name, "password" )
    WebDriver.Element.value(password, "Password123!")
    form = WebDriver.Session.element( :session, :id, "loginForm" )
    WebDriver.Element.submit (form)
    eleme = WebDriver.Session.element( :session, :css, ".dashboard-icon" )
    IO.puts WebDriver.Session.url :session
    WebDriver.Session.url :session, "https://paul.bp:8088/api-tokens"
    iconplus = WebDriver.Session.element( :session, :css, ".icon-plus" )
    WebDriver.Element.click(iconplus)
    form = WebDriver.Session.element( :session, :id, "token-new-form" )
    WebDriver.Element.submit( form )
    claimcode = WebDriver.Session.element( :session, :css, ".token-claimcode" ) |>
                WebDriver.Element.text
    IO.puts claimcode
  end
end
