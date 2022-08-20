// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

contract PrePrintTrack {
    address payable public owner;

    string[] public prePrintCIDs;

    struct PrePrintInfo {
        address submitAddress; 
        uint submitTime; 
    }

    mapping (string => PrePrintInfo) public prePrints;

    event Submit(string _fileCID, address indexed _submitAddress, uint indexed _submitTime, string _desciption);

    constructor() payable {
        owner = payable(msg.sender);
    }

    function submit(string memory _fileCID, string memory _desciption) external {
        require(prePrints[_fileCID].submitAddress == address(0), 'The cid of file has existed');

        uint _submitTime = block.timestamp;
        address _submitAddress = msg.sender;

        prePrintCIDs.push(_fileCID);
        prePrints[_fileCID] = PrePrintInfo({
            submitAddress: _submitAddress,
            submitTime: _submitTime
        });

        emit Submit(_fileCID, _submitAddress, _submitTime, _desciption);
    }
}