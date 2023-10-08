// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library MerkleProof {
    function verify(bytes32 leaf, bytes32[] memory proof, bytes32 root, uint256 index) public pure returns (bool) {
        bytes32 hash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            index = index / 2;
        }

        return hash == root;
    }

    // proof ["0x9a30915182e1552605b77a9732813f999089e52c512aae8acd4198ba6a353cb7","0x35094b2352ecc343f5237d3375fb86aea1a50d011b634a77abac6f01cd192a48","0xe0e4d16165376977b85482c360a07e9f69d818059b6834888cfce92bb4556682"]
    // root 0xed69fc1c48222f6e5ff83cb8e3aa7de9e9a401f21fdc95b4a492322306646e21
    // leaf 0x004ef3f825c8849c73999f6e84fcb0332c1597fa3afbd85f7f1f35c7ac696bc2
    // index 0
}
