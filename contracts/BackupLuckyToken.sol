// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
// For compiling with Truffle use imports bellow and comment out Remix imports
// Truffle Imports
/*
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
*/
// For compiling with Remix use imports below
// Remix Imports

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";

contract LuckyToken is ERC20("Lucky Bet", "LBT"), AccessControl {
    using SafeMath for uint256;

    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");

    uint256 public _totalSupply = 5000000000e18; //5,000,000,000
    uint256 internal _premine = 500000e18; // 500k

    uint256 public circulatingSupply;
    uint256 public startDate;
    uint256 public bonusEnds;
    uint256 public endDate;
    uint256 internal _teamPayout;
    uint256 internal _marketingPayout;
    uint256 internal _devPayout;
    uint256 internal _ownerPayout;
    uint256 internal _teamPercent = 10;
    uint256 internal _marketingPercent = 10;
    uint256 internal _devPercent = 20;
    uint256 internal _ownerPercent = 60;

    address[] internal teamMembers;
    uint256 internal teamCount;

    address payable owner = 0x709A3c46A75D4ff480b0dfb338b28cBc44Df357a;
    address payable teamFund = 0xEfB349d5DCe3171f753E997Cdd779D42d0d060e2;
    address payable marketingFund = 0x998a96345BC259bD401354975c00592612aBd2ec;
    address payable devFund = 0x991591ad6a7377Ec487e51f3f6504EE09B7b531C;

    uint256 internal _moderatorPercent = 100; // 2%
    uint256 internal _projectsPercent = 2000; // 20%
    uint256 internal _ownersPercent = 3000; // 30%

    // Jackpot
    uint256 internal _jackpot777 = 77777; // 777%

    // 300 point range
    uint256 internal _smallBetSmallWin = 7000; // 70%
    uint256 internal _smallBetMediumWin = 9000; // 90%
    uint256 internal _smallBetBigWin = 20000; // 200%

    // 200 point range
    uint256 internal _mediumBetSmallWin = 5000; // 50%
    uint256 internal _mediumBetMediumWin = 8000; // 80%
    uint256 internal _mediumBetBigWin = 30000; // 300%

    // 100 point range
    uint256 internal _largeBetSmallWin = 3000; // 30%
    uint256 internal _largeBetMediumWin = 7000; // 70%
    uint256 internal _largeBetBigWin = 40000; // 400%

    uint256 private _sessionsIds;

    // Set the sale state
    bool public sale;

    mapping(address => gameData) public addressGameHistory;
    mapping(uint256 => gameData) public sessionGameHistory;
    mapping(address => uint256) public balances;
    mapping(address => uint256) internal rewards;

    struct gameData {
        address account;
        uint256 session;
        uint256 amount;
        uint256 takeHome;
        uint256 loss;
        uint256 teamFee;
        uint256 luckyNumber;
    }

    modifier onlySetter() {
        require(hasRole(SETTER_ROLE, _msgSender()), "Caller is not a setter");
        _;
    }

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), "Caller is not the owner.");
        _;
    }

    constructor() public {
        owner = msg.sender;
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(SETTER_ROLE, msg.sender);
        _mint(owner, _premine);

        circulatingSupply = _premine;
        startDate = now;
        bonusEnds = startDate + 6 weeks;
        sale = true;
    }

    function getSetterRole() external pure returns (bytes32) {
        return SETTER_ROLE;
    }

    function endSale() public onlyOwner {
        sale = false;
    }

    function rebootSale() public onlyOwner {
        sale = true;
    }

    function addTeamMember(address _address) public onlySetter {
        (bool _isTeamMember, ) = isTeamMember(_address);
        if (!_isTeamMember) teamMembers.push(_address);
        teamCount = teamCount + 1;
    }

    function removeTeamMember(address _address) public {
        (bool _isTeamMember, uint256 s) = isTeamMember(_address);
        if (_isTeamMember) {
            teamMembers[s] = teamMembers[teamMembers.length - 1];
            teamMembers.pop();
            teamCount = teamCount - 1;
        }
    }

    function distributeRewards() public onlySetter {
        for (uint256 s = 0; s < teamMembers.length; s += 1) {
            address teamMember = teamMembers[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    function isTeamMember(address _address) public view returns (bool, uint256) {
        for (uint256 s = 0; s < teamMembers.length; s += 1) {
            if (_address == teamMembers[s]) return (true, s);
        }
        return (false, 0);
    }

    function luckyBet(uint256 amount) public payable {
        require(amount >= 2, "Cannot stake less than 2 LBT");
        require(amount <= 100, "Cannot stake more than 100 LBT");
        _burn(msg.sender, amount);
        _sessionsIds = _sessionsIds.add(1);

        uint256 sessionId = _sessionsIds;
        uint256 luckyNumber;
        luckyNumber = rand();
        uint256 totalFees;
        uint256 reward;
        uint256 loss;
        uint256 ownersCut;
        uint256 projectsCut;
        uint256 feeAfterCuts;

        // ------------------------------------------------------------------------
        //                             Small Bet
        // ------------------------------------------------------------------------
        if (amount >= 2 && amount <= 10) {
            if (luckyNumber == 777) {
                reward = amount.mul(_jackpot777).div(10000);
                loss = 0;

                _mint(msg.sender, reward);
            } else if (luckyNumber >= 900 || luckyNumber <= 100) {
                reward = amount.mul(_smallBetBigWin).div(10000);
                loss = 0;

                _mint(msg.sender, reward);
            } else if (luckyNumber >= 800 || luckyNumber <= 200) {
                reward = amount.mul(_smallBetMediumWin).div(10000);
                loss = amount.sub(reward);

                _burn(msg.sender, loss);
            } else if (luckyNumber >= 700 || luckyNumber <= 600) {
                reward = amount.mul(_smallBetSmallWin).div(10000);
                loss = amount.sub(reward);

                _burn(msg.sender, loss);
            } else if (luckyNumber < 700 && luckyNumber > 600) {
                reward = 0;
                loss = amount;

                if (amount < 5) {
                    ownersCut = loss.mul(_ownersPercent).div(10000);
                    projectsCut = loss.mul(_projectsPercent).div(10000);
                    totalFees = ownersCut.add(_projectsCut);
                    feeAfterCuts = loss.sub(totalFees);

                    //transfer(_owner, ownersCut);
                    //transfer(teamPayoutAddress, projectsCut);

                    _burn(msg.sender, feeAfterCuts);
                } else {
                    _burn(msg.sender, loss);
                }
            }
        }

        // ------------------------------------------------------------------------
        //                             Medium Bet
        // ------------------------------------------------------------------------
        if (amount >= 11 && amount <= 50) {
            if (luckyNumber == 777) {
                reward = amount.mul(_jackpot777).div(10000);
                loss = 0;

                _mint(msg.sender, reward);
            } else if (luckyNumber >= 900 || luckyNumber <= 100) {
                reward = amount.mul(_mediumBetBigWin).div(10000);
                loss = 0;

                _mint(msg.sender, reward);
            } else if (luckyNumber >= 800 || luckyNumber <= 200) {
                reward = amount.mul(_mediumBetMediumWin).div(10000);
                loss = amount.sub(reward);

                _burn(msg.sender, loss);
            } else if (luckyNumber >= 700 || luckyNumber <= 600) {
                reward = amount.mul(_mediumBetSmallWin).div(10000);
                loss = amount.sub(reward);

                _burn(msg.sender, loss);
            } else if (luckyNumber < 700 && luckyNumber > 600) {
                reward = 0;
                loss = amount;

                if (amount < 5) {
                    ownersCut = loss.mul(_ownersPercent).div(10000);
                    projectsCut = loss.mul(_projectsPercent).div(10000);
                    totalFees = ownersCut.add(_projectsCut);
                    feeAfterCuts = loss.sub(totalFees);

                    //transfer(_owner, ownersCut);
                    //transfer(teamPayoutAddress, projectsCut);

                    _burn(msg.sender, feeAfterCuts);
                } else {
                    _burn(msg.sender, loss);
                }
            }
        }

        // ------------------------------------------------------------------------
        //                             Large Bet
        // ------------------------------------------------------------------------
        if (amount >= 51 && amount <= 100) {
            if (luckyNumber == 777) {
                reward = amount.mul(_jackpot777).div(10000);
                loss = 0;

                _mint(msg.sender, reward);
            } else if (luckyNumber >= 900 || luckyNumber <= 100) {
                reward = amount.mul(_largeBetBigWin).div(10000);
                loss = 0;

                _mint(msg.sender, reward);
            } else if (luckyNumber >= 800 || luckyNumber <= 200) {
                reward = amount.mul(_largeBetMediumWin).div(10000);
                loss = amount.sub(reward);

                _burn(msg.sender, loss);
            } else if (luckyNumber >= 700 || luckyNumber <= 600) {
                reward = amount.mul(_largeBetSmallWin).div(10000);
                loss = amount.sub(reward);

                _burn(msg.sender, loss);
            } else if (luckyNumber < 700 && luckyNumber > 600) {
                reward = 0;
                loss = amount;

                if (amount < 5) {
                    ownersCut = loss.mul(_ownersPercent).div(10000);
                    projectsCut = loss.mul(_projectsPercent).div(10000);
                    totalFees = ownersCut.add(_projectsCut);
                    feeAfterCuts = loss.sub(totalFees);

                    //transfer(_owner, ownersCut);
                    //transfer(teamPayoutAddress, projectsCut);

                    _burn(msg.sender, feeAfterCuts);
                } else {
                    _burn(msg.sender, loss);
                }
            }
        }

        gameData memory gameData_ =
            gameData({
                account: msg.sender,
                session: sessionId,
                amount: amount,
                takeHome: reward,
                loss: loss,
                teamFee: totalFees,
                luckyNumber: luckyNumber
            });

        addressGameHistory[msg.sender] = gameData_;
        sessionGameHistory[sessionId] = gameData_;

        transfer(owner, ownersCut);
        transfer(teamFund, projectsCut);
    }

    function purchase() public payable {
        require(circulatingSupply < _totalSupply, "Max Supply Reached.");
        require(_sale == true, "Purchasing Tokens in not avaiable right now.");
        uint256 tokens;
        if (now <= bonusEnds) {
            tokens = msg.value.mul(700);
        } else {
            tokens = msg.value.mul(500);
        }
        circulatingSupply = circulatingSupply.add(tokens);
        _teamPayout = msg.value.mul(_teamPercent).div(100);
        _marketingPayout = msg.value.mul(_marketingPercent).div(100);
        _devPayout = msg.value.mul(_devPercent).div(100);
        _ownerPayout = msg.value.mul(_ownerPercent).div(100);

        owner.transfer(_ownerPayout);
        teamFund.transfer(_teamPayout);
        marketingFund.transfer(_marketingPayout);
        devFund.transfer(_devPayout);

        _mint(msg.sender, tokens);
    }

    function returnSessionInfo(uint256 sessionID) public view returns (
            address account,
            uint256 session,
            uint256 amount,
            uint256 takeHome,
            uint256 loss,
            uint256 teamFee,
            uint256 luckyNumber
        )
    {
        return (
            sessionGameHistory[sessionID].account,
            sessionGameHistory[sessionID].session,
            sessionGameHistory[sessionID].amount,
            sessionGameHistory[sessionID].takeHome,
            sessionGameHistory[sessionID].loss,
            sessionGameHistory[sessionID].teamFee,
            sessionGameHistory[sessionID].luckyNumber
        );
    }

    function rand() public view returns (uint256) {
        uint256 seed =
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (block.timestamp)) +
                            block.gaslimit +
                            ((
                                uint256(keccak256(abi.encodePacked(msg.sender)))
                            ) / (block.timestamp)) +
                            block.number
                    )
                )
            );

        return (seed - ((seed / 1000) * 1000));
    }

    function getBalance(address account) public view returns (uint256) {
        balanceOf(account);
    }

    
}
