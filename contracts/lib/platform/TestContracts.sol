pragma solidity ^0.4.24;

import "./Client.sol";
import "../../platform/dispatch/DispatchInterface.sol";
import "../../platform/bondage/BondageInterface.sol";
import "../../platform/registry/RegistryInterface.sol";
import "./OnChainProvider.sol";
import "../ERC20.sol";

contract TestProvider is OnChainProvider {
	event RecievedQuery(string query, bytes32 endpoint, bytes32[] params, address sender);

    event TEST(uint res, bytes32 b, string s);

    bytes32 public spec1 = "Hello?";
    bytes32 public spec2 = "Reverse";
    bytes32 public spec3 = "Add";
    bytes32 public spec4 = "Double";

    /* Endpoints to Functions:
    spec1: Hello? -> returns "Hello World"
    spec2: Reverse -> returns the query string in reverse
    spec3: Add -> Adds up the values in endpointParams 
    */

    // curve 2x^2
    int[] constants = [2, 2, 0];
    uint[] parts = [0, 1000000000];
    uint[] dividers = [1]; 

    RegistryInterface registry;

    // middleware function for handling queries
	function receive(uint256 id, string userQuery, bytes32 endpoint, bytes32[] endpointParams, bool onchainSubscriber) external {
        emit RecievedQuery(userQuery, endpoint, endpointParams, msg.sender);
        Dispatch(msg.sender).respond1(id, "Hello World");
        // if(onchainSubscriber) {
        //     bytes32 hash = (endpoint);

        //     if(hash == (spec1)) {
        //         endpoint1(id, userQuery, endpointParams);
        //     } 
        //     else {
        //        revert("Invalid endpoint");
        //     }
        // }
	}

    constructor(address registryAddress) public{

        registry = RegistryInterface(registryAddress);

        // initialize in registry
        bytes32 title = "Provider1";

        bytes32[] memory params = new bytes32[](2);
        params[0] = "p1";
        params[1] = "p2";

        registry.initiateProvider(12345, title, spec1, params);

        registry.initiateProviderCurve(spec1, constants, parts, dividers);
        registry.initiateProviderCurve(spec2, constants, parts, dividers);
    }


    // return Hello World to query-maker
    function endpoint1(uint256 id, string userQuery, bytes32[] endpointParams) internal{
        //if endpoint param == 1
        Dispatch(msg.sender).respond1(id, "Hello World");
    }

    // return the hash of the query
    function endpoint2(uint256 id, string userQuery, bytes32[] endpointParams) internal{
        // endpointParams
    }

    // TODO: TEST OUT MORE RETURN VALUES (1,2,3 or 4)!

}

contract TestProvider2 is OnChainProvider {
    event RecievedQuery(string query, bytes32 endpoint, bytes32[] params, address sender);

    event TEST(uint res, bytes32 b, string s);

    bytes32 public spec1 = "Hello?";
    bytes32 public spec2 = "Reverse";
    bytes32 public spec3 = "Add";
    bytes32 public spec4 = "Double";

    /* Endpoints to Functions:
    spec1: Hello? -> returns "Hello World"
    spec2: Reverse -> returns the query string in reverse
    spec3: Add -> Adds up the values in endpointParams 
    */

    // curve 2x^2
    int[] constants = [3, 3, 0];
    uint[] parts = [0, 1000000000];
    uint[] dividers = [1]; 

    RegistryInterface registry;

    // middleware function for handling queries
    function receive(uint256 id, string userQuery, bytes32 endpoint, bytes32[] endpointParams, bool onchainSubscriber) external {
        emit RecievedQuery(userQuery, endpoint, endpointParams, msg.sender);
        Dispatch(msg.sender).respond1(id, "Goodbye World");
    }

    constructor(address registryAddress) public{

        registry = RegistryInterface(registryAddress);

        // initialize in registry
        bytes32 title = "Provder2";

        bytes32[] memory params = new bytes32[](2);
        params[0] = "p1";
        params[1] = "p2";

        registry.initiateProvider(12345, title, spec1, params);

        registry.initiateProviderCurve(spec1, constants, parts, dividers);
        registry.initiateProviderCurve(spec2, constants, parts, dividers);
    }


    // return Hello World to query-maker
    function endpoint1(uint256 id, string userQuery, bytes32[] endpointParams) internal{
        //if endpoint param == 1
        Dispatch(msg.sender).respond1(id, "Hello World");
    }

    // return the hash of the query
    function endpoint2(uint256 id, string userQuery, bytes32[] endpointParams) internal{
        // endpointParams

    }

}


/* Test Subscriber Client */
contract TestClient is Client1, Client2{

	event Result1(uint256 id, string response1);
    event Result1(uint256 id, bytes32 response1);
    event Result2(uint256 id, string response1, string response2);
    //emit RecievedQuery(userQuery, endpoint, endpointParams, msg.sender);

	ERC20 token;
	DispatchInterface dispatch;
	BondageInterface bondage;
    RegistryInterface registry;

	constructor(address tokenAddress, address dispatchAddress, address bondageAddress, address registryAddress) public {
		token = ERC20(tokenAddress);
		dispatch = DispatchInterface(dispatchAddress);
		bondage = BondageInterface(bondageAddress);
        registry = RegistryInterface(registryAddress);
	}

    /*
    Implements overloaded callback functions for Client1
    */
    function callback(uint256 id, string response1) external {
    	string memory _response1 = response1;
    	emit Result1(id, _response1);
        // do something with result
    }

    function callback(uint256 id, bytes32[] response) external {

        emit Result1(id, response[0]);
        // do something with result
    }

    // Client2 callback
    function callback(uint256 id, string response1, string response2) external {
        emit Result2(id, response1, response2);
        // do something with result
    }

    function testQuery(address oracleAddr, string query, bytes32 specifier, bytes32[] params) external {
       //emit RecievedQuery(query, specifier, params);
    	dispatch.query(oracleAddr, query, specifier, params, true, true);
    
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    	bytes memory tempEmptyStringTest = bytes(source);

    	if (tempEmptyStringTest.length == 0) {
    		return 0x0;
    	}
    	assembly {
    		result := mload(add(source, 32))
    	}
    }

}