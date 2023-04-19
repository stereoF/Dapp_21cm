// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PrePrintTrack {
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    // string[] public prePrintCIDs;
    uint256 public prePrintCnt;

    mapping(uint256 => string) public prePrintCIDMap;

    function prePrintCIDs(
        uint256 _startIndex,
        uint256 _endIndex
    ) public view returns (string[] memory) {
        require(_startIndex <= _endIndex, "Invalid index range");
        require(_endIndex < prePrintCnt, "Index out of range");
        string[] memory cids = new string[](_endIndex - _startIndex + 1);
        for (uint256 i = _startIndex; i <= _endIndex; i++) {
            cids[i - _startIndex] = prePrintCIDMap[i];
        }
        return cids;
    }

    function getAuthorPapers(
        address _authorAddress,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (string[] memory authorPapers_) {
        string[] memory printsPool_ = prePrintCIDs(
            _startIndex,
            _endIndex
        );
        uint256 resultCount;

        for (uint256 i = 0; i < printsPool_.length; i++) {
            if (prePrints[printsPool_[i]].submitAddress == _authorAddress) {
                resultCount++; // step 1 - determine the result count
            }
        }

        authorPapers_ = new string[](resultCount); // step 2 - create the fixed-length array
        uint256 j;
        for (uint256 i = 0; i < printsPool_.length; i++) {
            if (prePrints[printsPool_[i]].submitAddress == _authorAddress) {
                authorPapers_[j] = printsPool_[i]; // step 3 - fill the array
                j++;
            }
        }

        return authorPapers_; // step 4 - return
    }

    struct PrePrintInfo {
        address submitAddress;
        uint256 submitTime;
        string keyInfo;
    }

    mapping(string => PrePrintInfo) public prePrints;

    event Submit(
        string fileCID,
        string keyInfo,
        address indexed submitAddress,
        uint256 indexed submitTime,
        string description
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function submit(
        string memory _fileCID,
        string memory _keyInfo,
        string memory _description
    ) external {
        require(
            prePrints[_fileCID].submitAddress == address(0),
            "The cid of file has existed!"
        );

        uint256 _submitTime = block.timestamp;
        address _submitAddress = msg.sender;

        // prePrintCIDs.push(_fileCID);
        prePrintCIDMap[prePrintCnt] = _fileCID;
        prePrintCnt++;
        prePrints[_fileCID] = PrePrintInfo({
            submitAddress: _submitAddress,
            submitTime: _submitTime,
            keyInfo: _keyInfo
        });

        emit Submit(
            _fileCID,
            _keyInfo,
            _submitAddress,
            _submitTime,
            _description
        );
    }

    receive() external payable {}

    function withdraw() public payable onlyOwner {
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
