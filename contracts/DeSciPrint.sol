// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciRoleModel.sol";
// import "hardhat/console.sol";

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
        string comment;
        uint256 commentTime;
        ReviewerStatus reviewerStatus;
    }

    struct PrintInfo {
        address submitAddress;
        uint256 submitTime;
        string keyInfo;
        string prevCID;
        string nextCID;
    }

    struct ProcessInfo {
        uint256 donate;
        address editor;
        address[] reviewers;
        ProcessStatus processStatus;
    }

    mapping(string => PrintInfo) public deSciPrints;
    mapping(string => ProcessInfo) public deSciProcess;
    mapping(string => mapping(address => ReviewInfo)) public deSciReviews;
    mapping(string => mapping(address => uint8)) public reviewerIndex;
    string[] public deSciFileCIDs;

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
        process.donate = _amount;
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


    function reviewerAssign(string memory fileCID, address[] memory reviewers_)
        public
        onlyEditor
    {
        ProcessInfo storage processInfo = deSciProcess[fileCID];
        require(processInfo.editor == msg.sender || processInfo.editor == address(0), "Can't be processed by different editor");
        require(
            processInfo.processStatus == ProcessStatus.Pending || processInfo.processStatus == ProcessStatus.AppendReviewer,
            "Can only assign to pending or append-need paper"
            );

        if (processInfo.editor == address(0)) {
            processInfo.editor = msg.sender;
        }

        address addr;
        uint8 index;
        for (uint8 i = 0; i < reviewers_.length; i++) {
            addr = payable(reviewers_[i]);
            require(reviewerIndex[fileCID][addr] == 0, "Duplicate reviewer");
            processInfo.reviewers.push(addr);
            index = uint8(processInfo.reviewers.length);
            reviewerIndex[fileCID][addr] = index;
        }
        require(processInfo.reviewers.length >= 2 && processInfo.reviewers.length <= 3, 'Need 2 or 3 reviewers');
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
    }

    function _isReviewer(string memory fileCID, address reviewer) public view returns (bool) {
        ProcessInfo storage process = deSciProcess[fileCID];
        bool canReview = false;
        address[] memory reviewers = process.reviewers;
        for (uint256 i = 0; i < reviewers.length; i++) {
            if (reviewers[i] == reviewer) {
                canReview = true;
                break;
            }
        }
        return canReview;
    }

    modifier onlyReviewer(string memory fileCID) {
        require(_isReviewer(fileCID, msg.sender), "You have no qualification to review this paper!");
        _;
    }

    function reviewPrint(
        string memory fileCID,
        string memory reviewCID,
        ReviewerStatus status
    ) public onlyReviewer(fileCID) {
        require(status != ReviewerStatus.Submit, "Must change the ReviewerStatus!");
        ReviewInfo storage reviewInfo = deSciReviews[fileCID][msg.sender];
        require(reviewInfo.reviewerStatus == ReviewerStatus.Submit, "You have submitted the comments!");

        ProcessInfo storage process = deSciProcess[fileCID];
        address[] memory reviewers = process.reviewers;

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
