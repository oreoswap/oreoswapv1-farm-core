// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@oreoswap/oreoswap-swap-lib/libs/token/SafeBEP20.sol";
import "@oreoswap/oreoswap-swap-lib/libs/token/IBEP20.sol";
import "@oreoswap/oreoswap-swap-lib/libs/math/SafeMath.sol";


// SousChef is the chef of new tokens. He can make yummy food and he is a fair guy as well as MasterChef.
contract SousChef {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;   // How many SYRUP tokens the user has provided.
        uint256 rewardDebt;  // Reward debt. See explanation below.
        uint256 rewardPending;
        //
        // We do some fancy math here. Basically, any point in time, the amount of SYRUPs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt + user.rewardPending
        //
        // Whenever a user deposits or withdraws SYRUP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of Pool
    struct PoolInfo {
        uint256 lastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated reward per share, times 1e12. See below.
    }

    // The SYRUP TOKEN!
    IBEP20 public milk;
    // rewards created per block.
    uint256 public rewardPerBlock;

    // Info.
    PoolInfo public poolInfo;
    // Info of each user that stakes Milk tokens.
    mapping (address => UserInfo) public userInfo;

    // addresses list
    address[] public addressList;

    // The block number when mining starts.
    uint256 public startBlock;
    // The block number when mining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _milk,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock) {
            milk = _milk;
            rewardPerBlock = _rewardPerBlock;
            startBlock = _startBlock;
            bonusEndBlock = _endBlock;

            // staking pool
            poolInfo = PoolInfo({
                lastRewardBlock: startBlock,
                accRewardPerShare: 0
            });
    }

    function addressLength() external view returns (uint256) {
        return addressList.length;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Tokens on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 stakedSupply = milk.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && stakedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(tokenReward.mul(1e12).div(stakedSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt).add(user.rewardPending);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }
        uint256 milkSupply = milk.balanceOf(address(this));
        if (milkSupply == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock);

        poolInfo.accRewardPerShare = poolInfo.accRewardPerShare.add(tokenReward.mul(1e12).div(milkSupply));
        poolInfo.lastRewardBlock = block.number;
    }


    // Deposit Milk tokens to SousChef for Reward allocation.
    function deposit(uint256 _amount) public {
        require (_amount > 0, 'amount 0');
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        milk.safeTransferFrom(address(msg.sender), address(this), _amount);
        // The deposit behavior before farming will result in duplicate addresses, and thus we will manually remove them when airdropping.
        if (user.amount == 0 && user.rewardPending == 0 && user.rewardDebt == 0) {
            addressList.push(address(msg.sender));
        }
        user.rewardPending = user.amount.mul(poolInfo.accRewardPerShare).div(1e12).sub(user.rewardDebt).add(user.rewardPending);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(poolInfo.accRewardPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw Milk tokens from SousChef.
    function withdraw(uint256 _amount) public {
        require (_amount > 0, 'amount 0');
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not enough");

        updatePool();
        milk.safeTransfer(address(msg.sender), _amount);

        user.rewardPending = user.amount.mul(poolInfo.accRewardPerShare).div(1e12).sub(user.rewardDebt).add(user.rewardPending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(poolInfo.accRewardPerShare).div(1e12);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        milk.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardPending = 0;
    }

}
