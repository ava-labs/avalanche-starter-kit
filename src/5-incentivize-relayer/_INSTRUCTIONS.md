

Deploy the ERC20 Token to be used for paying the fees to the relayer
```bash
forge create --rpc-url mysubnet --private-key $PK src/5-incentivize-relayer/ERC20FeeToken.sol:FeeToken 

```

To mint tokens to your funded account: 

```bash
cast send --rpc-url local-c --private-key $PK <fee_contract_address> "mint(address,uint256)" <your_address> <Amount_to_mint>
cast send --rpc-url local-c --private-key $PK 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "mint(address,uint256)" 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC 10000000000000

 
```

