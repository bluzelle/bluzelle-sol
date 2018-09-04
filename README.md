# bluzelle-sol
Solidity Contracts to use when connecting to the Bluzelle Swarm

They are essentially files that implements a wrapper around Oraclize.

## Video

https://www.youtube.com/watch?v=fc5bPlQKa88

## Importing

To use Bluzelle in a solidity contract, first import bluzelle.sol. If you are
using remix, you can do this with just 

```
import "https://github.com/bluzelle/bluzelle-sol/contracts/bluzelle.sol";
```

If you are using an environment which doesn't handle that for you, you may have
to download bluzelle.sol directly as well as its dependancies:

https://github.com/oraclize/ethereum-api/blob/master/oracloraclizeAPI_0.5.sol
https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol

## Usage

To use the Bluzelle interface, first have your contract extend BluzelleClient

```
contract MyContract is BluzelleClient {
  ...
}
```

Call `setUUID(string uuid)` before making any DB calls - this configures which
distinct database you connect to. Your UUID may actually be any string, but you
should choose it to be something distinct from anyone else's - such as your
contract's address, a random string, or actually a uuid.

Then, DB operations are performed with the following methods:
```
create("a key", "with some data");
read("a key");
update("a key", "with a new value");
remove("a key");
```
Each DB operation will consume a small amount of ether to pay Oraclize's fee.  You may add a function such as retrieveETH() to reclaim overspent ethereum that Oraclize refunded to your smart contract. 

All database operations are performed asynchronously (this is a fundamental
constraint of running in Ethereum). If you want to act on the result of your
database operations (and presumably you do, at least for reads), then override
some or all of the following callback methods

```
// When a read succeeds
function readResult(string key, string result, bool success) internal { ... }

// When a read fails
function readFailure(string key, bool success) internal {...}

// When a create, update, remove is performed
function createResponse(string key, bool success) internal {...}
function updateResponse(string key, bool success) internal {...}
function removeResponse(string key, bool success) internal {...}
```

The included file SampleDappPublic.sol shows an example smart contract that excercises
this functionality.

## Caveats

This should work on any network Oraclize supports: Ropsten, Kovan, and Rinkeby
as well as the main net. We do not recommend it for use on the main net; it's
not known to be reliable or secure enough.

Each database transaction requires a small fee for Oraclize ($0.01 usd worth),
and the transaction will fail if the contract balance is too low.

If you neglect to set a UUID before making a DB call, you will end up using the
emptry string as your UUID. This may result in Bad Things.  
You may use setUUID(string uuid) function to switch to the correct UUID.
