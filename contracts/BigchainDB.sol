// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../modules/chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../modules/utils/strings.sol";
import "../modules/@openzeppelin/contracts/utils/Strings.sol";

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
        setChainlinkToken(0x2a14911610Fe49bCaB2f6998dc1eF2bC6DbfA80e);
        setChainlinkOracle(0x85D8ec63ECb5C037dAFb1fB87A81398805baCAbD);
        jobId = "220a1cc9ca2b43b6bc6134b25568ad92";
        fee = 0.1 * 10 ** 18;
    }

    function requestTest(string memory _model, bytes memory _meta, string memory _returnAtt) internal returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";

        uint256 lastRun;

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", "");
        request.add("method", "add");
        request.add("model", _model);
        request.addBytes("meta", _meta);
        request.add("limit", "");
        request.add("returnAtt", _returnAtt);

        requestId = sendChainlinkRequest(request, fee);
        lastRun = block.timestamp;

        while ((block.timestamp - lastRun) < 30 seconds && StringUtils.equal("{}", string(data))) {
            requests.push(Request(requestId, Status.Pending, abi.encodePacked("{0}")));
            return requestId;
        }

        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function requestNewObject(string memory _model, bytes memory _meta, string memory _returnAtt) internal returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";

        uint256 lastRun;

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", "");
        request.add("method", "add");
        request.add("model", _model);
        request.addBytes("meta", _meta);
        request.add("limit", "");
        request.add("returnAtt", _returnAtt);

        requestId = sendChainlinkRequest(request, fee);
        lastRun = block.timestamp;

        while ((block.timestamp - lastRun) < 30 seconds && StringUtils.equal("{}", string(data))) {
            data = "{}";
        }

        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function requestGetObject(string memory _model, string memory _id, string memory _returnAtt) internal returns (bytes32) {
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
        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function requestFindObject(string memory _model, bytes memory _meta, uint256 _limit, string memory _returnAtt) internal returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", "");
        request.add("method", "find");
        request.add("model", _model);
        request.addBytes("meta", _meta);
        request.addUint("limit", _limit);
        request.add("returnAtt", _returnAtt);

        requestId = sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function requestUpdateObject(string memory _model, string memory _id,  bytes memory _meta, string memory _returnAtt) internal returns (bytes32) {
        bytes32 requestId;
        bytes memory data = "{}";

        Chainlink.Request memory request = ChainlinkClient.buildChainlinkRequest(jobId, address(this), this.fulfillRequest.selector);
        request.add("id", _id);
        request.add("method", "update");
        request.add("model", _model);
        request.addBytes("meta", _meta);
        request.add("limit", "");
        request.add("returnAtt", _returnAtt);

        requestId = sendChainlinkRequest(request, fee);
        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function requestBurnObject(string memory _model, string memory _id) internal returns (bytes32) {
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
        requests.push(Request(requestId, Status.Pending, abi.encodePacked(data)));
        return requestId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory data) public recordChainlinkFulfillment(requestId) {
        uint index = getRequestIndex(requestId);
        requests[index].status = Status.Success;
        requests[index].data = data;
    }

    function getRequestData(bytes32 _requestId) public view returns (string memory) {
        uint index = getRequestIndex(_requestId);
        return string(requests[index].data);
    }

    function getRequestData(bytes32 _requestId, uint _length) internal view returns (string memory) {
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

    function getRequestIndex(bytes32 _requestId) public view returns (uint) {
        for (uint i = 0; i < requests.length; i++) {
            if (requests[i].requestId == _requestId) {
                return i;
            }
        }
        revert StatusError("Request not found");
    }

    // NOTE: This function is currently not supported yet.
    // function clearRequests() public {
    //     requests = new Request[](0);
    // }

}