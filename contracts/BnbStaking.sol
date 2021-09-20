// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './oreoswap-lib/SafeBEP20.sol';
import './oreoswap-lib/IBEP20.sol';
import './oreoswap-lib/SafeBEP20.sol';
import './oreoswap-lib/Ownable.sol';

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

contract BnbStaking is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
        // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        bool inBlackList;
    }

    // struct UserInfo {
    //     IBEP20 lpToken;           // Address of LP token contract.
    //     uint256 allocPoint;       // How many allocation points assigned to this pool. Oreos to distribute per block.
    //     uint256 lastRewardBlock;  // Last block number that Oreos distribution occurs.
    //     uint256 accOreoPerShare; // Accumulated Oreos per share, times 1e12. See below.
    // }
   
     struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Oreos to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Oreos distribution occurs.
        uint256 accOreoPerShare; // Accumulated Oreos per share, times 1e12. See below.
    }


    // The REWARD TOKEN          //NOTE address of Oreotoken
    IBEP20 public rewardToken;  

    // adminAddress
    address public adminAddress;

    // WBNB
    address public immutable WBNB; //WRAP BNB address -- created from WBNB.sol NOTE We created WBNB to make it easier tracking
                                    // users' deposit and not dealing directly with BNB

    // OREOtokens created per block.
    uint256 public rewardPerBlock;  //To be determined.

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // limit 10 BNB here
    uint256 public limitAmount = 10000000000000000000;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when OREOmining starts.
    uint256 public startBlock;
    // The block number when OREOmining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _lp, //NOTE When user stakes BNB, they're given LP tokens which represents their share of the pool.
        IBEP20 _rewardToken, //NOTE After providing liquidity, gets LP token, they earn reward in this token.
        uint256 _rewardPerBlock, //How much reward is earned per block.
        uint256 _startBlock, //@dev sets the block number when bonus should begin.
        uint256 _bonusEndBlock, //@dev sets the block number when bonus ends.
        address _adminAddress,
        address _wbnb  //@dev sets WBNB address
    ) {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        adminAddress = _adminAddress;
        WBNB = _wbnb;

        // staking pool   ON DEPLOYMENT, AT THE CONSTRUCTOR, WE INITIALIZED OR CREATE A POOL FOR ALL.
        poolInfo.push(PoolInfo({
            lpToken: _lp, //WE SET LP TOKEN ADDRESS i.e MILKBAR TOKEN ADDRESS.
            allocPoint: 1000, //@dev SETS ALLOCATION POINT TO 1000
            lastRewardBlock: startBlock, //OBVIOUSLY, THE LAST BLOCK WHICH REWARD WAS DISTRIBUTED WILL BE THE STARTING BLOCK.
            accOreoPerShare: 0
        }));

        totalAllocPoint = 1000;  //WE INITIALIZED TOTAL ALLOCATION POINT TO THE TOTAL OF ALL ALLOCATION POINTS IN THE POOL

    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?"); // WE WILL NOT ACCEPT BNB TRANSFER FROM OUTSIDE WORLRD EXCEPT
        _;                                                  // FROM ADMIN, ELSE POOL WILL BE MESSED UP.
    }

    receive() external payable {
        assert(msg.sender == WBNB); // only accept BNB via fallback from the WBNB contract
    }

    // Update admin address by the previous dev.
    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    function setBlackList(address _blacklistAddress) public onlyAdmin {
        userInfo[_blacklistAddress].inBlackList = true;
    }

    function removeBlackList(address _blacklistAddress) public onlyAdmin {
        userInfo[_blacklistAddress].inBlackList = false;
    }

    // Set the limit amount. Can only be called by the owner.
    function setLimitAmount(uint256 _amount) public onlyOwner {  //WE CAN UPDATE THE INITIAL BNB STAKING LIMIT SET.
        limitAmount = _amount;
    }

    // Return reward multiplier over the given starting block (_from) to current block(_to).
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {  //If the current block is less or same with the block from which reward was distributed,
            return _to.sub(_from);   // then subtract the starting block from the current block and return it.
        } else if (_from >= bonusEndBlock) { //An example: say: bonusEndBlock = 1234577, _fromBlock = 1234570, _toBlock = 1234576 
            return 0;                       // Multiplier = _toBlock - _fromBlock i.e 1234576 - 1234570  
        } else {                            // M = 6;
            return bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward for a single user in the pool on the frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accOreoPerShare = pool.accOreoPerShare; // We get the accumulated Oreopershare from the pool
        uint256 lpSupply = pool.lpToken.balanceOf(address(this)); // Get the total Liquidity provider token in this contract
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accOreoPerShare = accOreoPerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accOreoPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accOreoPerShare = pool.accOreoPerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Stake tokens to SmartChef
    function deposit() public payable {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        require (user.amount.add(msg.value) <= limitAmount, 'exceed the top');
        require (!user.inBlackList, 'in black list');

        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accOreoPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if(msg.value > 0) {
            IWBNB(WBNB).deposit{value: msg.value}();
            assert(IWBNB(WBNB).transfer(address(this), msg.value));
            user.amount = user.amount.add(msg.value);
        }
        user.rewardDebt = user.amount.mul(pool.accOreoPerShare).div(1e12);

        emit Deposit(msg.sender, msg.value);
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        // (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    // Withdraw tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accOreoPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0 && !user.inBlackList) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IWBNB(WBNB).withdraw(_amount);
            safeTransferBNB(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accOreoPerShare).div(1e12);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

}
