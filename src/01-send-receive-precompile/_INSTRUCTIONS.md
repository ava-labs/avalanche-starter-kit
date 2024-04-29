

cast call --rpc-url mamaSubnet 0x0200000000000000000000000000000000000005 "getBlockchainID()(bytes32)" 
    0x2698e9474c753c6b2163166c0dada64ac7ce5691c36d7c0fa475aa62777cb8a2

forge create --rpc-url local-c --private-key $PK src/01-send-receive-precompile/senderOnCChain.sol:SenderOnCChain
    0x5DB9A7629912EBF95876228C24A848de0bfB43A9

forge create --rpc-url mamaSubnet --private-key $PK src/01-send-receive-precompile/receiverOnSubnet.sol:ReceiverOnSubnet
    0x52C84043CD9c865236f11d9Fc9F56aa003c1f922

cast send --rpc-url local-c --private-key $PK <sender_contract_address> "sendMessage(address,string)" <receiver_contract_address> "Hello"
    cast send --rpc-url local-c --private-key $PK 0x5DB9A7629912EBF95876228C24A848de0bfB43A9 "sendMessage(address,string)" 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "Hello"

cast call --rpc-url local-c 0x5DB9A7629912EBF95876228C24A848de0bfB43A9 "sha256hash()(string)"
cast call --rpc-url mamaSubnet 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "response()(bytes32)"
cast call --rpc-url mamaSubnet 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "computeHash(string)" "hola"