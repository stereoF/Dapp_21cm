// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciRoleModel.sol";
import "./DeSciView.sol";
import "./DeSciProcess.sol";
contract DeSciPrintMain is DeSciRoleModel,DeSciView ,DeSciProcess{
    uint256 private minGasCost = 0.0001 ether;

    function setMinGasCost(uint256 amount) public onlyOwner {
        minGasCost = amount;
    }

    mapping(address => uint256) public tokenBlance;

    mapping(string => PrintInfo) private DeSciPrints;
    string[] private DeSciFileCIDs;
    mapping(address => uint256) ownerPrintCnt;
    mapping(address => string[]) reviewPrints;
    mapping(address => uint256) editPrintCnt;

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
        require(msg.value >= _amount, "Token not enough for review donate!");
        uint256 _submitTime = block.timestamp;
        address _submitAddress = msg.sender;

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
        print.fileCIDs.push(_fileCID);
        emit Submit(_fileCID, _keyInfo, _description);
        ownerPrintCnt[msg.sender] += 1;
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
            emit Published(fileCID);
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
        _owner.transfer(address(this).balance); // 计算可提现金额有误，需修改
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
