// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../modules/chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../modules/utils/strings.sol";

contract BigchainDB is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using strings for *;

    event Log(bytes32 requestId, string message);

    enum Status {
        Pending,
        Success,
        Failed,
        Idling
    }

    struct Request {
        bytes32 requestId;
        Status status;
        bytes data;
    }

    Request[] private requests;

    bytes32 private jobId;
    uint256 private fee;
    
    // string internal assestId;
    // string internal metadataId;

    error StatusError(string message);

    constructor() {
        setChainlinkToken(0x8a31544A2a4006889735B97d092FFD5bd0396B5E);
        setChainlinkOracle(0x12803e97582646C463b631c2bb653A72Bf16f13B);
        jobId = "5d82606d6dd440bea720bfad1d75516d";
        fee = 0.1 * 10 ** 18;
    }

    // Helper function(s)

    function getRequestIndex(bytes32 _requestId) public view returns (uint) {
        for (uint i = 0; i < requests.length; i++) {
            if (requests[i].requestId == _requestId) {
                return i;
            }
        }
        revert StatusError("Request not found");
    }

    // Contract functions
    
    function requestAssetSearchId(string memory _search) internal returns (bytes32) {   
        bytes32 requestId;
        uint data = 0;

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        
        request.add("get", string(abi.encodePacked("http://24.150.93.243:9984/api/v1/assets/?search=", _search, "&limit=", "1")));
        request.add("path", "0,id");
        
        requestId = ChainlinkClient.sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function requestAssetSearchResponse(string memory _search, string memory _path) internal returns (bytes32) {   
        bytes32 requestId;
        uint data = 0;

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        
        request.add("get", string(abi.encodePacked("http://24.150.93.243:9984/api/v1/assets/?search=", _search, "&limit=", "1")));
        request.add("path", _path);
        
        requestId = ChainlinkClient.sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function requestMetadataSearchId(string memory _search) internal returns (bytes32) {
        bytes32 requestId;
        uint data = 0;

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        
        request.add("get", string(abi.encodePacked("http://24.150.93.243:9984/api/v1/metadata/?search=", _search, "&limit=", "1")));
        request.add("path", "0,id");
        
        requestId = ChainlinkClient.sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function requestMetadataSearchResponse(string memory _search, string memory _path) internal returns (bytes32) {   
        bytes32 requestId;
        uint data = 0;

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        
        request.add("get", string(abi.encodePacked("http://24.150.93.243:9984/api/v1/metadata/?search=", _search, "&limit=", "1")));
        request.add("path", _path);
        
        requestId = ChainlinkClient.sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function fulfillRequest(bytes32 _requestId, bytes memory _data) public recordChainlinkFulfillment(_requestId) {
        uint index = getRequestIndex(_requestId);
        requests[index].status = Status.Success;
        requests[index].data = _data;
    }

    function getRequestData(bytes32 _requestId) public view returns (string memory) {
        uint index = getRequestIndex(_requestId);
        return string(requests[index].data);
    }

    function getRequestData(bytes32 _requestId, uint _length) public view returns (string memory) {
        uint index = getRequestIndex(_requestId);
        return string(requests[index].data).toSlice().substringLast(_length).toString();
    }
    
    function getRequest(bytes32 _requestId) internal view returns (Request memory) {
        for (uint i = 0; i < requests.length; i++) {
            if (requests[i].requestId == _requestId) {
                return requests[i];
            }
        }
        revert StatusError("Request not found");
    }

    function getRequestStatus(bytes32 _requestId, Status _status) internal view returns (Request memory) {
        for (uint i = 0; i < requests.length; i++) {
            if (requests[i].requestId == _requestId) {
                if (requests[i].status == _status) {
                    return requests[i];
                }
            }
        }
        revert StatusError("Request not found");
    }

    function requestStatus(bytes32 _requestId) public view returns (Status) {
        Request memory request = getRequest(_requestId);
        return request.status;
    }

    function requestStatusString(bytes32 _requestId) public view returns (string memory) {

        Request memory request = getRequest(_requestId);
        if (request.status == Status.Pending) {
            return "Pending";
        } else if (request.status == Status.Success) {
            return "Success";
        } else if (request.status == Status.Failed) {
            return "Failed";
        } else if (request.status == Status.Idling) {
            return "Idling";
        }
        revert StatusError("Request not found");
    }

    function cancelRequest(bytes32 _requestId) public returns (bool) {
        uint index = getRequestIndex(_requestId);
        if (requests[index].status == Status.Pending) {
            requests[index].status = Status.Failed;
            return true;
        }
        return false;
    }

    function getRequestsLength() public view returns (uint) {
        return requests.length;
    }

    

    // NOTE: This function is currently not supported yet.
    // function clearRequests() public {
    //     requests = new Request[](0);
    // }

}