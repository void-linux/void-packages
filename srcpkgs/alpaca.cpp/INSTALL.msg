To use alpaca.cpp, you need to download a ggml model.

A pre-trained model (~4GB) with 7 billion quantifiers can be downloaded at 
https://huggingface.co/Sosaka/Alpaca-native-4bit-ggml/resolve/main/ggml-alpaca-7b-q4.bin

A pre-trained model (~7.6GB) with 13 billion quantifiers is located at
https://gateway.estuary.tech/gw/ipfs/Qme6wyw9MzqbrUMpFNVq42rC1kSdko7MGT9CL7o1u9Cv9G

To run alpaca.cpp, call
$ alpaca-chat -m [insert model]
