// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiTokenVesting {
    struct VestingSchedule {
        address tokenAddress;
        address beneficiary;
        uint256 amount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 duration;
        uint256 released;
    }

    // Mapping of vesting schedule IDs to VestingSchedules
    mapping(uint256 => VestingSchedule) public vestingSchedules;
    // Mapping from beneficiary address to list of vesting schedule IDs
    mapping(address => uint256[]) public userVestingSchedules;
    // Mapping from schedule ID to current owner of the schedule
    mapping(uint256 => address) public vestingScheduleOwners;
    // Counter for generating unique vesting schedule IDs
    uint256 public vestingScheduleCount;

    event TokensVested(uint256 indexed scheduleId, address indexed beneficiary, address indexed token, uint256 amount, uint256 startTime, uint256 cliffTime, uint256 duration);
    event TokensReleased(uint256 indexed scheduleId, address indexed beneficiary, uint256 amount);
    event OwnershipTransferred(uint256 indexed scheduleId, address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Function to create a vesting schedule for a user
     * @param _tokenAddress The address of the ERC20 token to be vested
     * @param _beneficiary The address of the user who will receive the vested tokens
     * @param _amount The total amount of tokens to be vested
     * @param _startTime The start time of the vesting period
     * @param _cliffTime The time after which the tokens can start to be released
     * @param _duration The duration over which the tokens will be vested
     */
    function vestTokens(
        address _tokenAddress,
        address _beneficiary,
        uint256 _amount,
        uint256 _startTime,
        uint256 _cliffTime,
        uint256 _duration
    ) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(_startTime >= block.timestamp, "Start time must be in the future");
        require(_cliffTime >= _startTime, "Cliff time must be after start time");
        require(_duration > 0, "Duration must be greater than 0");

        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        uint256 scheduleId = vestingScheduleCount++;
        VestingSchedule memory schedule = VestingSchedule({
            tokenAddress: _tokenAddress,
            beneficiary: _beneficiary,
            amount: _amount,
            startTime: _startTime,
            cliffTime: _cliffTime,
            duration: _duration,
            released: 0
        });

        vestingSchedules[scheduleId] = schedule;
        userVestingSchedules[_beneficiary].push(scheduleId);
        vestingScheduleOwners[scheduleId] = _beneficiary;

        emit TokensVested(scheduleId, _beneficiary, _tokenAddress, _amount, _startTime, _cliffTime, _duration);
    }

    /**
     * @dev Function to release vested tokens
     * @param _scheduleId The ID of the vesting schedule
     */
    function releaseTokens(uint256 _scheduleId) external {
        require(vestingScheduleOwners[_scheduleId] == msg.sender, "Not the owner of this vesting schedule");

        VestingSchedule storage schedule = vestingSchedules[_scheduleId];
        require(block.timestamp >= schedule.cliffTime, "Vesting cliff not reached");

        uint256 vestedAmount = _calculateVestedAmount(schedule);
        uint256 unreleased = vestedAmount - schedule.released;

        require(unreleased > 0, "No tokens to release");

        schedule.released += unreleased;

        IERC20 token = IERC20(schedule.tokenAddress);
        require(token.transfer(msg.sender, unreleased), "Token transfer failed");

        emit TokensReleased(_scheduleId, schedule.beneficiary, unreleased);
    }

    /**
     * @dev Function to transfer ownership of a vesting schedule
     * @param _scheduleId The ID of the vesting schedule
     * @param _newOwner The address of the new owner
     */
    function transferVestingOwnership(uint256 _scheduleId, address _newOwner) external {
        require(vestingScheduleOwners[_scheduleId] == msg.sender, "Not the owner of this vesting schedule");
        require(_newOwner != address(0), "New owner address cannot be zero");

        address oldOwner = vestingScheduleOwners[_scheduleId];
        vestingScheduleOwners[_scheduleId] = _newOwner;

        emit OwnershipTransferred(_scheduleId, oldOwner, _newOwner);
    }

    /**
     * @dev View function to get all vesting schedules for a user
     * @param _user The address of the user
     * @return An array of vesting schedule IDs
     */
    function getUserVestingSchedules(address _user) external view returns (uint256[] memory) {
        return userVestingSchedules[_user];
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
