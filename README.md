[![Build Status](https://travis-ci.org/bitpay/elixir-client.svg?branch=master)](https://travis-ci.org/bitpay/elixir-client) [![Hex Package](https://img.shields.io/badge/hexpm-v0.0.1-plug.svg)](https://hex.pm/packages/bitpay)

# BitPay Library for Elixir or Erlang
Powerful, flexible, lightweight interface to the BitPay Bitcoin Payment Gateway API. Can be used in an Elixir project or directly in an Erlang project as described in the [Elixir Crash Course](http://elixir-lang.org/crash-course.html). This README assumes that you are using Elixir.

## Installation

using hex, add to mixfile:
 { :bitpay, "~> 0.0.1" }

otherwise: 
 { :bitpay, github: "bitpay/elixir-client", tag: "v0.0.1" }

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

    > webclient = %BitPay.WebClient{pem: pem}
    > params = %{price: 100, currency: "USD", token: token.pos}
    > invoice = BitPay.WebClient.create_invoice(params, webclient)

That will return a map representing the invoice, and create an invoice on BitPays servers. Other parameters can be sent, see the [BitPay REST API documentation](https://bitpay.com/api#resource-Invoices) for details.

## Testnet Usage

  To use testnet, add a uri parameter when creating the webclient struct `%BitPay.WebClient{uri: "https://test.bitpay.com"}`
  

## API Documentation

API Documentation is available on the [BitPay site](https://bitpay.com/api).

## Running the Tests

The tests depend on a custom fork of elixir-webdriver and require that you have phantomjs installed.

Before running the tests, get a test.bitpay.com account. On Mac or Linux systems, set your system variables using the `set_constants` shell file in the test directory. 

    $ source ./test/set_constants.sh https://test.bitpay.com <youremail> <yourpassword>
    $ mix test

The tests will attempt to create two files and a folder called `.bitpay` in your home (~) directory. This saves a pem file and token, which keeps the tests from having to pair twice every time they run, speeding up testing and avoiding BitPays token creation rate limiter. If you revoke the tokens or want a clean run, delete the files in this directory.

## Found a bug?
Let us know! Send a pull request or a patch. Questions? Ask! We're here to help. We will respond to all filed issues.

## Contributors
[Click here](https://github.com/philosodad/bitpay-elixir/graphs/contributors) to see a list of the contributors to this library.

