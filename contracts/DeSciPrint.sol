// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./DeSciRoleModel.sol";
// import "hardhat/console.sol";

contract DeSciPrint is DeSciRoleModel {

    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    // minGasCost, editorActGas, reviewerActGas, minWithdrawValue, minDonate
    uint256[5] public gasFee = [0.05 ether, 0.02 ether, 0.007 ether, 0.001 ether, 2000 gwei];

    enum ValueType { gasFee, bonus }

    event ChangeValue(
        ValueType valueType,
        uint256 indexed changeTime,
        uint256 indexed index,
        uint256 oldAmount,
        uint256 newAmount
    );

    function setGasFee(uint256 amount, uint8 index) public onlyOwner {
        emit ChangeValue(ValueType.gasFee, block.timestamp, index, gasFee[index], amount);
        gasFee[index] = amount;
        require(gasFee[0] >= gasFee[1] + 3*gasFee[2], 'The minGas should cover editor and reviewer cost');
    }

    // reviewerPass, reviewerRevise, reviewerReject, reviewerAssign, reviewerAppend, reviewerRemove, editorReject, published, contractTakeRate
    uint256[9] private _bonusWeight = [3,6,3,3,1,1,1,2,5];
    
    function _getBonus(uint256 total, uint8 index) private view returns(uint256 bonus) {
        uint256 sum;
        for (uint8 i = 0; i < 9; i++) {
            sum += _bonusWeight[i];
        }
        bonus = (total/sum) * _bonusWeight[index];
    }

    function setBonusWeight(uint256 amount, uint8 index) public onlyOwner {
        emit ChangeValue(ValueType.bonus, block.timestamp, index, _bonusWeight[index], amount);
        _bonusWeight[index] = amount;
    }

    function bonusWeight() public view returns(uint256[9] memory) {
        return _bonusWeight;
    }

    uint8 public editorActLimit = 4;

    event ChangeEditorActLimit(
        uint256 indexed changeTime,
        uint256 oldValue,
        uint256 newValue
    );

    function setEditorActLimit(uint8 limitCnt) public onlyOwner {
        emit ChangeEditorActLimit(block.timestamp, editorActLimit, limitCnt);
        editorActLimit = limitCnt;
    }
    
    enum ReviewerStatus { Submit, Revise, Reject, Pass }
    enum ProcessStatus { Pending, ReviewerAssigned, EditorRejected, ReviewerRejected, AppendReviewer, NeedRevise, RepliedNew, Published }

    mapping(address => uint256) public tokenBalance;
    address[] balanceAddrs;
    mapping(address => uint256) balanceIndex;

    event ChangeToken(
        address indexed balanceOwner,
        uint256 finalAmount,
        uint256 indexed changeTime
    );

    function _addToken(address balanceOwner, uint256 amount) private {
        if (balanceIndex[balanceOwner] == 0 ) {
            balanceAddrs.push(balanceOwner);
            balanceIndex[balanceOwner] = balanceAddrs.length;
        }
        tokenBalance[balanceOwner] += amount;
        // console.log(balanceOwner, amount);
        emit ChangeToken(balanceOwner, tokenBalance[balanceOwner], block.timestamp);
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

    // string[] public deSciFileCIDs;
    uint256 public deSciPrintCnt;
    mapping(uint256 => string) public deSciPrintCIDMap;

    function deSciFileCIDs (uint256 _startIndex, uint256 _endIndex) public view returns (string[] memory) {
        require(_startIndex <= _endIndex, "Invalid index range");
        require(_endIndex < deSciPrintCnt, "Index out of range");
        string[] memory cids = new string[](_endIndex - _startIndex + 1);
        for (uint256 i = _startIndex; i <= _endIndex; i++) {
            cids[i - _startIndex] = deSciPrintCIDMap[i];
        }
        return cids;
    }

    event Submit(
        string fileCID,
        string keyInfo,
        address indexed submitAddress,
        uint256 indexed submitTime,
        string description,
        uint256 amount
    );

    event ReplyNew(
        string prevCID,
        string fileCID,
        string keyInfo,
        address indexed submitAddress,
        uint256 indexed submitTime,
        string description,
        uint256 amount
    );

    event ChangeReviewers(
        address indexed _editor,
        uint256 indexed _changeTime,
        string indexed _fileCID,
        address[] _newReviewers
    );

    event ChangePaperEditor(
        string indexed _fileCID,
        address _editor,
        uint256 indexed _changeTime
    );

    event Comment(
        address indexed commentator,
        uint256 indexed commentTime,
        string indexed targetCID,
        string commentCID,
        ReviewerStatus status
    );

    event ReplyComment(
        string indexed fileCID,
        address indexed toCommentator,
        uint256 indexed replyTime,
        string replyCID
    );

    function submitForReview(
        string memory _fileCID,
        string memory _keyInfo,
        string memory _description,
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
        // deSciFileCIDs.push(_fileCID);
        deSciPrintCIDMap[deSciPrintCnt] = _fileCID;
        deSciPrintCnt++;

        emit Submit(
            _fileCID,
            _keyInfo,
            _submitAddress,
            _submitTime,
            _description,
            _amount
        );

    }

    function printsPool(ProcessStatus _status, uint256 _startIndex, uint256 _endIndex) public view returns (string[] memory printsPool_) {
        uint256 resultCount;

        string[] memory deSciFileCIDs_ = new string[](_endIndex - _startIndex + 1);
        deSciFileCIDs_ = deSciFileCIDs(_startIndex, _endIndex);

        for (uint256 i = 0; i < deSciFileCIDs_.length; i++) {
            if (deSciProcess[deSciFileCIDs_[i]].processStatus == _status) {
                resultCount++;  // step 1 - determine the result count
            }
        }

        printsPool_ = new string[](resultCount);  // step 2 - create the fixed-length array
        uint256 j;
        for (uint256 i = 0; i < deSciFileCIDs_.length; i++) {
            if (deSciProcess[deSciFileCIDs_[i]].processStatus == _status) {
                printsPool_[j] = deSciFileCIDs_[i];  // step 3 - fill the array
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

        emit ChangeReviewers(
            msg.sender,
            block.timestamp,
            fileCID,
            processInfo.reviewers
        );
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

            emit ChangePaperEditor(
                fileCID,
                msg.sender,
                block.timestamp
            );
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

        emit Comment(
            msg.sender,
            block.timestamp,
            fileCID,
            comment_,
            ReviewerStatus.Reject
        );
    }

    // function _isReviewer(string memory fileCID, address reviewer) public view returns (bool) {
    //     ProcessInfo storage process = deSciProcess[fileCID];
    //     bool canReview = false;
    //     address[] memory reviewers = process.reviewers;
    //     for (uint256 i = 0; i < reviewers.length; i++) {
    //         if (reviewers[i] == reviewer) {
    //             canReview = true;
    //             break;
    //         }
    //     }
    //     return canReview;
    // }

    function _isReviewer(string memory fileCID, address reviewer) public view returns (bool) {
        bool canReview = false;
        if (reviewerIndex[fileCID][reviewer] != 0) {
            canReview = true;
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

        emit Comment(
            msg.sender,
            block.timestamp,
            fileCID,
            reviewCID,
            status
        );
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

        emit ReplyComment(
            fileCID,
            reviewer,
            block.timestamp,
            replyCID
        );
    }

    function replyNew(
        string memory preFileCID,
        string memory _fileCID,
        string memory _keyInfo,
        string memory _description,
        uint256 _amount
    ) public payable onlyAuthor(preFileCID) checkProcessStatus(_fileCID) {
        ProcessInfo storage preProcess = deSciProcess[preFileCID];
        require(preProcess.processStatus == ProcessStatus.NeedRevise, 'The status should be NeedRevise');
        submitForReview(_fileCID, _keyInfo, _description, _amount);
        PrintInfo storage prePrintInfo = deSciPrints[preFileCID];
        prePrintInfo.nextCID = _fileCID;
        preProcess.processStatus = ProcessStatus.RepliedNew;
        PrintInfo storage printInfo = deSciPrints[_fileCID];
        printInfo.prevCID = preFileCID;
        ProcessInfo storage processInfo = deSciProcess[_fileCID];
        processInfo.editor = preProcess.editor;
        _reviewerAssign(_fileCID, preProcess.reviewers);
        emit ReplyNew(
            preFileCID,
            _fileCID,
            _keyInfo,
            msg.sender,
            block.timestamp,
            _description,
            _amount
        );
    }

    function removeReviewer(string memory fileCID, address[] memory _reviewers) 
        public
        onlyEditor
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
                reviewerIndex[fileCID][lastReviewer] = index;
                reviewerIndex[fileCID][_reviewers[i]] = 0;
            }
        }
        processInfo.editorActCnt++;
        if (processInfo.editorActCnt <= editorActLimit) {
            _assignToken(msg.sender, 5, fileCID);
        }

        emit ChangeReviewers(
            msg.sender,
            block.timestamp,
            fileCID,
            processInfo.reviewers
        );
    }

    function changeEditor(string memory fileCID, address newEditor)
        public 
        onlyOwner
    {
        deSciProcess[fileCID].editor = newEditor;

        emit ChangePaperEditor(
                fileCID,
                newEditor,
                block.timestamp
        );
    }

    receive() external payable {}

    // // Use this very carefully. Use withdrawAvalible in most cases.
    // function withdrawAll() public payable onlyOwner {
    //     require(address(this).balance > 0);
    //     address payable _owner = owner();
    //     for (uint256 i = 0; i < balanceAddrs.length; i++) {
    //         _clearBalance(balanceAddrs[i]);
    //     }
    //     _owner.transfer(address(this).balance);
    // }

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
        uint256 amount = tokenBalance[msg.sender];
        require(amount > gasFee[3]);
        _clearBalance(msg.sender);
        payable(msg.sender).transfer(amount);
        emit ChangeToken(msg.sender, tokenBalance[msg.sender], block.timestamp);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
