// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract DeSciRoleModel {
    address payable private _owner;
    address[] private _administrators;
    address[] private _editors;
    address[] private _reviewers;
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

    function assignAdministrator(address payable admin) public onlyOwner {
        _administrators.push(admin);
    }

    modifier onlyAdmin() {
        require(isAdmin());
        _;
    }

    function isAdmin() public view returns (bool) {
        bool ret = false;
        for (uint256 i = 0; i < _administrators.length; i++) {
            if (_administrators[i] == msg.sender) {
                ret = true;
                break;
            }
        }
        return ret;
    }

    function pushEditor(address payable editor) internal onlyAdmin {
        _editors.push(editor);
    }

    function pushReviewer(address payable reviewer) internal onlyAdmin {
        _reviewers.push(reviewer);
    }

    function removeEditor(address payable editor) internal onlyAdmin {
        bool ret = false;
        uint256 index;
        for (uint256 i = 0; i < _editors.length; i++) {
            if (_editors[i] == editor) {
                ret = true;
                index = i;
                break;
            }
        }
        if (ret) {
            removeElement(_editors, index);
        }
    }

    function removeReviewer(address payable reviewer) internal onlyAdmin {
        bool ret = false;
        uint256 index;
        for (uint256 i = 0; i < _reviewers.length; i++) {
            if (_reviewers[i] == reviewer) {
                ret = true;
                index = i;
                break;
            }
        }
        if (ret) {
            removeElement(_reviewers, index);
        }
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

    function removeElement(address[] storage arr, uint256 index) internal {
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
}
