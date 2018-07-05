pragma solidity ^0.4.20;

import "./BluzelleClient.sol";

contract SampleDapp is BluzelleClient {
    string public current_uuid;
    string public last_key_used;
    string public last_value_read;
    string public last_result_received;

    event OwnershipChanged(address indexed prevOwner, address indexed newOwner);
    event swarm_response(string _action, string _key, bool _response, uint256 _timestamp);
    event swarm_read(string _key, string _value, uint256 _timestamp);

    bool public keyExists = false;
    address public owner = msg.sender;
    
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

    function SampleDapp(string _uuid) public {
        owner = msg.sender;
        changeUUID(_uuid); 
    }
   
    function changeOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != address(this));
        OwnershipChanged(owner, newOwner);
        owner = newOwner;
    }
    
    function changeUUID(string _uuid) onlyOwner public {
        require(bytes(_uuid).length > 0);
        current_uuid = _uuid;
        setUUID(_uuid);
    }

    function changeURL(string _url) onlyOwner public {
        setURL(_url);
    }

    /* Read the value from Bluzelle (this requires a small fee to pay Oraclize) */
    function getValue(string _key) onlyOwner public payable {
        read(_key);
    }
    
    /* Set the value */
    function set(string _key, string _value) onlyOwner public payable {
        update(_key, _value);
    }

    /* Create new KVP */
    function add(string _key, string _value) onlyOwner public payable {
        create(_key, _value);
    }
    
    /* Remove a KVP */
    function eliminate(string _key) onlyOwner public payable {
        remove(_key);
    }


    /* callback invoked by bluzelle upon read */
    function readResult(string k, string v, bool /*success*/) internal {
        last_key_used = k;
        last_value_read = v;
        swarm_read(k,v,now);
    }

    function readFailure(string k, bool failed) internal {
        swarm_response("readFailed",k,failed, now);
    }
    
    /* callback invoked by bluzelle upon create */
    function createResponse(string k, bool success) internal {
        last_key_used = k;   
        if(success){
            keyExists = true;
        }
        swarm_response("create",k,success, now);
    }

    function updateResponse(string k, bool success) internal {
        last_key_used = k;
        if(success){
            keyExists = true;
        }
        swarm_response("update",k,success, now);
    }
    
    /* callback invoked by bluzelle upon delete */
    function removeResponse(string k, bool success) internal {
        last_key_used = k;
        if(success){
            keyExists = false;
        }
        swarm_response("remove",k,success, now);
    }

    function __callback(bytes32 myid, string result) public {
        last_result_received = result;
        super.__callback(myid,result);
    }

    function retrieveETH() onlyOwner public payable {
        owner.transfer(address(this).balance);
    }
}
  