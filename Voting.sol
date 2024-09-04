// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Vote {
    struct Voter {
        string name;
        uint256 age;
        uint256 voterId;
        uint256 voteCandidateId;
        address voteAddress;
        Gender gender;
    }

    struct Candidate {
        string name;
        string party;
        uint256 age;
        Gender gender;
        uint256 candidateId;
        uint256 votes;
        address candidateAddress;
    }

    // third entity
    address public electionCommission;
    address public winner;

    uint256 nextVoterId = 1;
    uint256 nextCandidateId = 1;

    //voting period
    uint256 startTime;
    uint256 endTime;
    bool stopVoting;

    mapping(uint256 => Voter) voterDetails; // here voter and candidate is struct ...... mapping with struct
    mapping(uint256 => Candidate) candidateDetails;

    enum VotingStatus {
        NotStarted,
        InProgess,
        Ended
    } // enum is 3 values NotStarted , InProgess , Ended
    enum Gender {
        NotSpecified,
        Male,
        Female,
        Other
    }

    constructor() {
        electionCommission = msg.sender; // here msg.sender is address of contract
    }

    modifier isVotingOver() {
        require(
            block.timestamp <= endTime || stopVoting == true,
            "Voting is over"
        ); // block.timeswap is used to check current block time of voting
        _;
    } // double braces mei false condition liki hui hai

    modifier onlyComissioner() {
        // require check krne k liye use
        require(msg.sender == electionCommission, "Not Authorized");
        _;
    }

    function registerCandidate(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        Gender _gender
    ) external {
        require(_age > 18, "you are below 18");
        require(
            isCandidateNotRegistered(msg.sender),
            "you are already registered"
        );
        require(nextCandidateId < 3, "Candidate Registration Full");
        require(
            msg.sender != electionCommission,
            "Election Commission cannot register candidate"
        );
        candidateDetails[nextCandidateId] = Candidate({
            name: _name,
            party: _party,
            gender: _gender,
            age: _age,
            candidateId: nextCandidateId,
            candidateAddress: msg.sender,
            votes: 0
        });
        nextCandidateId++;
    }

    function isCandidateNotRegistered(address _person)
        private
        view
        returns (bool)
    {
        for (uint256 i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].candidateAddress == _person) {
                return false; // means candidate is registered
            }
        }
        return true; // means candidate is not registered
    }

    function getCandidateList() public view returns (Candidate[] memory) {
        Candidate[] memory candidateList = new Candidate[](nextCandidateId - 1);
        // here candidateList is array of type Candidate
        for (uint256 i = 0; i < candidateList.length; i++) {
            candidateList[i] = candidateDetails[i + 1];
        }
        return candidateList;
    }

    function isVoterNotRegistered(address _person) private view returns (bool) {
        for (uint256 i = 1; i < nextVoterId; i++) {
            if (voterDetails[i].voteAddress == _person) {
                return false;
            }
        }
        return true;
    }

    function registerVoter(
        string calldata _name,
        uint256 _age,
        Gender _gender
    ) external {
        require(isVoterNotRegistered(msg.sender), "You are already registered");

        voterDetails[nextVoterId] = Voter({
            name: _name,
            age: _age,
            gender: _gender,
            voterId: nextVoterId,
            voteCandidateId: 0,
            voteAddress: msg.sender
        });
        nextVoterId++;
    }

    function getVoterList() public view returns (Voter[] memory) {
        uint256 lengthArr = nextVoterId - 1; // here to  give the current number of the votes we used nextVoterId-1;
        Voter[] memory voterList = new Voter[](lengthArr); // new array for voterlist
        for (uint256 i = 0; i < voterList.length; i++) {
            voterList[i] = voterDetails[i + 1]; //i + 1: Since voterDetails is indexed starting from 1 (because nextVoterId starts at 1), and arrays in Solidity are zero-indexed, the code uses i + 1 to correctly map the array index to the voter ID.
        }
        return voterList;
    }

    function setVotingPeriod(
        uint256 _startTimeDuration,
        uint256 _endTimeDuration
    ) external onlyComissioner {
        require(
            _endTimeDuration > 3600,
            "Endtime duration must be greater than 1 hour"
        );
        startTime = 1720799550 + _startTimeDuration; // here 1720799550 is unix base number jisme ye add hoke start time dega voting ka
        endTime = startTime + _endTimeDuration;
    }

    function getVotingStatus() public view returns (VotingStatus) {
        if (startTime == 0) {
            return VotingStatus.NotStarted; // enum used here
        } else if (endTime > block.timestamp || stopVoting == false) {
            return VotingStatus.InProgess;
        } else {
            return VotingStatus.Ended;
        }
    }

    function announceVotingResult() external onlyComissioner {
        uint256 max = 0;
        for (uint256 i = 0; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes > max) {
                max = candidateDetails[i].votes;
                winner = candidateDetails[i].candidateAddress;
            }
        }
    }

    function emergencyStopVoting() public onlyComissioner {
        stopVoting = true;
    }
}
