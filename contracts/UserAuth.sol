// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./BigchainDB.sol";
import "../modules/@openzeppelin/contracts/utils/Strings.sol";

contract UserAuth is BigchainDB {
    using strings for *;

    constructor() BigchainDB() {
    }

    function requestIsAuth(string memory _username, string memory _password) public returns (bytes32) {
        string memory encoded = Strings.toHexString(uint256(keccak256(abi.encodePacked(_username, _password))), 32);
        return BigchainDB.requestFindObject("user", abi.encodePacked('{"encoded":"', encoded, '"}'), 1, "");
    }

    function requestNewAccount(string memory _username, string memory _password) public returns (bytes32) {
        string memory encoded = Strings.toHexString(uint256(keccak256(abi.encodePacked(_username, _password))), 32);
        return BigchainDB.requestNewObject("user", abi.encodePacked('{"encoded":"', encoded, '"}'), "");
    }

    function requestChangePassword(string memory _id, string memory _username, string memory _newPassword) public returns (bytes32) {
        string memory encoded = Strings.toHexString(uint256(keccak256(abi.encodePacked(_username, _newPassword))), 32);
        return BigchainDB.requestUpdateObject("user", _id, abi.encodePacked('{"encoded":"', encoded, '"}'), "");
    }

}