pragma solidity ^0.4.24;

import "./MPOStorage.sol";
import "./OnChainProvider.sol";
import "./Client.sol";

import "../ERC20.sol";
import "../lifecycle/Destructible.sol";

import "../../platform/bondage/BondageInterface.sol";
import "../../platform/registry/RegistryInterface.sol";
import "../../platform/dispatch/DispatchInterface.sol";

contract MultiPartyOracle is OnChainProvider, Client1 {
  event RecievedQuery(string query, bytes32 endpoint, bytes32[] params, address sender);
  event ReceivedResponse(uint256 queryId, address responder, string response);

    event Result1(uint256 id, string response1);
    //event TEST(uint res, bytes32 b, string s);

    bytes32 public spec1 = "Hello?";

    // curve 2x^2
    int[] constants = [2, 2, 0];
    uint[] parts = [0, 1000000000];
    uint[] dividers = [1]; 

    DispatchInterface dispatch;
    RegistryInterface registry;
    address dispatchAddress;
    MPOStorage stor;
    address public storageAddress;
    
    // middleware function for handling queries
  function receive(uint256 id, string userQuery, bytes32 endpoint, bytes32[] endpointParams, bool onchainSubscriber) external {
        emit RecievedQuery(userQuery, endpoint, endpointParams, msg.sender);
        //emit RecievedQuery(userQuery, endpoint, endpointParams, dispatchAddress);
        require(msg.sender == dispatchAddress && stor.getQueryStatus(id) == 0 );

        stor.setClientQueryId(id);
        bytes32 hash = keccak256(endpoint);
        // if(hash == spec1) {
            //endpoint1(id, userQuery, endpointParams);
            stor.setQueryStatus(id,1);
            // query each of the responders
            for(uint i=0; i<stor.getNumResponders(); i++) {      
              dispatch.query(stor.getResponderAddress(i),userQuery,endpoint,endpointParams, true, true);
              //OnChainProvider(stor.getResponderAddress(i)).receive(id, userQuery, endpoint, endpointParams, true);
            }
        //}
  }
    constructor(address registryAddress, address _dispatchAddress, address mpoStorageAddress) public{

        registry = RegistryInterface(registryAddress);
        dispatch = DispatchInterface(_dispatchAddress);
        stor = MPOStorage(mpoStorageAddress);
        dispatchAddress = _dispatchAddress;

        // initialize in registry
        bytes32 title = "MultiPartyOracle";

        bytes32[] memory params = new bytes32[](2);
        params[0] = "p1";

        registry.initiateProvider(12345, title, spec1, params);

        registry.initiateProviderCurve(spec1, constants, parts, dividers);
        // registry.initiateProviderCurve(spec2, constants, parts, dividers);
        // registry.initiateProviderCurve(spec3, constants, parts, dividers);
        // registry.initiateProviderCurve(spec4, constants, parts, dividers);
    }

    function setParams(address[] _responders, address _client, uint256 _threshold) public {
        require(_threshold>0 && _threshold <= _responders.length);    
        stor.setThreshold(_threshold);
        stor.setResponders(_responders);
        stor.setClient(_client);
    }


    // return Hello World to query-maker
    function endpoint1(uint256 id, string userQuery, bytes32[] endpointParams) internal{
        Dispatch(msg.sender).respond1(id, "Hello World");
        // stor.setQueryStatus(id,1);

        // // query each of the responders
        // for(uint i=0; i<stor.getNumResponders(); i++){      
        //   OnChainProvider(stor.getResponderAddress(i)).receive(id, userQuery, endpoint, endpointParams);
        // }
    }

    function callback(uint256 queryId, string response) external {
        require(msg.sender == dispatchAddress);
        //emit Result1(queryId, response);
        stor.addResponse(queryId, response, msg.sender);
        emit ReceivedResponse(queryId, msg.sender, response);
    
         if(stor.getTally(queryId, response) >= stor.getThreshold() && stor.getQueryStatus(stor.getClientQueryId()) == 1) {
            stor.setQueryStatus(stor.getClientQueryId(), 2);
            emit Result1(queryId, response);
            dispatch.respond1(stor.getClientQueryId(), response);
         }
  }

}