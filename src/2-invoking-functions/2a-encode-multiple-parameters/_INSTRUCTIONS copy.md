TO-DO


forge create --rpc-url local-c --private-key $PK src/2-invoking-functions/2a-encode-multiple-parameters/NumberSenderOnCChain.sol:NumberSenderOnCChain

 0x5DB9A7629912EBF95876228C24A848de0bfB43A9

forge create --rpc-url mysubnet --private-key $PK src/2-invoking-functions/2a-encode-multiple-parameters/ReceiveAndSumOnSubnet.sol:ReceiveAndSumOnDestination

0x52C84043CD9c865236f11d9Fc9F56aa003c1f922

cast send --rpc-url local-c --private-key $PK 0x5DB9A7629912EBF95876228C24A848de0bfB43A9 "sendNumbers(address,uint256, uint256)" 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 4 2


cast call --rpc-url mysubnet 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "result()(uint256)"