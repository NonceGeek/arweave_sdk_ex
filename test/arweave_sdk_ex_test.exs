defmodule ArweaveSdkExTest do
  use ExUnit.Case
  doctest ArweaveSdkEx

  test "gen_root_hash" do
    data = File.read!(Path.join([__DIR__, "fixtures/testfile0.bin"]))

    root_hash = ArweaveSdkEx.Tx.get_root_hash(data)

    assert ArweaveSdkEx.Utils.Crypto.url_encode64(root_hash) ==
             "YPg3Q4bkY2--cf4Ydjf5XnT1LXDKAVXVCDUaqkJ0Jvk"
  end
end
