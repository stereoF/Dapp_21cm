// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

contract DeSciRoleModel {
    address payable private _owner;
    address[] private _editors;
    // address[] private _reviewers;
    mapping(address => uint256) private _editorsIndex;
    // mapping(address => uint256) private _reviewersIndex;
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

    // function isEditor() public view returns (bool) {
    //     bool ret = false;
    //     for (uint256 i = 0; i < _editors.length; i++) {
    //         if (_editors[i] == msg.sender) {
    //             ret = true;
    //             break;
    //         }
    //     }
    //     return ret;
    // }

    function isEditor() public view returns (bool) {
        bool ret = false;
        if (_editorsIndex[msg.sender] > 0) {
            ret = true;
        }
        return ret;
    }

    function pushEditors(address[] memory editorAddrs) public onlyOwner {
        address addr;
        uint256 index;
        for (uint256 i = 0; i < editorAddrs.length; i++) {
            addr = payable(editorAddrs[i]);
            require(_editorsIndex[addr] == 0, "Duplicate editor");
            _editors.push(addr);
            index = _editors.length;
            _editorsIndex[addr] = index;
        }
    }

    function removeEditor(address[] memory editorAddrs) public onlyOwner {
        for (uint256 i = 0; i < editorAddrs.length; i++) {
            uint256 index = _editorsIndex[editorAddrs[i]];
            if (index > 0) {
                address lastEditor = _editors[_editors.length - 1];
                _editors[index - 1] = lastEditor;
                _editors.pop();
                _editorsIndex[lastEditor] = index;
                _editorsIndex[editorAddrs[i]] = 0;
            }
        }
    }

}
