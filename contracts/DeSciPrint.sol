// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciRoleModel.sol";

contract DeSciPrint is DeSciRoleModel {
    uint256 public minGasCost = 0.0001 ether;

    function setMinGasCost(uint256 amount) public onlyOwner {
        minGasCost = amount;
    }

    uint256 private minWithdrawValue = 0.01 ether;

    function setMinWithdrawValue(uint256 amount) public onlyOwner {
        minWithdrawValue = amount;
    }

    mapping(address => uint256) tokenBalance;
    struct ReviewInfo {
        address fromAddr;
        address toAddr;
        string remark;
        uint256 rmkTime;
    }
    struct PrintInfo {
        address submitAddress;
        uint256 submitTime;
        uint256 publishTime;
        string keyInfo;
        string[] fileCIDs;
    }
    struct ProcessInfo {
        uint256 donate;
        address editor;
        address[] reviewers;
        uint8 passCnt;
        uint256 status;
        ReviewInfo[] reviewInfos;
    }

    mapping(string => PrintInfo) public DeSciPrints;
    mapping(string => ProcessInfo) public DeSciProcess;
    string[] public DeSciFileCIDs;

    function submitForReview(
        string memory _fileCID,
        string memory _keyInfo,
        uint256 _amount
    ) public payable {
        require(
            DeSciPrints[_fileCID].submitAddress == address(0),
            "File cid exist!"
        );
        // require(msg.value >= minGasCost, "Not enough gas!");
        require(_amount > 0 && msg.value >= (_amount + minGasCost), "Not enough amount!");
        uint256 _submitTime = block.timestamp;
        address _submitAddress = msg.sender;

        PrintInfo storage print = DeSciPrints[_fileCID];
        ProcessInfo storage process = DeSciProcess[_fileCID];
        print.submitAddress = _submitAddress;
        print.submitTime = _submitTime;
        print.keyInfo = _keyInfo;
        print.fileCIDs.push(_fileCID);
        process.status = 0;
        process.donate = _amount;
        DeSciFileCIDs.push(_fileCID);
    }

    function reviewPrint(
        string memory fileCID,
        string memory reviewCID,
        uint8 isPass
    ) public onlyReviewer {
        ProcessInfo storage process = DeSciProcess[fileCID];
        PrintInfo storage print = DeSciPrints[fileCID];

        bool canReview = false;
        address[] memory reviewers = process.reviewers;
        for (uint256 i = 0; i < reviewers.length; i++) {
            if (reviewers[i] == msg.sender) {
                canReview = true;
                break;
            }
        }
        require(canReview);
        process.passCnt += isPass;
        if (process.passCnt >= 2) {
            process.status = 3; // 已发布
            print.publishTime = block.timestamp;
            for (uint8 i = 0; i < process.reviewers.length; i++) {
                tokenBalance[process.reviewers[i]] +=
                    process.donate /
                    (process.reviewers.length + 1);
            }
        }
        process.reviewInfos.push(
            ReviewInfo({
                remark: reviewCID,
                rmkTime: block.timestamp,
                fromAddr: msg.sender,
                toAddr: print.submitAddress
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
        ProcessInfo storage process = DeSciProcess[fileCID];
        PrintInfo storage print = DeSciPrints[fileCID];

        require(print.submitAddress == msg.sender);
        print.fileCIDs.push(newFileCID);
        for (uint8 i = 0; i < replyInfos.length; i++) {
            process.reviewInfos.push(
                ReviewInfo({
                    remark: replyInfos[i],
                    rmkTime: block.timestamp,
                    fromAddr: msg.sender,
                    toAddr: toEditors[i]
                })
            );
        }
    }

    function editorAssign(string memory fileCID, address editor)
        public
        onlyOwner
    {
        ProcessInfo storage processInfo = DeSciProcess[fileCID];
        require(processInfo.status == 0);
        processInfo.editor = editor;
        processInfo.status = uint256(1); // 已分配编辑
    }

    function editorConfirm(string memory fileCID, bool isAccept)
        public
        onlyEditor
    {
        ProcessInfo storage processInfo = DeSciProcess[fileCID];
        require(processInfo.editor == msg.sender);
        if (!isAccept) {
            processInfo.editor = address(0);
            processInfo.status = uint256(0); // 编辑拒绝
        }
    }

    function reviewerAssign(string memory fileCID, address[] memory reviewers)
        public
        onlyEditor
    {
        require(reviewers.length >= 2 && reviewers.length <= 3);
        ProcessInfo storage processInfo = DeSciProcess[fileCID];
        require(processInfo.editor == msg.sender);
        processInfo.reviewers = reviewers;
        processInfo.status = uint256(2); // 已分配审稿人
    }

    function reviewerConfirm(string memory fileCID, bool isAccept)
        public
        onlyReviewer
    {
        ProcessInfo storage processInfo = DeSciProcess[fileCID];
        require(processInfo.status == 2);
        if (!isAccept) {
            bool inReview = false;
            for (uint256 i = 0; i < processInfo.reviewers.length; i++) {
                if (msg.sender == processInfo.reviewers[i]) {
                    processInfo.reviewers[i] = processInfo.reviewers[
                        processInfo.reviewers.length - 1
                    ];
                    processInfo.reviewers.pop();
                    inReview = true;
                    break;
                }
            }
            if (processInfo.reviewers.length == 0) {
                processInfo.status = uint256(1); // 未分配审稿人
            }
        }
    }

    receive() external payable {}

    function withdraw() public payable onlyOwner {
        require(address(this).balance > 0);
        address payable _owner = owner();
        _owner.transfer(address(this).balance);
    }

    function withdraw_token() public payable {
        require(tokenBalance[msg.sender] > minWithdrawValue);
        tokenBalance[msg.sender] = 0;
        payable(msg.sender).transfer(tokenBalance[msg.sender]);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
