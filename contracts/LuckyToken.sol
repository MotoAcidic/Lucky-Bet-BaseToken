// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
// For compiling with Truffle use imports bellow and comment out Remix imports
// Truffle Imports

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// For compiling with Remix use imports below
// Remix Imports
/*
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";
*/

contract LuckyToken is ERC20("Lucky Bet", "LBT"), AccessControl {
    using SafeMath for uint256;

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

    address internal payable owner = 0x709A3c46A75D4ff480b0dfb338b28cBc44Df357a;
    address internal payable teamFund = 0xEfB349d5DCe3171f753E997Cdd779D42d0d060e2;
    address internal payable marketingFund = 0x998a96345BC259bD401354975c00592612aBd2ec;
    address internal payable devFund = 0x991591ad6a7377Ec487e51f3f6504EE09B7b531C;

    event Receive(uint256 value);

    constructor() public {
        _mint(owner, _premine);
        circulatingSupply = _premine;
        startDate = now;
        bonusEnds = startDate + 6 weeks;
        endDate = startDate + 52 weeks;
        sale = true;
    }

    function saleState() public onlyOwner {
        sale = false;
    }

    function purchase() public payable {
        require(circulatingSupply < _totalSupply, "Max Supply Reached.");
        require(now >= startDate && now <= endDate);
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

    function getBalance(address account) public view returns (uint256) {
        balanceOf(account);
    }
}
