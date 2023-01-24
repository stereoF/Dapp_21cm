// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DeSciRoleModel {
    address payable private _owner;
    address[] private _editors;
    address[] private _reviewers;
    mapping(address => uint256) private _editorsIndex;
    mapping(address => uint256) private _reviewersIndex;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    function editors() public view returns (address[] memory) {
        return _editors;
    }

    function reviewers() public view returns (address[] memory) {
        return _reviewers;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    modifier onlyEditor() {
        require(isEditor());
        _;
    }

    function isEditor() public view returns (bool) {
        bool ret = false;
        for (uint256 i = 0; i < _editors.length; i++) {
            if (_editors[i] == msg.sender) {
                ret = true;
                break;
            }
        }
        return ret;
    }

    function pushEditors(address[] memory editorAddrs) public onlyOwner {
        address addr;
        uint256 index;
        for (uint256 i = 0; i < editorAddrs.length; i++) {
            addr = payable(editorAddrs[i]);
            _editors.push(addr);
            index = _editors.length;
            _editorsIndex[addr] = index;
        }
    }

    function removeEditor(address[] memory editorAddrs) public onlyOwner {
        for (uint256 i = 0; i < editorAddrs.length; i++) {
            uint256 index = _editorsIndex[editorAddrs[i]];
            if (index > 0) {
                _editors[index - 1] = _editors[_editors.length - 1];
                _editors.pop();
                _editorsIndex[editorAddrs[i]] = 0;
            }
        }
    }

    modifier onlyReviewer() {
        require(isReviewer());
        _;
    }

    function isReviewer() public view returns (bool) {
        bool ret = false;
        for (uint256 i = 0; i < _reviewers.length; i++) {
            if (_reviewers[i] == msg.sender) {
                ret = true;
                break;
            }
        }
        return ret;
    }

    function pushReviewers(address[] memory reviewerAddrs) public onlyOwner {
        address addr;
        uint256 index;
        for (uint256 i = 0; i < reviewerAddrs.length; i++) {
            addr = payable(reviewerAddrs[i]);
            _reviewers.push(addr);
            index = _reviewers.length;
            _reviewersIndex[addr] = index;
        }
    }

    function removeReviewer(address[] memory reviewerAddrs) public onlyOwner {
        for (uint256 i = 0; i < reviewerAddrs.length; i++) {
            uint256 index = _reviewersIndex[reviewerAddrs[i]];
            if (index > 0) {
                _reviewers[index - 1] = _reviewers[_reviewers.length - 1];
                _reviewers.pop();
                _reviewersIndex[reviewerAddrs[i]] = 0;
            }
        }
    }
}
