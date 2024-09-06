// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract IDSafeNFT is ERC721URIStorage {
    struct Identity {
        bool isRegistered;
        bool isFullyApproved;
        address[] approvers;
        uint approvals;
        bytes32 dataHash;  // Encrypted hash of the identity data
    }

    mapping(address => Identity) private identities;
    address[] public ngoAddresses;
    uint public approvalThreshold;
    address public admin;
    uint public tokenCounter;

    event IdentityRegistered(address indexed user, bytes32 dataHash);
    event IdentityApproved(address indexed approver, address indexed user);
    event IdentityRevoked(address indexed user);
    event IdentityFullyApproved(address indexed user);
    event IdentityStored(address indexed user, bytes32 dataHash);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyNGO() {
        require(isNGO(msg.sender), "Only approved NGOs can perform this action");
        _;
    }

    constructor(address[] memory _ngoAddresses, uint _approvalThreshold) ERC721("IDSafeNFT", "IDSNFT") {
        require(_approvalThreshold > 0, "Approval threshold must be greater than 0");
        require(_ngoAddresses.length >= _approvalThreshold, "Not enough NGOs for the given threshold");
        admin = msg.sender;
        ngoAddresses = _ngoAddresses;
        approvalThreshold = _approvalThreshold;
        tokenCounter = 0;
    }

    // Function to register identity (NGO can call this on behalf of a refugee)
    function registerIdentity(address user, bytes32 encryptedDataHash) public onlyNGO {
        require(!identities[user].isRegistered, "User is already registered");

        identities[user].isRegistered = true;
        identities[user].dataHash = encryptedDataHash;
        emit IdentityRegistered(user, encryptedDataHash);
    }

    // Function to approve an identity
    function approveIdentity(address user, string memory tokenURI) public onlyNGO {
        require(identities[user].isRegistered, "User is not registered");
        require(!hasApproved(user, msg.sender), "NGO has already approved this identity");
        require(!identities[user].isFullyApproved, "Identity is already fully approved");

        identities[user].approvers.push(msg.sender);
        identities[user].approvals++;

        emit IdentityApproved(msg.sender, user);

        // Check if identity has reached the approval threshold
        if (identities[user].approvals >= approvalThreshold) {
            // Mark identity as fully approved
            identities[user].isFullyApproved = true;
            // Mint NFT to the user
            mintIdentityNFT(user, tokenURI);
            emit IdentityFullyApproved(user);
        }
    }

    // Internal function to mint NFT
    function mintIdentityNFT(address user, string memory tokenURI) internal {
        _safeMint(user, tokenCounter);
        _setTokenURI(tokenCounter, tokenURI);
        tokenCounter++;
    }

    // Function to check if a specific NGO has already approved an identity
    function hasApproved(address user, address ngo) public view returns (bool) {
        for (uint i = 0; i < identities[user].approvers.length; i++) {
            if (identities[user].approvers[i] == ngo) {
                return true;
            }
        }
        return false;
    }

    // Function to revoke an identity (Admin-only)
    function revokeIdentity(address user) public onlyAdmin {
        require(identities[user].isRegistered, "User is not registered");

        delete identities[user];  // Delete the identity from the mapping

        emit IdentityRevoked(user);
    }

    // Function to store an encrypted data hash of the identity information (for privacy)
    function storeIdentityHash(address user, bytes32 encryptedHash) public onlyNGO {
        require(identities[user].isRegistered, "User is not registered");

        identities[user].dataHash = encryptedHash;
        emit IdentityStored(user, encryptedHash);
    }

    // Function to retrieve an identity’s encrypted data hash
    function getIdentityHash(address user) public view returns (bytes32) {
        require(identities[user].isRegistered, "User is not registered");

        return identities[user].dataHash;
    }

    // Function to check if an address is a recognized NGO
    function isNGO(address ngo) public view returns (bool) {
        for (uint i = 0; i < ngoAddresses.length; i++) {
            if (ngoAddresses[i] == ngo) {
                return true;
            }
        }
        return false;
    }

    // Function to change the admin (Admin-only)
    function changeAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    // Function to add a new NGO (Admin-only)
    function addNGO(address ngo) public onlyAdmin {
        ngoAddresses.push(ngo);
    }

    // Function to remove an NGO (Admin-only)
    function removeNGO(address ngo) public onlyAdmin {
        for (uint i = 0; i < ngoAddresses.length; i++) {
            if (ngoAddresses[i] == ngo) {
                ngoAddresses[i] = ngoAddresses[ngoAddresses.length - 1];  // Move the last element to the deleted position
                ngoAddresses.pop();  // Remove the last element
                break;
            }
        }
    }

    // Function to change the approval threshold (Admin-only)
    function changeApprovalThreshold(uint newThreshold) public onlyAdmin {
        require(newThreshold > 0, "Threshold must be greater than 0");
        require(newThreshold <= ngoAddresses.length, "Threshold exceeds the number of NGOs");
        approvalThreshold = newThreshold;
    }
}
