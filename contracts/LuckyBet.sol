// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./LuckyToken.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";

contract LuckyBet is LuckyToken {
    using SafeMath for uint256;
    
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");
    
    address mainToken = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;

    address[] internal _teamMembers;
    uint256 internal teamCount;
    
    address internal _owner = 0x709A3c46A75D4ff480b0dfb338b28cBc44Df357a;

    uint256 internal _moderatorPercent = 100; // 2%
    uint256 internal _projectsPercent = 2000; // 20%
    uint256 internal _ownersPercent = 3000; // 30%
    uint256 public teamFundPool;
    
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

    constructor() public {
        owner = msg.sender;
        _setupRole(SETTER_ROLE, msg.sender);
    }

    function getSetterRole() external pure returns (bytes32) {
        return SETTER_ROLE;
    }

    function addTeamMember(address _address) public onlySetter {
        (bool _isTeamMember, ) = isTeamMember(_address);
        if (!_isTeamMember) _teamMembers.push(_address);
        teamCount = teamCount + 1;
    }

    function removeTeamMember(address _address) public onlySetter{
        (bool _isTeamMember, uint256 s) = isTeamMember(_address);
        if (_isTeamMember) {
            _teamMembers[s] = _teamMembers[_teamMembers.length - 1];
            _teamMembers.pop();
            teamCount = teamCount - 1;
        }
    }

    function distributeRewards() public onlySetter {
        for (uint256 s = 0; s < _teamMembers.length; s += 1) {
            address member = _teamMembers[s];
            uint256 reward = teamFundPool.div(teamCount);
            //rewards[member] = rewards[member].add(reward);
            // Set the team fund back to 0
            teamFundPool == 0;
            _mint(member, reward);
        }
    }

    function isTeamMember(address _address) public view returns (bool, uint256) {
        for (uint256 s = 0; s < _teamMembers.length; s += 1) {
            if (_address == _teamMembers[s]) return (true, s);
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
                    totalFees = ownersCut.add(projectsCut);
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
                    totalFees = ownersCut.add(projectsCut);
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
                    totalFees = ownersCut.add(projectsCut);
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

        transfer(_owner, ownersCut);
        teamFundPool.add(projectsCut);
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
}
