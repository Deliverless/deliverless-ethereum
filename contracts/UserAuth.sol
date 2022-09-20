// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./BigchainDB.sol";
import "../modules/@openzeppelin/contracts/utils/Strings.sol";

contract UserAuth is BigchainDB {
    using strings for *;

    constructor() BigchainDB() {
    }

    event LogRequestId(bytes32 requestId, string message);

    function requestIsAuth(string memory _username, string memory _password) public returns (bytes32) {
        string memory encoded = Strings.toHexString(uint256(keccak256(abi.encodePacked(_username, _password))), 32);
        bytes32 requestId = BigchainDB.requestFindObject("user", abi.encodePacked('{"encoded":"', encoded, '"}'), 1, "");
        emit LogRequestId(requestId, "Found");
        return requestId;
    }

    function requestNewAccount(string memory _username, string memory _password) public returns (bytes32) {
        string memory encoded = Strings.toHexString(uint256(keccak256(abi.encodePacked(_username, _password))), 32);
        bytes32 requestId = BigchainDB.requestNewObject("user", abi.encodePacked('{"encoded":"', encoded, '"}'), "");
        emit LogRequestId(requestId, "Found");
        return requestId;
    }

    function requestChangePassword(string memory _id, string memory _username, string memory _newPassword) public returns (bytes32) {
        string memory encoded = Strings.toHexString(uint256(keccak256(abi.encodePacked(_username, _newPassword))), 32);
        return BigchainDB.requestUpdateObject("user", _id, abi.encodePacked('{"encoded":"', encoded, '"}'), "");
    }

    function requestTest() public returns (bytes32) {
        string memory encoded = Strings.toHexString(uint256(keccak256(abi.encodePacked("Marcin", "Koziel"))), 32);
        return BigchainDB.requestTest("user", abi.encodePacked('{"encoded":"', encoded, '"}'), "");
    }

}