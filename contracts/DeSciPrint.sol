// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciRoleModel.sol";
// import "hardhat/console.sol";

contract DeSciPrint is DeSciRoleModel {

    // minGasCost, editorActGas, reviewerActGas, minWithdrawValue, minDonate
    uint256[5] public gasFee = [0.0004 ether, 0.0002 ether, 0.0001 ether, 0.01 ether, 2000 gwei];

    function setGasFee(uint256 amount, uint8 index) public onlyOwner {
        gasFee[index] = amount;
        require(gasFee[0] >= gasFee[1] + gasFee[2], 'The minGas should cover editor and reviewer cost');
    }

    // reviewerPass, reviewerRevise, reviewerReject, reviewerAssign, reviewerAppend, reviewerRemove, editorReject, published, contractTakeRate
    uint256[9] public bonusWeight = [3,6,3,3,1,1,1,2,5];
    
    function _getBonus(uint256 total, uint8 index) private view returns(uint256 bonus) {
        uint256 sum;
        for (uint8 i = 0; i < 9; i++) {
            sum += bonusWeight[i];
        }
        bonus = (total/sum) * bonusWeight[index];
    }

    function setBonusWeight(uint256 amount, uint8 index) public onlyOwner {
        bonusWeight[index] = amount;
    }

    uint8 public editorActLimit = 4;

    function setEditorActLimit(uint8 limitCnt) public onlyOwner {
        editorActLimit = limitCnt;
    }
    
    enum ReviewerStatus { Submit, Revise, Reject, Pass }
    enum ProcessStatus { Pending, ReviewerAssigned, EditorRejected, ReviewerRejected, AppendReviewer, NeedRevise, RepliedNew, Published }

    mapping(address => uint256) tokenBalance;
    address[] balanceAddrs;
    mapping(address => uint256) balanceIndex;

    function _addToken(address balanceOwner, uint256 amount) private {
        if (balanceIndex[balanceOwner] == 0 ) {
            balanceAddrs.push(balanceOwner);
            balanceIndex[balanceOwner] = balanceAddrs.length;
        }
        tokenBalance[balanceOwner] += amount;
    }

    function _assignToken(address addr, uint8 bonusIndex, string memory fileCID) private {
        ProcessInfo storage processInfo = deSciProcess[fileCID];
        uint actionBonus = _getBonus(processInfo.donate, bonusIndex);
        if (processInfo.donateUsed + actionBonus <= processInfo.donate) {
            processInfo.donateUsed += actionBonus;
            _addToken(addr, actionBonus);
        }
        else if (processInfo.donateUsed < processInfo.donate) {
            processInfo.donateUsed = processInfo.donate;
            _addToken(addr, processInfo.donate - processInfo.donateUsed);
        }
    }

    function _clearBalance(address addr) private {
        tokenBalance[addr] = 0;
        uint256 index = balanceIndex[addr];
        if (index > 0) {
            address lastAddr = balanceAddrs[balanceAddrs.length - 1];
            balanceAddrs[index - 1] = lastAddr;
            balanceAddrs.pop();
            balanceIndex[addr] = 0;
            balanceIndex[lastAddr] = index;
        }
    }

    struct ReviewInfo {
        string comment;
        uint256 commentTime;
        ReviewerStatus reviewerStatus;
        string reply;
        uint256 replyTime;
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
        uint8 editorActCnt;
        uint256 donateUsed;
    }

    mapping(string => PrintInfo) public deSciPrints;
    mapping(string => ProcessInfo) public deSciProcess;
    mapping(string => mapping(address => ReviewInfo)) public deSciReviews;
    mapping(string => mapping(address => uint256)) public reviewerIndex;
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
        require(_amount >= gasFee[4] && msg.value >= (_amount + gasFee[0]), "Not enough amount!");
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

    modifier canOperate(string memory fileCID) {
        ProcessInfo storage processInfo = deSciProcess[fileCID];
        require(processInfo.editor == msg.sender || processInfo.editor == address(0), "Can't be processed by different editor");
        require(
            processInfo.processStatus == ProcessStatus.Pending || processInfo.processStatus == ProcessStatus.AppendReviewer,
            "Can only assign to pending or append-need paper"
        );
        _;
    }

    modifier checkProcessStatus(string memory fileCID) {
        _;
        ProcessInfo storage process = deSciProcess[fileCID];
        address[] memory reviewers = process.reviewers;
        uint256 totalCnt = reviewers.length;
        require(totalCnt <= 3, 'No more than 3 reviewers');

        uint8 passCnt = 0;
        uint8 rejectCnt = 0;
        uint8 reviseCnt = 0;
        uint8 submitCnt = 0;

        for (uint256 i = 0; i < reviewers.length; i++) {
            ReviewInfo storage reviewInfo = deSciReviews[fileCID][reviewers[i]];
            if (reviewInfo.reviewerStatus == ReviewerStatus.Pass) {
                passCnt++;
            }
            else if (reviewInfo.reviewerStatus == ReviewerStatus.Reject) {
                rejectCnt++;
            }
            else if (reviewInfo.reviewerStatus == ReviewerStatus.Revise) {
                reviseCnt++;
            }
            else {
                submitCnt++;
            }
        }

        if (totalCnt < 2) {
            process.processStatus = ProcessStatus.AppendReviewer;
        }
        else {
            if (passCnt >= 2){
                process.processStatus = ProcessStatus.Published;
                _assignToken(process.editor, 7, fileCID);
            }
            else if (rejectCnt >= 2){
                process.processStatus = ProcessStatus.ReviewerRejected;
            }
            else if (totalCnt == 2 && rejectCnt == 1) {
                process.processStatus = ProcessStatus.AppendReviewer;
            }
            else if (submitCnt == 0  && reviseCnt+passCnt >= 2) {
                process.processStatus = ProcessStatus.NeedRevise;
            }
            else {
                process.processStatus = ProcessStatus.ReviewerAssigned;
            }
        }
    }

    function _reviewerAssign(string memory fileCID, address[] memory reviewers_)
        private
    {
        ProcessInfo storage processInfo = deSciProcess[fileCID];

        address addr;
        uint256 index;
        for (uint8 i = 0; i < reviewers_.length; i++) {
            addr = payable(reviewers_[i]);
            require(reviewerIndex[fileCID][addr] == 0, "Duplicate reviewer");
            processInfo.reviewers.push(addr);
            index = processInfo.reviewers.length;
            reviewerIndex[fileCID][addr] = index;
        }
    }

    function reviewerAssign(string memory fileCID, address[] memory reviewers_)
        public
        onlyEditor
        canOperate(fileCID)
        checkProcessStatus(fileCID)
    {
        require(reviewers_.length > 0, 'Need more than 1 reviewer');
        ProcessInfo storage processInfo = deSciProcess[fileCID];

        if (processInfo.editor == address(0)) {
            processInfo.editor = msg.sender;
        }

        _reviewerAssign(fileCID, reviewers_);

        processInfo.editorActCnt++;
        if (processInfo.editorActCnt == 1) {
            _addToken(msg.sender, gasFee[1]);
        }
        if (processInfo.editorActCnt <= editorActLimit) {
            uint8 bonusIndex = (processInfo.processStatus == ProcessStatus.AppendReviewer) ? 4:3;
            _assignToken(msg.sender, bonusIndex, fileCID);
        }
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
        canOperate(fileCID)
    {
        ProcessInfo storage processInfo = deSciProcess[fileCID];
        processInfo.editor = msg.sender;
        processInfo.processStatus = ProcessStatus.EditorRejected;

        ReviewInfo storage reviewInfo = deSciReviews[fileCID][msg.sender];
        reviewInfo.comment = comment_;
        reviewInfo.commentTime = block.timestamp;
        reviewInfo.reviewerStatus = ReviewerStatus.Reject;

        processInfo.editorActCnt++;
        if (processInfo.editorActCnt == 1) {
            _addToken(msg.sender, gasFee[1]);
        }
        if (processInfo.editorActCnt <= editorActLimit) {
            _assignToken(msg.sender, 6, fileCID);
        }
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
    ) public onlyReviewer(fileCID) checkProcessStatus(fileCID) {
        require(status != ReviewerStatus.Submit, "Must change the ReviewerStatus!");
        ReviewInfo storage reviewInfo = deSciReviews[fileCID][msg.sender];
        require(reviewInfo.reviewerStatus == ReviewerStatus.Submit, "You have submitted the comments!");

        reviewInfo.comment = reviewCID;
        reviewInfo.commentTime = block.timestamp;
        reviewInfo.reviewerStatus = status;

        _addToken(msg.sender, gasFee[2]);

        uint8 bonusIndex;
        if (status == ReviewerStatus.Pass) {
            bonusIndex = 0;
        }
        else if (status == ReviewerStatus.Revise) {
            bonusIndex = 1;
        }
        else {
            bonusIndex = 2;
        }
        _assignToken(msg.sender, bonusIndex, fileCID);
    }

    modifier onlyAuthor(string memory fileCID) {
        require(deSciPrints[fileCID].submitAddress == msg.sender, "You are not the author!");
        _;
    }

    function replyReviewInfo(
        string memory fileCID,
        address reviewer,
        string memory replyCID
    ) public onlyAuthor(fileCID) {
        require(_isReviewer(fileCID, reviewer), "Not the reviewer");
        ReviewInfo storage reviewInfo = deSciReviews[fileCID][reviewer];
        require(reviewInfo.reviewerStatus != ReviewerStatus.Submit, "Cannot reply before comment submitted");
        reviewInfo.reply = replyCID;
        reviewInfo.replyTime = block.timestamp;
    }

    function replyNew(
        string memory preFileCID,
        string memory _fileCID,
        string memory _keyInfo,
        uint256 _amount
    ) public payable onlyAuthor(preFileCID) checkProcessStatus(_fileCID) {
        ProcessInfo storage preProcess = deSciProcess[preFileCID];
        require(preProcess.processStatus == ProcessStatus.NeedRevise, 'The status should be NeedRevise');
        submitForReview(_fileCID, _keyInfo, _amount);
        PrintInfo storage prePrintInfo = deSciPrints[preFileCID];
        prePrintInfo.nextCID = _fileCID;
        preProcess.processStatus = ProcessStatus.RepliedNew;
        PrintInfo storage printInfo = deSciPrints[_fileCID];
        printInfo.prevCID = preFileCID;
        ProcessInfo storage processInfo = deSciProcess[_fileCID];
        processInfo.editor = preProcess.editor;
        _reviewerAssign(_fileCID, preProcess.reviewers);
    }

    function removeReviewer(string memory fileCID, address[] memory _reviewers) 
        public
        onlyEditor
        canOperate(fileCID)
        checkProcessStatus(fileCID)
    {
        require(_reviewers.length > 0, 'Need remove at least 1 reviewer');
        ProcessInfo storage processInfo = deSciProcess[fileCID];
        address[] storage reviewers = processInfo.reviewers;
        for (uint256 i = 0; i < _reviewers.length; i++) {
            require(
                deSciReviews[fileCID][_reviewers[i]].reviewerStatus == ReviewerStatus.Submit,
                "Can only remove no action reviewer"
            );
            uint256 index = reviewerIndex[fileCID][_reviewers[i]];
            if (index > 0) {
                address lastReviewer = reviewers[reviewers.length - 1];
                reviewers[index - 1] = lastReviewer;
                reviewers.pop();
                reviewerIndex[fileCID][_reviewers[i]] = 0;
                reviewerIndex[fileCID][lastReviewer] = index;
            }
        }
        processInfo.editorActCnt++;
        if (processInfo.editorActCnt <= editorActLimit) {
            _assignToken(msg.sender, 5, fileCID);
        }
    }

    function changeEditor(string memory fileCID, address newEditor)
        public 
        onlyOwner
    {
        deSciProcess[fileCID].editor = newEditor;
    }

    receive() external payable {}

    // Use this very carefully. Use withdrawAvalible in most cases.
    function withdrawAll() public payable onlyOwner {
        require(address(this).balance > 0);
        address payable _owner = owner();
        for (uint256 i = 0; i < balanceAddrs.length; i++) {
            _clearBalance(balanceAddrs[i]);
        }
        _owner.transfer(address(this).balance);
    }

    function totalUserBalance() public view returns(uint256 total) {
        for (uint256 i = 0; i < balanceAddrs.length; i++) {
            total += tokenBalance[balanceAddrs[i]];
        }
    }

    function withdrawAvalible() public payable onlyOwner {
        uint256 balanceLeft = totalUserBalance();
        uint256 withdrawAmount = address(this).balance - balanceLeft;
        require(withdrawAmount > 0, 'Not enough balance');
        address payable _owner = owner();
        _owner.transfer(withdrawAmount);
    }

    function withdrawToken() public payable {
        require(tokenBalance[msg.sender] > gasFee[3]);
        _clearBalance(msg.sender);
        payable(msg.sender).transfer(tokenBalance[msg.sender]);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
