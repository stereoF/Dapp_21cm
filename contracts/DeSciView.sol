// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciRoleModel.sol";

contract DeSciView is DeSciRoleModel {
    struct ReviewInfo {
        string remark;
        uint256 rmkTime;
        address fromAddr;
        address toAddr;
    }
    struct PrintInfo {
        address submitAddress;
        uint256 submitTime;
        uint256 editorAssignTime;
        uint256 reviewerAssignTime;
        uint256 publicTime;
        string keyInfo;
        uint256 status;
        address editor;
        uint256 reviewCost;
        address[] reviewers;
        uint8 passReviewCnt;
        ReviewInfo[] reviewInfos;
        address[] editorRejected;
        address[] reviewerRejcted;
        string[] fileCIDs;
    }

    mapping(string => PrintInfo) private DeSciPrints;
    string[] private DeSciFileCIDs;
    uint256 public publishedCnt = 0;
    mapping(address => uint256) ownerPrintCnt;
    mapping(address => string[]) reviewPrints;
    mapping(address => uint256) editPrintCnt;

    function getOwnerPrints() public view returns (PrintInfo[] memory) {
        PrintInfo[] memory ownerPrintInfos = new PrintInfo[](
            ownerPrintCnt[msg.sender]
        );
        for (uint256 i = 0; i < DeSciFileCIDs.length; i++) {
            if (DeSciPrints[DeSciFileCIDs[i]].submitAddress == msg.sender) {
                ownerPrintInfos[i] = DeSciPrints[DeSciFileCIDs[i]];
            }
        }
        return ownerPrintInfos;
    }

    function getPublishedPrints() public view returns (PrintInfo[] memory) {
        PrintInfo[] memory publishedPrintInfos = new PrintInfo[](publishedCnt);
        for (uint256 i = 0; i < DeSciFileCIDs.length; i++) {
            if (DeSciPrints[DeSciFileCIDs[i]].status == 3) {
                publishedPrintInfos[i] = DeSciPrints[DeSciFileCIDs[i]];
            }
        }
        return publishedPrintInfos;
    }

    function getInEditPrints()
        public
        view
        onlyEditor
        returns (PrintInfo[] memory)
    {
        PrintInfo[] memory editingPrintInfos = new PrintInfo[](
            editPrintCnt[msg.sender]
        );
        for (uint256 i = 0; i < DeSciFileCIDs.length; i++) {
            if (DeSciPrints[DeSciFileCIDs[i]].editor == msg.sender) {
                editingPrintInfos[i] = DeSciPrints[DeSciFileCIDs[i]];
            }
        }
        return editingPrintInfos;
    }

    function getInReviewPrints()
        public
        view
        onlyReviewer
        returns (PrintInfo[] memory)
    {
        PrintInfo[] memory reviewPrintInfos = new PrintInfo[](
            reviewPrints[msg.sender].length
        );
        for (uint256 i = 0; i < reviewPrints[msg.sender].length; i++) {
            reviewPrintInfos[i] = DeSciPrints[reviewPrints[msg.sender][i]];
        }
        return reviewPrintInfos;
    }
}
