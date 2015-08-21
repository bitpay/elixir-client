[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://raw.githubusercontent.com/bitpay/elixir-client/master/LICENSE.md)
[![Travis](https://img.shields.io/travis/bitpay/elixir-client.svg?style=flat-square)](https://travis-ci.org/bitpay/elixir-client)
[![Hex.pm](https://img.shields.io/hexpm/v/bitpay.svg?style=flat-square)](https://hex.pm/packages/bitpay)
[![Coveralls](https://img.shields.io/coveralls/bitpay/elixir-client.svg?style=flat-square)](https://coveralls.io/r/bitpay/elixir-client)

# BitPay Library for Elixir or Erlang
Powerful, flexible, lightweight interface to the BitPay Bitcoin Payment Gateway API. Can be used in an Elixir project or directly in an Erlang project as described in the [Elixir Crash Course](http://elixir-lang.org/crash-course.html). This document assumes that you are using Elixir.

## Installation

using hex, add to mixfile:
 { :bitpay, "~> 0.2.4" }

otherwise:
 { :bitpay, github: "bitpay/elixir-client", tag: "v0.2.4" }

## Basic Usage

The bitpay library allows authenticating with BitPay, creating invoices, and retrieving invoices.

### Pairing with Bitpay.com

Before pairing with BitPay.com, you'll need to log in to your BitPay account and navigate to /api-tokens. Generate a new pairing code and use it in the next step. If you want to test against

    > pem = BitPay.KeyUtils.generate_pem
    > webclient = %BitPay.WebClient{pem: pem} #or %BitPay.WebClient{pem: pem, uri: "https://test.bitpay.com"}
    > token = BitPay.WebClient.pair_pos_client(pairingcode, webclient)

You'll need to know the pem file and the token in order to create invoices.

### To create an invoice with a paired client:

Assuming that you have both a token object and a webclient as shown in the last step:

    > webclient = %BitPay.WebClient{pem: pem, uri: "https://test.bitpay.com"}
    > params = %{price: 100, currency: "USD", token: token.pos}
    > invoice = BitPay.WebClient.create_invoice(params, webclient)

That will return a map representing the invoice, and create an invoice on BitPays servers. Other parameters can be sent, see the [BitPay REST API documentation](https://bitpay.com/api#resource-Invoices) for details.

## Testnet Usage

  To use testnet, add a uri parameter when creating the webclient struct `%BitPay.WebClient{uri: "https://test.bitpay.com"}`


## API Documentation

API Documentation is available on the [BitPay site](https://bitpay.com/api).

## Running the Tests

The tests depend on a custom fork of elixir-webdriver and require that you have phantomjs installed.

Before running the tests, get a test.bitpay.com account. After this, you'll need to use the shell to approve a merchant token. Using `iex -S mix`:
```iex
(iex 1)> pem = BitPay.KeyUtils.generate_pem
(iex 2)> api = "https://test.bitpay.com"
(iex 3)> client = %BitPay.WebClient{pem: pem, uri: api}
(iex 4)> {:ok, pairingCode} = BitPay.WebClient.get_pairing_code(client)
```

Then log in to your dashboard and use the pairing code to create a "merchant" token. Once this is set, you'll need to create two environment variables, BITPAYPEM and BITPAYAPI, set to the values you used in the shell session. It's a good idea to save the pem to a file so that you can retrieve it later, the tests don't take care of that for you.

Once that's done you should be able to run: `mix test` and see the tests run.

## Found a bug?
Let us know! Send a pull request or a patch. Questions? Ask! We're here to help. We will respond to all filed issues.

## Contributors
[Click here](https://github.com/philosodad/bitpay-elixir/graphs/contributors) to see a list of the contributors to this library.
