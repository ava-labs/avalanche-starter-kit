const provider = new Web3.providers.HttpProvider("http://localhost:8545");
const contractArtifact = require("./path/to/contractArtifact.json"); //produced by Truffle compile
const contract = require("@truffle/contract");

const MyContract = contract(contractArtifact);