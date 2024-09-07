const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('IDSafe Contract', function () {
    let idSafe;
    let admin;
    let ngo1;
    let ngo2;
    let user;
    let newAdmin;
    let newNGO;

    beforeEach(async function () {
        [admin, ngo1, ngo2, user, newAdmin, newNGO] = await ethers.getSigners();

        const IDSafe = await ethers.getContractFactory('IDSafe');
        idSafe = await IDSafe.deploy([ngo1.address, ngo2.address], 2);
        await idSafe.deployed();
    });

    it('should register an identity', async function () {
        const dataHash = ethers.utils.formatBytes32String('testData');
        await idSafe.connect(ngo1).registerIdentity(user.address, dataHash);

        const identity = await idSafe.getIdentityHash(user.address);
        expect(identity).to.equal(dataHash);
    });

    it('should approve an identity', async function () {
        const dataHash = ethers.utils.formatBytes32String('testData');
        await idSafe.connect(ngo1).registerIdentity(user.address, dataHash);

        await idSafe.connect(ngo1).approveIdentity(user.address);
        await idSafe.connect(ngo2).approveIdentity(user.address);

        const isFullyApproved = await idSafe.isRegistered(user.address);
        expect(isFullyApproved).to.be.true;
    });

    it('should revoke an identity', async function () {
        const dataHash = ethers.utils.formatBytes32String('testData');
        await idSafe.connect(ngo1).registerIdentity(user.address, dataHash);

        await idSafe.revokeIdentity(user.address);

        const isRegistered = await idSafe.isRegistered(user.address);
        expect(isRegistered).to.be.false;
    });

    it('should check if a user is registered', async function () {
        const dataHash = ethers.utils.formatBytes32String('testData');
        await idSafe.connect(ngo1).registerIdentity(user.address, dataHash);

        const isRegistered = await idSafe.isRegistered(user.address);
        expect(isRegistered).to.be.true;
    });

    it('should store an encrypted identity hash', async function () {
        const dataHash = ethers.utils.formatBytes32String('testData');
        await idSafe.connect(ngo1).registerIdentity(user.address, dataHash);

        const newHash = ethers.utils.formatBytes32String('newData');
        await idSafe.connect(ngo1).storeIdentityHash(user.address, newHash);

        const storedHash = await idSafe.getIdentityHash(user.address);
        expect(storedHash).to.equal(newHash);
    });

    it('should retrieve an identity’s encrypted data hash', async function () {
        const dataHash = ethers.utils.formatBytes32String('testData');
        await idSafe.connect(ngo1).registerIdentity(user.address, dataHash);

        const retrievedHash = await idSafe.getIdentityHash(user.address);
        expect(retrievedHash).to.equal(dataHash);
    });

    it('should check if an address is a recognized NGO', async function () {
        const isNgo1 = await idSafe.isNGO(ngo1.address);
        expect(isNgo1).to.be.true;

        const isNgo2 = await idSafe.isNGO(ngo2.address);
        expect(isNgo2).to.be.true;

        const isNotNgo = await idSafe.isNGO(user.address);
        expect(isNotNgo).to.be.false;
    });

    it('should change the admin address', async function () {
        await idSafe.changeAdmin(newAdmin.address);

        const currentAdmin = await idSafe.admin();
        expect(currentAdmin).to.equal(newAdmin.address);
    });

    it('should add a new NGO address', async function () {
        await idSafe.addNGO(newNGO.address);

        const isNewNgo = await idSafe.isNGO(newNGO.address);
        expect(isNewNgo).to.be.true;
    });

    it('should remove an existing NGO address', async function () {
        await idSafe.removeNGO(ngo1.address);

        const isRemovedNgo = await idSafe.isNGO(ngo1.address);
        expect(isRemovedNgo).to.be.false;
    });

    it('should change the approval threshold', async function () {
        await idSafe.changeApprovalThreshold(1);

        const newThreshold = await idSafe.approvalThreshold();
        expect(newThreshold.toNumber()).to.equal(1);
    });
});
