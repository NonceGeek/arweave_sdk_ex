defmodule ArweaveSdkExTest do
  use ExUnit.Case
  doctest ArweaveSdkEx

  test "gen_root_hash with large data" do
    data = File.read!(Path.join([__DIR__, "fixtures/testfile0.bin"]))
    # data = "Test Data"

    root_hash = ArweaveSdkEx.Tx.get_root_hash(data)

    assert ArweaveSdkEx.Utils.Crypto.url_encode64(root_hash) ==
             "YPg3Q4bkY2--cf4Ydjf5XnT1LXDKAVXVCDUaqkJ0Jvk"
  end

  test "gen_root_hash with small data" do
    data = "Test Data"

    root_hash = ArweaveSdkEx.Tx.get_root_hash(data)

    assert ArweaveSdkEx.Utils.Crypto.url_encode64(root_hash) ==
             "0W8rNlv4bUX_mdPf6m102cjlyb3isgtBOYBeNjF-f_4"
  end

  test "send_tx" do
    jwk_json =
      ArweaveSdkEx.Wallet.read_jwk_json_from_file(
        Path.join([__DIR__, "fixtures/test_jwk_file.json"])
      )

    node = "https://arweave.net"
    data = "Test Data"
    tags = []
    reward_coefficient = 1
    python_path = "/usr/local/bin/"

    {tx_signed, id, tx_unsigned} =
      ArweaveSdkEx.Wallet.sign_tx(node, data, tags, jwk_json, reward_coefficient, python_path)

    # IO.inspect(tx_signed)
    IO.inspect(id)
    IO.inspect(ArweaveSdkEx.send(node, tx_signed))
  end
end
