// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciRoleModel.sol";

contract DeSciPrint is DeSciRoleModel {
    uint256 public minGasCost = 0.0001 ether;
    enum ReviewerStatus { Submit, Revise, Reject, Pass }
    enum ProcessStatus { Pending, ReviewerAssigned, EditorRejected, ReviewerRejected, AppendReviewer, Published }

    function setMinGasCost(uint256 amount) public onlyOwner {
        minGasCost = amount;
    }

    uint256 private minWithdrawValue = 0.01 ether;

    function setMinWithdrawValue(uint256 amount) public onlyOwner {
        minWithdrawValue = amount;
    }

    mapping(address => uint256) tokenBalance;

    struct ReviewInfo {
        // address fromAddr;
        // address toAddr;
        string comment;
        uint256 commentTime;
        ReviewerStatus reviewerStatus;
    }

    struct PrintInfo {
        address submitAddress;
        uint256 submitTime;
        // uint256 publishTime;
        string keyInfo;
        // string[] fileCIDs;
        string prevCID;
        string nextCID;
        // ReviewerStatus reviewerStatus;
    }

    struct ProcessInfo {
        uint256 donate;
        address editor;
        address[] reviewers;
        // uint8 passCnt;
        // uint256 status;
        ProcessStatus processStatus;
        // ReviewInfo[] reviewInfos;
    }

    mapping(string => PrintInfo) public deSciPrints;
    mapping(string => ProcessInfo) public deSciProcess;
    // mapping(string => ReviewInfo[]) private _deSciReviews;
    mapping(string => mapping(address => ReviewInfo)) public deSciReviews;
    string[] public deSciFileCIDs;
    // string[] public printsInProcess;
    // string[] public printsPublished;
    // string[] public PrintsRejected;

    function submitForReview(
        string memory _fileCID,
        string memory _keyInfo,
        uint256 _amount
    ) public payable {
        require(
            deSciPrints[_fileCID].submitAddress == address(0),
            "File cid exist!"
        );
        require(_amount > 0 && msg.value >= (_amount + minGasCost), "Not enough amount!");
        uint256 _submitTime = block.timestamp;
        address _submitAddress = msg.sender;

        PrintInfo storage print = deSciPrints[_fileCID];
        ProcessInfo storage process = deSciProcess[_fileCID];
        print.submitAddress = _submitAddress;
        print.submitTime = _submitTime;
        print.keyInfo = _keyInfo;
        // print.reviewerStatus = ReviewerStatus.Submit;
        // print.fileCIDs.push(_fileCID);
        // process.status = 0;
        process.donate = _amount;
        // DeSciFileCIDs.push(_fileCID);
        deSciFileCIDs.push(_fileCID);
    }

    function printsPool(ProcessStatus _status) public view returns (string[] memory printsPool_) {
        uint256 resultCount;

        for (uint256 i = 0; i < deSciFileCIDs.length; i++) {
            if (deSciProcess[deSciFileCIDs[i]].processStatus == _status) {
                resultCount++;  // step 1 - determine the result count
            }
        }

        printsPool_ = new string[](resultCount);  // step 2 - create the fixed-length array
        uint256 j;
        for (uint256 i = 0; i < deSciFileCIDs.length; i++) {
            if (deSciProcess[deSciFileCIDs[i]].processStatus == _status) {
                printsPool_[j] = deSciFileCIDs[i];  // step 3 - fill the array
                j++;
            }
        }

        return printsPool_; // step 4 - return
    }

    // function editorPrintsPool() public view onlyEditor returns (string[] memory) {
    //     return printsPool(ProcessStatus.Pending);
    // }

    function reviewerAssign(string memory fileCID, address[] memory reviewers_)
        public
        onlyEditor
    {
        require(reviewers_.length >= 2 && reviewers_.length <= 3);
        ProcessInfo storage processInfo = deSciProcess[fileCID];
        require(processInfo.processStatus == ProcessStatus.Pending);
        processInfo.editor = msg.sender;
        processInfo.reviewers = reviewers_;
        // for (uint i = 0; i < reviewers_.length; i++) {
        //     processInfo.reviewers.push(reviewers_[i]);
        // }
        processInfo.processStatus = ProcessStatus.ReviewerAssigned;
    }

    function getReviewers(string memory fileCID)
        external
        view
        returns (address[] memory)
    {
        return deSciProcess[fileCID].reviewers;
    } 

    function editorReject(string memory fileCID, string memory comment_)
        public
        onlyEditor
    {
        ProcessInfo storage processInfo = deSciProcess[fileCID];
        processInfo.editor = msg.sender;
        processInfo.processStatus = ProcessStatus.EditorRejected;

        ReviewInfo storage reviewInfo = deSciReviews[fileCID][msg.sender];
        reviewInfo.comment = comment_;
        reviewInfo.commentTime = block.timestamp;
        reviewInfo.reviewerStatus = ReviewerStatus.Reject;

        // PrintInfo storage printInfo = deSciPrints[fileCID];
        // printInfo.reviewerStatus = ReviewerStatus.Reject;

        // require(processInfo.editor == msg.sender);
        // if (!isAccept) {
        //     processInfo.editor = address(0);
        //     processInfo.status = uint256(0); // 编辑拒绝
        // }
    }

    // function getPapersByReviewer() external view onlyReviewer returns(string[] memory papers) {
    //     string[] memory printsInReview = printsPool(ProcessStatus.ReviewerAssigned);
    //     for (uint256 i = 0; i < printsInReview.length; i++) {
    //         string memory fileCID = printsInReview[i];
    //         address[] memory reviewers = deSciProcess[fileCID].reviewers;
    //         for (uint j =0; i < reviewers.length; j++) {
    //             if (reviewers[j] == msg.sender) {
    //                 papers.push(fileCID);
    //             }
    //         }
    //     }

    // }

    function reviewPrint(
        string memory fileCID,
        string memory reviewCID,
        ReviewerStatus status
    ) public onlyReviewer {
        require(status != ReviewerStatus.Submit, "Must change the ReviewerStatus!");
        ReviewInfo storage reviewInfo = deSciReviews[fileCID][msg.sender];
        require(reviewInfo.reviewerStatus == ReviewerStatus.Submit, "You have submitted the comments!");
        // PrintInfo storage print = deSciPrints[fileCID];

        ProcessInfo storage process = deSciProcess[fileCID];
        bool canReview = false;
        address[] memory reviewers = process.reviewers;
        for (uint256 i = 0; i < reviewers.length; i++) {
            if (reviewers[i] == msg.sender) {
                canReview = true;
                break;
            }
        }
        require(canReview, "You have no qualification to review this paper!");

        reviewInfo.comment = reviewCID;
        reviewInfo.commentTime = block.timestamp;
        reviewInfo.reviewerStatus = status;

        uint8 passCnt = 0;
        uint8 rejectCnt = 0;

        for (uint256 i = 0; i < reviewers.length; i++) {
            reviewInfo = deSciReviews[fileCID][reviewers[i]];
            if (reviewInfo.reviewerStatus == ReviewerStatus.Pass) {
                passCnt++;
            }
            if (reviewInfo.reviewerStatus == ReviewerStatus.Reject) {
                rejectCnt++;
            }
        }

        if (passCnt >= 2){
            process.processStatus = ProcessStatus.Published;
        }

        if (rejectCnt >= 2){
            process.processStatus = ProcessStatus.ReviewerRejected;
        }

        if (reviewers.length == 2 && rejectCnt == 1) {
            process.processStatus = ProcessStatus.AppendReviewer;
        }

        // // process.passCnt += isPass;
        // if (process.passCnt >= 2) {
        //     process.status = 3; // 已发布
        //     print.publishTime = block.timestamp;
        //     for (uint8 i = 0; i < process.reviewers.length; i++) {
        //         tokenBalance[process.reviewers[i]] +=
        //             process.donate /
        //             (process.reviewers.length + 1);
        //     }
        // }
        // process.reviewInfos.push(
        //     ReviewInfo({
        //         remark: reviewCID,
        //         rmkTime: block.timestamp,
        //         fromAddr: msg.sender,
        //         toAddr: print.submitAddress
        //     })
        // );
    }

    // function replyReviewInfo(
    //     string memory fileCID,
    //     string memory newFileCID,
    //     string[] memory replyInfos,
    //     address[] memory toEditors
    // ) public {
    //     require(replyInfos.length == toEditors.length);
    //     ProcessInfo storage process = DeSciProcess[fileCID];
    //     PrintInfo storage print = DeSciPrints[fileCID];

    //     require(print.submitAddress == msg.sender);
    //     print.fileCIDs.push(newFileCID);
    //     for (uint8 i = 0; i < replyInfos.length; i++) {
    //         process.reviewInfos.push(
    //             ReviewInfo({
    //                 remark: replyInfos[i],
    //                 rmkTime: block.timestamp,
    //                 fromAddr: msg.sender,
    //                 toAddr: toEditors[i]
    //             })
    //         );
    //     }
    // }

    // function editorAssign(string memory fileCID, address editor)
    //     public
    //     onlyOwner
    // {
    //     ProcessInfo storage processInfo = DeSciProcess[fileCID];
    //     require(processInfo.status == 0);
    //     processInfo.editor = editor;
    //     processInfo.status = uint256(1); // 已分配编辑
    // }

    // function reviewerConfirm(string memory fileCID, bool isAccept)
    //     public
    //     onlyReviewer
    // {
    //     ProcessInfo storage processInfo = DeSciProcess[fileCID];
    //     require(processInfo.status == 2);
    //     if (!isAccept) {
    //         bool inReview = false;
    //         for (uint256 i = 0; i < processInfo.reviewers.length; i++) {
    //             if (msg.sender == processInfo.reviewers[i]) {
    //                 processInfo.reviewers[i] = processInfo.reviewers[
    //                     processInfo.reviewers.length - 1
    //                 ];
    //                 processInfo.reviewers.pop();
    //                 inReview = true;
    //                 break;
    //             }
    //         }
    //         if (processInfo.reviewers.length == 0) {
    //             processInfo.status = uint256(1); // 未分配审稿人
    //         }
    //     }
    // }

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
