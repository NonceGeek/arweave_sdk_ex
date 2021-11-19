jwk = ArweaveSdkEx.Wallet.read_jwk_from_file("/Users/liaohua/arweave_study/arweave-key-riehAVqG1ihV3kwNb3IandUy2OfLnilk3cj7fSuDEPw.json")
node = "https://arweave.net"
tags = %{"Content-Type" => "application/elixir"}
data ="test"
example_tx = File.read!("tx_example2.json") |> Poison.decode!
unsigned_tx_hash =
  "20866b4fa81614964106f260878220abb72dfabf768c1cd211c076c99139d7d1cca32ca489a7939d22dfdafdfcf5e5f8"
  |> Base.decode16!(case: :lower)
