// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../modules/chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../modules/utils/strings.sol";
import "../modules/@openzeppelin/contracts/utils/Strings.sol";

contract BigchainDB is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using strings for *;

    event RequestEvent (
        bytes32 id,
        string typeRequest,
        string data,
        string message
    );

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

    error StatusError(string message);

    constructor() {
        setChainlinkToken(0x2a14911610Fe49bCaB2f6998dc1eF2bC6DbfA80e);
        setChainlinkOracle(0x85D8ec63ECb5C037dAFb1fB87A81398805baCAbD);
        jobId = "220a1cc9ca2b43b6bc6134b25568ad92";
        fee = 0.1 * 10 ** 18;
    }

    function requestNewObject(string memory _model, string memory _meta, string memory _returnAtt) public returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";
        bytes memory metaBytes = abi.encodePacked(_meta);

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", "");
        request.add("method", "add");
        request.add("model", _model);
        request.addBytes("meta", metaBytes);
        request.add("limit", "");
        request.add("returnAtt", _returnAtt);

        requestId = sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, data));
        return requestId;
    }

    function requestGetObject(string memory _model, string memory _id, string memory _returnAtt) public returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", _id);
        request.add("method", "get");
        request.add("model", _model);
        request.addBytes("meta", "{}");
        request.add("limit", "");
        request.add("returnAtt", _returnAtt);

        requestId = sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, data));
        return requestId;
    }

    function requestFindObject(string memory _model, string memory _meta, uint256 _limit, string memory _returnAtt) public returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";
        bytes memory metaBytes = abi.encodePacked(_meta);

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", "");
        request.add("method", "find");
        request.add("model", _model);
        request.addBytes("meta", metaBytes);
        request.addUint("limit", _limit);
        request.add("returnAtt", _returnAtt);

        requestId = sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, data));
        return requestId;
    }

    function requestAppendObject(string memory _model, string memory _id,  string memory _meta, string memory _returnAtt) public returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";
        bytes memory metaBytes = abi.encodePacked(_meta);

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", _id);
        request.add("method", "update");
        request.add("model", _model);
        request.addBytes("meta", metaBytes);
        request.add("limit", "");
        request.add("returnAtt", _returnAtt);

        requestId = sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, data));
        return requestId;
    }

    function requestBurnObject(string memory _model, string memory _id) public returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", _id);
        request.add("method", "delete");
        request.add("model", _model);
        request.addBytes("meta", "{}");
        request.add("limit", "");
        request.add("returnAtt", "");

        requestId = sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, data));
        return requestId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory data) public recordChainlinkFulfillment(requestId) {
        uint256 index = findRequestIndex(requestId);
        requests[index].data = data;
        requests[index].status = Status.Success;

        emit RequestEvent(requestId, "fulfill", bytesToString(data), "Request fulfilled");
    }

    function getStatusId(Status _status) internal pure returns (uint8) {
        if (_status == Status.Pending) {
            return uint8(1);
        } else if (_status == Status.Success) {
            return uint8(2);
        } else if (_status == Status.Failed) {
            return uint8(3);
        } else if (_status == Status.Idling) {
            return uint8(4);
        } else {
            revert StatusError("Invalid status");
        }
    }

    function getRequestData(bytes32 _requestId) public view returns (string memory) {
        uint index = findRequestIndex(_requestId);
        return string(requests[index].data);
    }

    function getRequestData(bytes32 _requestId, uint _length) internal view returns (string memory) {
        uint index = findRequestIndex(_requestId);
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
            return "pending";
        } else if (request.status == Status.Success) {
            return "success";
        } else if (request.status == Status.Failed) {
            return "failed";
        } else if (request.status == Status.Idling) {
            return "idle";
        }
        revert StatusError("Request not found");
    }

    function cancelRequest(bytes32 _requestId) public returns (bool) {
        uint index = findRequestIndex(_requestId);
        if (requests[index].status == Status.Pending) {
            requests[index].status = Status.Failed;
            return true;
        }
        return false;
    }

    function getRequestsLength() public view returns (uint) {
        return requests.length;
    }

    function findRequestIndex(bytes32 _requestId) public view returns (uint) {
        for (uint i = 0; i < requests.length; i++) {
            if (requests[i].requestId == _requestId) {
                return i;
            }
        }
        revert StatusError("Request not found");
    }

    // Helper functions

    function bytesToString(bytes memory _bytes) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(_bytes.length);
        for (uint256 i = 0; i < _bytes.length; i++) {
            bytesArray[i] = _bytes[i];
        }
        return string(bytesArray);
    }

    // function testMemory() public {
    //     bytes memory var1 = "hello world";
    //     bytes memory var2;
    //     assembly {
    //         let ptr := mload(0x40)
    //         mstore(add(ptr, 0x00), var1)
    //         var2 := mload(add(ptr, 0x00))
    //     }

    //     emit LogBytes(var1, "Variable prefixed with 'hello world'");
    //     emit LogBytes(var2, "Copied variable prefixed with 'hello world'");

    //     emitLog();
    // }

    // function emitLog() public {
    //     bytes memory data;
    //     assembly {
    //         let ptr := mload(0x40)
    //         data := mload(add(ptr, 0x20))
    //     }
    //     emit LogBytes(data, "Copied variable prefixed with 'hello world' outside function");
    // }

}