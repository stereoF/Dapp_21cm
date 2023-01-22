// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciRoleModel.sol";

contract DeSciPrintFactory is DeSciRoleModel {
    uint256 private minGasCost = 0.0001 ether;

    function setMinGasCost(uint256 amount) public onlyOwner {
        minGasCost = amount;
    }

    mapping(address => uint256) public tokenBlance;
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

    event Submit(string fileCID, string keyInfo, string description);
    event EditorAssign(string fileCID, address editor);
    event ReviewAssign(string fileCID, address[] reviewers);

    function submitForReview(
        string memory _fileCID,
        string memory _keyInfo,
        string memory _description,
        uint256 _amount
    ) public payable {
        require(
            DeSciPrints[_fileCID].submitAddress == address(0),
            "The cid of file has existed!"
        );

        require(msg.value >= minGasCost, "Token not enough for review action!");
        uint256 _submitTime = block.timestamp;
        address _submitAddress = msg.sender;
        address[] memory _reviews;
        address[] memory _editorRejected;
        address[] memory _reviewerRejcted;
        ReviewInfo[] memory _reviewInfos;

        PrintInfo storage print = DeSciPrints[_fileCID];
        print.submitAddress = _submitAddress;
        print.submitTime = _submitTime;
        print.editorAssignTime = 0;
        print.reviewerAssignTime = 0;
        print.publicTime = 0;
        print.keyInfo = _keyInfo;
        print.status = 0;
        print.editor = address(0);
        print.reviewCost = _amount - minGasCost;
        print.reviewers = _reviews;
        print.passReviewCnt = 0;
        print.reviewInfos = _reviewInfos;
        print.editorRejected = _editorRejected;
        print.reviewerRejcted = _reviewerRejcted;
        print.fileCIDs.push(_fileCID);
        emit Submit(_fileCID, _keyInfo, _description);
        ownerPrintCnt[msg.sender] += 1;
    }

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

    function assignReviewer(string memory fileCID, address[] memory reviewers)
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

    function reviewPrint(
        string memory fileCID,
        string memory reviewDescription,
        uint8 passStatus
    ) public onlyReviewer {
        PrintInfo storage printInfo = DeSciPrints[fileCID];
        bool canReview = false;
        address[] memory reviewers = printInfo.reviewers;
        for (uint256 i = 0; i < reviewers.length; i++) {
            if (reviewers[i] == msg.sender) {
                canReview = true;
                break;
            }
        }
        require(canReview);
        printInfo.passReviewCnt += passStatus;
        if (printInfo.passReviewCnt >= 2) {
            printInfo.status = 3; // 已发布
            publishedCnt += 1;
        }
        printInfo.reviewInfos.push(
            ReviewInfo({
                remark: reviewDescription,
                rmkTime: block.timestamp,
                fromAddr: msg.sender,
                toAddr: printInfo.submitAddress
            })
        );
    }

    function replyReviewInfo(
        string memory fileCID,
        string memory newFileCID,
        string[] memory replyInfos,
        address[] memory toEditors
    ) public {
        require(replyInfos.length == toEditors.length);
        PrintInfo storage printInfo = DeSciPrints[fileCID];
        require(printInfo.submitAddress == msg.sender);
        printInfo.fileCIDs.push(newFileCID);
        for (uint8 i = 0; i < replyInfos.length; i++) {
            printInfo.reviewInfos.push(
                ReviewInfo({
                    remark: replyInfos[i],
                    rmkTime: block.timestamp,
                    fromAddr: msg.sender,
                    toAddr: toEditors[i]
                })
            );
        }
    }

    receive() external payable {}

    function withdraw() public payable onlyOwner {
        require(address(this).balance > 0);
        address payable _owner = owner();
        _owner.transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
