async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Example NGO addresses (testnet addresses)
  const ngoAddresses = [
    "0x1234567890abcdef1234567890abcdef12345678",
    "0xabcdef1234567890abcdef1234567890abcdef12",
    "0x7890abcdef1234567890abcdef1234567890abcd"
  ];

  // Example approval threshold
  const approvalThreshold = 2;  // Must be <= number of NGO addresses

  const Contract = await ethers.getContractFactory("IDSafe");
  const contract = await Contract.deploy(ngoAddresses, approvalThreshold);

  console.log("Contract deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
