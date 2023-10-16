const { encodeAbiParameters, parseAbiParameters } = require('viem');

var args = process.argv.slice(2);

async function fetchParams() {
  const bridgeCall = await (
    await fetch(`https://bridge-api.zkevm-rpc.com/bridges/${args[0]}`)
  ).json();
  if (process.env.VERBOSE) console.log(bridgeCall);
  const deposit = bridgeCall.deposits.find(
    (deposit) => deposit.claim_tx_hash == '' && deposit.ready_for_claim == true
  );
  if (!deposit) throw new Error('No claimable deposit txn found');
  const proof = await (
    await fetch(
      `https://bridge-api.zkevm-rpc.com/merkle-proof?deposit_cnt=${deposit.deposit_cnt}&net_id=${deposit.network_id}`
    )
  ).json();

  if (process.env.VERBOSE) console.log(proof);
  const encodedData = encodeAbiParameters(
    parseAbiParameters(
      'bytes32[32] smtProof, uint32 index, bytes32 mainnetExitRoot, bytes32 rollupExitRoot, uint32 originNetwork, address originAddress, uint32 destinationNetwork, address destinationAddress, uint256 amount, bytes metadata'
    ),
    [
      proof.proof.merkle_proof,
      Number(deposit.deposit_cnt),
      proof.proof.main_exit_root,
      proof.proof.rollup_exit_root,
      Number(deposit.orig_net),
      deposit.orig_addr,
      Number(deposit.dest_net),
      deposit.dest_addr,
      Number(deposit.amount),
      deposit.metadata,
    ]
  );
  console.log(encodedData);
}

fetchParams();
