// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiTokenVesting is Ownable {
    struct VestingSchedule {
        address tokenAddress;
        uint256 amount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 duration;
        uint256 released;
    }

    // Mapping of user address to array of vesting schedules
    mapping(address => VestingSchedule[]) public vestingSchedules;

    event TokensVested(address indexed user, address indexed token, uint256 amount, uint256 startTime, uint256 cliffTime, uint256 duration);
    event TokensReleased(address indexed user, address indexed token, uint256 amount);

    /**
     * @dev Function to create a vesting schedule for a user
     * @param _tokenAddress The address of the ERC20 token to be vested
     * @param _user The address of the user who will receive the vested tokens
     * @param _amount The total amount of tokens to be vested
     * @param _startTime The start time of the vesting period
     * @param _cliffTime The time after which the tokens can start to be released
     * @param _duration The duration over which the tokens will be vested
     */
    function vestTokens(
        address _tokenAddress,
        address _user,
        uint256 _amount,
        uint256 _startTime,
        uint256 _cliffTime,
        uint256 _duration
    ) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(_startTime >= block.timestamp, "Start time must be in the future");
        require(_cliffTime >= _startTime, "Cliff time must be after start time");
        require(_duration > 0, "Duration must be greater than 0");

        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        VestingSchedule memory schedule = VestingSchedule({
            tokenAddress: _tokenAddress,
            amount: _amount,
            startTime: _startTime,
            cliffTime: _cliffTime,
            duration: _duration,
            released: 0
        });

        vestingSchedules[_user].push(schedule);

        emit TokensVested(_user, _tokenAddress, _amount, _startTime, _cliffTime, _duration);
    }

    /**
     * @dev Function to release vested tokens
     * @param _index The index of the vesting schedule in the user's array
     */
    function releaseTokens(uint256 _index) external {
        require(_index < vestingSchedules[msg.sender].length, "Invalid vesting schedule index");

        VestingSchedule storage schedule = vestingSchedules[msg.sender][_index];

        require(block.timestamp >= schedule.cliffTime, "Vesting cliff not reached");

        uint256 vestedAmount = _calculateVestedAmount(schedule);
        uint256 unreleased = vestedAmount - schedule.released;

        require(unreleased > 0, "No tokens to release");

        schedule.released += unreleased;

        IERC20 token = IERC20(schedule.tokenAddress);
        require(token.transfer(msg.sender, unreleased), "Token transfer failed");

        emit TokensReleased(msg.sender, schedule.tokenAddress, unreleased);
    }

    /**
     * @dev View function to get details of a user's vesting schedules
     * @param _user The address of the user
     * @return An array of vesting schedules
     */
    function getVestingSchedules(address _user) external view returns (VestingSchedule[] memory) {
        return vestingSchedules[_user];
    }

    /**
     * @dev Internal function to calculate the amount of tokens vested
     * @param schedule The vesting schedule
     * @return The amount of tokens vested
     */
    function _calculateVestedAmount(VestingSchedule memory schedule) internal view returns (uint256) {
        if (block.timestamp < schedule.cliffTime) {
            return 0;
        } else if (block.timestamp >= schedule.startTime + schedule.duration) {
            return schedule.amount;
        } else {
            return (schedule.amount * (block.timestamp - schedule.startTime)) / schedule.duration;
        }
    }
}
