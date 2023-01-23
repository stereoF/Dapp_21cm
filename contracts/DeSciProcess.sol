// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciView.sol";
contract DeSciProcess is DeSciView {

    mapping(string => PrintInfo) private DeSciPrints;
    string[] private DeSciFileCIDs;



    event Submit(string fileCID, string keyInfo, string description);
    event Published(string fileCID);

    function editorAssign(string memory fileCID, address editor)
        public
        onlyAdmin
    {
        PrintInfo storage printInfo = DeSciPrints[fileCID];
        require(printInfo.status == 0);
        bool notInEditorRejected = true;
        for (uint256 i = 0; i < printInfo.editorRejected.length; i++) {
            if (editor == printInfo.editorRejected[i]) {
                notInEditorRejected = false;
                break;
            }
        }
        require(notInEditorRejected);
        printInfo.editor = editor;
        printInfo.status = uint256(1); // 已分配编辑
        printInfo.editorAssignTime = block.timestamp;
        editPrintCnt[editor] += 1;
    }

    function editorReject(string memory fileCID) public onlyEditor {
        PrintInfo storage printInfo = DeSciPrints[fileCID];
        require(printInfo.status == 1);
        require(printInfo.editor == msg.sender);
        printInfo.editor = address(0);
        printInfo.status = uint256(0); // 编辑拒绝
        printInfo.editorAssignTime = 0;
        printInfo.editorRejected.push(msg.sender);
    }

    function editorApproval(string memory fileCID)
        public
        view
        onlyEditor
        returns (PrintInfo memory)
    {
        return DeSciPrints[fileCID];
    }

    function reviewerAssign(string memory fileCID, address[] memory reviewers)
        public
        onlyEditor
    {
        require(reviewers.length >= 2 && reviewers.length <= 3);
        PrintInfo storage printInfo = DeSciPrints[fileCID];
        require(printInfo.status == 1);
        printInfo.reviewers = reviewers;
        printInfo.status = uint256(2); // 已分配审稿人
        printInfo.reviewerAssignTime = block.timestamp;
        for (uint8 i = 0; i < reviewers.length; i++) {
            reviewPrints[reviewers[i]].push(fileCID);
        }
    }

    function reviewerReject(string memory fileCID) public onlyReviewer {
        PrintInfo storage printInfo = DeSciPrints[fileCID];
        require(printInfo.status == 2);
        bool inReview = false;
        for (uint256 i = 0; i < printInfo.reviewers.length; i++) {
            if (msg.sender == printInfo.reviewers[i]) {
                printInfo.reviewers[i] = printInfo.reviewers[
                    printInfo.reviewers.length - 1
                ];
                printInfo.reviewers.pop();
                inReview = true;
                break;
            }
        }
        require(inReview);
        printInfo.reviewerRejcted.push(msg.sender);
        if (printInfo.reviewers.length == 0) {
            printInfo.status = uint256(1); // 未分配审稿人
            printInfo.reviewerAssignTime = 0;
        }
        for (uint8 i = 0; i < reviewPrints[msg.sender].length; i++) {
            string memory file = reviewPrints[msg.sender][i];
            if (
                keccak256(abi.encodePacked(fileCID)) ==
                keccak256(abi.encodePacked(file))
            ) {
                reviewPrints[msg.sender][i] = reviewPrints[msg.sender][
                    reviewPrints[msg.sender].length - 1
                ];
                reviewPrints[msg.sender].pop();
                break;
            }
        }
    }

    function reviewerApproval(string memory fileCID)
        public
        view
        onlyReviewer
        returns (PrintInfo memory)
    {
        return DeSciPrints[fileCID];
    }

}
