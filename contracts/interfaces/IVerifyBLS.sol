pragma solidity >=0.8.0;

interface IVerifyBLS {
    function verifySignatureBLS(string calldata message, bytes calldata signature, bytes calldata publicKey)
        external
        view
        returns (bool result);
    function aggregatePublicKeys(bytes[] calldata publicKeys) external pure returns (bytes calldata publicKey);
    function aggregateSignatures(bytes[] calldata signatures) external view returns (bytes calldata signature);
}
