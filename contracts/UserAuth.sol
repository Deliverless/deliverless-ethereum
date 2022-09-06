// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./BigchainDB.sol";

contract UserAuth is BigchainDB {
    using strings for *;

    constructor() BigchainDB() {
    }

    function requestIsUsername(string memory _username) public returns (bytes32) {
        return requestAssetSearchId(_username);
    }

    function requestUserPassword(bytes32 _requestId) public returns (bytes32) {
        Request memory request = getRequestStatus(_requestId, BigchainDB.Status.Success);
        string memory id = string(request.data).toSlice().substringLast(64).toString();
        emit Log(_requestId, id);
        return requestMetadataSearchResponse(id, "0,metadata,password");
    }

    function isUserAuth(string memory _username, string memory _password, bytes32 _usernameRequestId, bytes32 _passwordRequestId) public view returns (bool) {
        
        string memory usernameResult = getRequestData(_usernameRequestId, _username.toSlice().len());
        string memory passwordResult = getRequestData(_passwordRequestId, _password.toSlice().len());

        if (keccak256(abi.encodePacked(usernameResult)) == keccak256(abi.encodePacked(_username)) 
        && keccak256(abi.encodePacked(passwordResult)) == keccak256(abi.encodePacked(_password))) {
            return true;
        } else {
            return false;
        }

    }

}