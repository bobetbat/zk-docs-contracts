// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZKDocsScheduler {
    constructor() { }

    function shouldDoDisput(
        uint256 _timestampToInvoke,
        address _contractAddressToCheck,
        address _accountAddressToCheck,
        uint256 _amountToCheck
    ) public view returns (bool) {
        require (
            _timestampToInvoke >= block.timestamp,
            "Time to check validity status not passed yet"
        );

        ERC20 contractToCheck = ERC20(_contractAddressToCheck);

        if (contractToCheck.balanceOf(_accountAddressToCheck) > _amountToCheck) {
            return false;
        }

        return true;
    }
}
