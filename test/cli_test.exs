defmodule CliTest do
  use ExUnit.Case

  import Client.CLI, only: [ parse_args: 1 ]
  

  test ":help returned by option parsing with -h and --help options" do
    assert parse_args(["-h", "--test"]) == :help
    assert parse_args(["-h"]) == :help
  end

  test "keys returns help message if it is used with any options" do
    assert parse_args(["keys", "anything"]) == :help
    assert parse_args(["anything", "keys"]) == :help
  end

  test "keys returns keys if used without any options" do
    keystring = """ 
    Current BitPay Client Keys:
    Private Key: 
    Public Key: 
    Client ID: 
    """
    assert parse_args(["keys"]) == keystring
  end
end

