// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Linear vesting wallet with a cliff.
/// @notice Escrows ETH or ERC-20 style balances for one beneficiary, released
///         linearly between `cliff` and `start + duration`. Any token that can
///         be pushed here is out of scope: `release` only moves native value.
contract VestingWallet {
    error ZeroBeneficiary();
    error CliffExceedsDuration();
    error NotBeneficiary();
    error NothingToRelease();
    error TransferFailed();

    address public immutable beneficiary;
    uint64 public immutable start;
    uint64 public immutable cliff; // seconds after `start`
    uint64 public immutable duration; // seconds after `start`

    event Released(uint256 amount);

    constructor(address beneficiary_, uint64 start_, uint64 cliff_, uint64 duration_) {
        if (beneficiary_ == address(0)) revert ZeroBeneficiary();
        if (cliff_ > duration_) revert CliffExceedsDuration();
        beneficiary = beneficiary_;
        start = start_;
        cliff = cliff_;
        duration = duration_;
    }

    receive() external payable {}

    /// @notice Value unlocked at `timestamp`, ignoring what was already released.
    function vestedAmount(uint64 timestamp) public view returns (uint256) {
        uint256 balance = address(this).balance;
        if (timestamp < start + cliff) return 0;
        if (timestamp >= start + duration) return balance;
        // linear from `start`, but nothing moves before the cliff
        return (balance * (timestamp - start)) / duration;
    }

    /// @notice Value withdrawable right now.
    function releasable() public view returns (uint256) {
        return vestedAmount(uint64(block.timestamp));
    }

    /// @notice Send everything unlocked so far to the beneficiary.
    function release() external {
        if (msg.sender != beneficiary) revert NotBeneficiary();
        uint256 amount = releasable();
        if (amount == 0) revert NothingToRelease();
        (bool ok,) = beneficiary.call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit Released(amount);
    }
}
