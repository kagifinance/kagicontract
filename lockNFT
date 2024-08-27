// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract NFTLocker {
    struct LockInfo {
        address tokenAddress;
        uint256 tokenId;
        uint256 unlockTime;
    }

    mapping(address => LockInfo[]) public userLocks;

    event NFTLocked(address indexed user, address indexed tokenAddress, uint256 indexed tokenId, uint256 unlockTime);
    event NFTUnlocked(address indexed user, address indexed tokenAddress, uint256 indexed tokenId);

    function lockNFT(address _tokenAddress, uint256 _tokenId, uint256 _lockPeriod) external {
        IERC721 tokenContract = IERC721(_tokenAddress);
        require(tokenContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");

        uint256 unlockTime = block.timestamp + _lockPeriod;

        // Transfer the NFT to the contract
        tokenContract.transferFrom(msg.sender, address(this), _tokenId);

        // Store lock information
        userLocks[msg.sender].push(LockInfo({
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            unlockTime: unlockTime
        }));

        emit NFTLocked(msg.sender, _tokenAddress, _tokenId, unlockTime);
    }

    function unlockNFT(address _tokenAddress, uint256 _tokenId) external {
        LockInfo[] storage locks = userLocks[msg.sender];
        bool found = false;
        
        for (uint256 i = 0; i < locks.length; i++) {
            if (locks[i].tokenAddress == _tokenAddress && locks[i].tokenId == _tokenId) {
                require(block.timestamp >= locks[i].unlockTime, "NFT is still locked");

                // Transfer the NFT back to the user
                IERC721(_tokenAddress).transferFrom(address(this), msg.sender, _tokenId);

                // Remove the lock from the list
                locks[i] = locks[locks.length - 1];
                locks.pop();

                found = true;
                emit NFTUnlocked(msg.sender, _tokenAddress, _tokenId);
                break;
            }
        }

        require(found, "NFT not found in your locked list");
    }

    function getLockedNFTs(address _user) external view returns (LockInfo[] memory) {
        return userLocks[_user];
    }
}
