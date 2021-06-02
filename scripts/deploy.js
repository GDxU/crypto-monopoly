// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scohouseExchange.
const hre = require("hardhat");

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile 
    // manually to make sure everything is compiled
    // await hre.run('compile');

    const ERC20Token = await hre.ethers.getContractFactory("ERC20Token");
    const erc20Token = await ERC20Token.deploy();

    const UserCenter = await hre.ethers.getContractFactory("UserCenter");
    const userCenter = await UserCenter.deploy();

    const PropertyOwnership = await hre.ethers.getContractFactory("PropertyOwnership");
    const houseNFT = await PropertyOwnership.deploy();

    const PropertyExchange = await hre.ethers.getContractFactory("PropertyExchange");
    const houseExchange = await PropertyExchange.deploy(houseNFT.address, erc20Token.address);

    const Gov = await hre.ethers.getContractFactory("Gov");
    const gov = await Gov.deploy(houseExchange.address, erc20Token.address);

    const Game = await hre.ethers.getContractFactory("Game");
    const game = await Game.deploy();

    await erc20Token.deployed();
    await userCenter.deployed();
    await houseNFT.deployed();
    await houseExchange.deployed();
    await gov.deployed();
    await game.deployed();

    console.info("ERC20 deployed to:", erc20Token.address);
    console.info("UserCenter deployed to:", userCenter.address);
    console.info("House NFT deployed to:", houseNFT.address);
    console.info("House Exchange deployed to:", houseExchange.address);
    console.info("Gov deployed to:", gov.address);
    console.info("Game deployed to:", game.address);

    console.info('setup Monopoly...')
    await userCenter.addAdmin(game.address)
    await erc20Token.addAdmin(houseExchange.address)
    await erc20Token.addAdmin(gov.address)
    await erc20Token.addAdmin(game.address)
    await houseNFT.addAdmin(houseExchange.address)
    await houseNFT.addAdmin(game.address)
    await houseExchange.addAdmin(gov.address)
    await houseExchange.addAdmin(game.address)
    await gov.addAdmin(game.address)
    await game.setup(houseNFT.address, houseExchange.address, erc20Token.address, userCenter.address, gov.address)

    console.info('Monopoly is ready!')
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });