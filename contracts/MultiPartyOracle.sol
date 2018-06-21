pragma solidity ^0.4.24;

import "./MPOStorage.sol";
import "./OnChainProvider.sol";
import "./Client.sol";

contract MultiPartyOracle is OnChainProvider, Client1 {

  event ReceivedQuery(string query, bytes32 endpoint, bytes32[] params);

  event ReceivedResponse(uint256 queryId, address responder, string response);

  MPOStorage stor;
  address public storageAddress;

  constructor(address _storageAddress, address[] _responders, address _client, uint256 _threshold) public {
    stor = MPOStorage(_storageAddress);
    stor.setThreshold(_threshold);
    stor.setResponders(_responders);
    stor.setClient(_client);
  }

// <<<<<<< HEAD
//   function submitResponse1(uint256 queryId, string response) {
//     require(stor.getAddressStatus(msg.sender) && !stor.getQueryStatus(queryId));
//     stor.addResponse(queryId, response, msg.sender);
// =======

  function receive(uint256 id, string userQuery, bytes32 endpoint, bytes32[] endpointParams) external {
    //TODO: queryId will eventually be given by dispatch

    emit ReceivedQuery(userQuery, endpoint, endpointParams);

    // query each of the responders
    for(uint i=0; i<stor.getNumResponders(); i++){
      OnChainProvider(stor.getResponderAddress(i)).receive(id, userQuery, endpoint, endpointParams);
    }

  }

  function callback(uint256 queryId, string response) external {
    require(stor.getAddressStatus(msg.sender) && !stor.getQueryStatus(queryId));
    stor.addResponse(queryId, response, msg.sender);

    emit ReceivedResponse(queryId, msg.sender, response);

    if(stor.getTally(queryId, response) >= stor.getThreshold()) {
      Client1(stor.getClient()).callback(queryId, response);
    }
  }
}
