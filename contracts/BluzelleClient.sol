pragma solidity ^0.4.20;

import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol"; //".oraclizeAPI_0.4.sol";
//import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol"; //"./oraclizeAPI_0.5.sol";
import "github.com/Arachnid/solidity-stringutils/src/strings.sol"; //"./strings.sol";

contract BluzelleClient is usingOraclize {
    
    enum opType {read, create, update, remove}
    struct pendingOperation {
        opType op;
        string key;
    }
    
    using strings for *;
    mapping(bytes32 => pendingOperation) pendingOps;
    string uuid;

    
    string public apiRead = "http://testnet.bluzelle.com:8080/read/";
    string public apiCreate = "http://testnet.bluzelle.com:8080/create/";
    string public apiUpdate = "http://testnet.bluzelle.com:8080/update/";
    string public apiRemove = "http://testnet.bluzelle.com:8080/delete/";
    
    string constant successPrefix = "ack";
    string constant failPrefix = "err";

    function setUUID(string _uuid) internal {
        uuid = _uuid;
    }

    function setURL(string _url) internal {
        apiRead = strConcat(_url,"/read/");
        apiCreate = strConcat(_url,"/create/");
        apiUpdate = strConcat(_url,"/update/");
        apiRemove = strConcat(_url,"/delete/");
    }
    
    function read(string key) internal {
        string memory request = strConcat(apiRead,uuid,"/",key);
        bytes32 id = oraclize_query("URL", request);
        pendingOps[id] = pendingOperation(opType.read, key);
    }
    
    function remove(string key) internal {
        string memory request = strConcat(apiRemove,uuid,"/",key);
        // third parameter makes the request a POST
        bytes32 id = oraclize_query("URL", request, "-");
        pendingOps[id] = pendingOperation(opType.remove, key);
    }
    
    function update(string key, string data) internal {
        string memory request = strConcat(apiUpdate,uuid,"/",key);
        bytes32 id = oraclize_query("URL", request, data);
        pendingOps[id] = pendingOperation(opType.update, key);
    }
    
    function create(string key, string data) internal {
        string memory request = strConcat(apiCreate,uuid,"/",key);
        bytes32 id = oraclize_query("URL", request, data);       
        pendingOps[id] = pendingOperation(opType.create, key);
    }

    function readResult(string /*key*/, string /*result*/, bool /*success*/) internal {
        // Called when a read returns sucessfully
    }
    
    function readFailure(string /*key*/, bool /*success*/) internal {
        // Called when a read fails (no such key or db unavailable)
    }
    
    function createResponse(string /*key*/, bool /*success*/) internal {
        // Called when a create returns
    }
    
    function updateResponse(string /*key*/, bool /*success*/) internal {
        // Called when an update returns
    }
    
    function removeResponse(string /*key*/, bool /*success*/) internal {
        // Called when a remove returns
    }
    // Result from oraclize
    function __callback(bytes32 myid, string result) public {
        require(msg.sender == oraclize_cbAddress());
        require(pendingOps[myid].key.toSlice().len() > 0);
        
        bool success = result.toSlice().startsWith(successPrefix.toSlice());
        string memory key = pendingOps[myid].key;
        opType op = pendingOps[myid].op;
        
        if(op == opType.read){
            if(success){
                readResult(
                    key, 
                    result.toSlice().beyond(successPrefix.toSlice()).toString(),
                    success
                    );
            }else{
                readFailure(key,success);
            }
        }else if(op == opType.create){
            createResponse(key, success);
        }else if(op == opType.update){
            updateResponse(key, success);
        }else if(op == opType.remove){
            removeResponse(key, success);
        }
        
        delete pendingOps[myid];
    }
}
