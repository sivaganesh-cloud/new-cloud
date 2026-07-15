// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMockeERC {
    function transferPrivate(address to, uint256 amount, bytes32 encryptedProof) external returns (bool);
}

contract SecuredPayEscrow {
    struct Offer {
        address recruiter;
        address candidate;
        bytes32 encryptedSalaryHash; // Sha256 of (Candidate Address + Salt + Salary)
        uint256 signingBonus;
        bool isAccepted;
        bool isClosed;
    }

    uint256 public offerCount;
    mapping(uint256 => Offer) public offers;
    address public eERCAddress;

    event OfferCreated(uint256 indexed offerId, address indexed recruiter, address indexed candidate);
    event OfferAccepted(uint256 indexed offerId, address indexed candidate);

    constructor(address _eERCAddress) {
        eERCAddress = _eERCAddress;
    }

    function createOffer(
        address _candidate, 
        bytes32 _encryptedSalaryHash, 
        uint256 _signingBonus
    ) external payable {
        require(_candidate != address(0), "Invalid candidate");
        
        offerCount++;
        offers[offerCount] = Offer({
            recruiter: msg.sender,
            candidate: _candidate,
            encryptedSalaryHash: _encryptedSalaryHash,
            signingBonus: _signingBonus,
            isAccepted: false,
            isClosed: false
        });

        emit OfferCreated(offerCount, msg.sender, _candidate);
    }

    function acceptOffer(uint256 _offerId, string memory salt, uint256 actualSalary) external {
        Offer storage offer = offers[_offerId];
        require(msg.sender == offer.candidate, "Not authorized candidate");
        require(!offer.isAccepted, "Already accepted");
        require(!offer.isClosed, "Offer closed");

        // Verification of the secret off-chain negotiated salary without exposing it
        bytes32 computedHash = keccak256(abi.encodePacked(msg.sender, salt, actualSalary));
        require(computedHash == offer.encryptedSalaryHash, "Salary verification failed");

        offer.isAccepted = true;
        offer.isClosed = true;

        // Payout the signing bonus in eERC
        IMockeERC(eERCAddress).transferPrivate(offer.candidate, offer.signingBonus, computedHash);

        emit OfferAccepted(_offerId, msg.sender);
    }
}