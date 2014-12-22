defmodule Client.CLI do

  @moduledoc """

  parse arguments, pair, retrieve invoices.

  """

  def run(argv) do
    parse_args(argv)
  end

  @doc """
    commands can be:
      pair <code> [options] 
      keys

    options can be:
      -t or --test, which will use the test server
      -c <custom uri> or --custom <custom_uri>, which will use a custom server
      -i <insecure_uri> or --insecure <insecure_uri>, which will use an insecure custom bitpay URI
      -h or --help, which will display this help message
  """

  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [ help: :boolean], aliases: [ h: :help ]) 

    case parse do
    { [ help: true ], _ , _ }
      -> :help
    { _, [ keys ], _ }
      -> show_keys() 
    _ -> :help
    end
  end

  defp show_keys do
    private = nil;
    public = nil;
    client_id = nil;

    """
    Current BitPay Client Keys:
    Private Key: #{private}
    Public Key: #{public}
    Client ID: #{client_id}
    """
  end
end 
