// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
interface IFakeNFTMarketplace {
    function getPrice() external view returns (uint256);
    function available(uint256 _tokenId) external view returns (bool);
    function purchase(uint256 _tokenId) external payable;
}
interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns (uint256);
    function tokenofOwnerByIndex(address owner, uint256 index) 
    external
    view
    returns (uint256);
}
contract CryptoDevsDao is Ownable {

struct Proposal {
    uint256 nftTokenId;
    uint256 deadline;
    uint256 yayVotes;
    uint256 nayVotes;
    bool executed;
    mapping(uint256 => bool) voters;

}
mapping(uint256 => Proposal) public proposals;
uint256 public numProposals;

IFakeNFTMarketplace nftMarketplace;
ICryptoDevsNFT cryptoDevsNFT;

constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
}

modifier nftHolderOnly() {
    require(
        cryptoDevsNFT.balanceOf(msg.sender)>0, "NOT_A_DAO_MEMBER");
        _;

}
function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256){
    require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
    Proposal storage proposal = proposals[numProposals];
    proposal.nftTokenId = _nftTokenId;
    proposal.deadline = block.timestamp + 5 minutes;
    numProposals++;
    return numProposals - 1;

}
modifier activeProposalOnly(uint256 proposalIndex) {
    require(
       proposals[proposalIndex].deadline > block.timestamp,
       "DEADLINE_EXCEEDED"
    );
    _;

}

enum Vote {Yay, Nay}
function voteOnProposal(uint256 proposalIndex, Vote vote)
    external
    nftHolderOnly
    activeProposalOnly(proposalIndex)
    {
       Proposal storage proposal = proposals[proposalIndex];
       uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
       uint256 numVotes = 0;
       for (uint256 i = 0; i < voterNFTBalance; i++) {
        uint256 tokenId = cryptoDevsNFT.tokenofOwnerByIndex(msg.sender, i);
        if (proposal.voters[tokenId] == false) {
            numVotes++;
            proposal.voters[tokenId] = true;
        }
    }
    require(numVotes > 0, "ALREADY_VOTED");

    if (vote == Vote.Yay) {
        proposal.yayVotes += numVotes;
    } else {
        proposal.nayVotes += numVotes;
    }
    }
modifier inactiveProposalOnly(uint256 proposalIndex){
    require(
        proposals[proposalIndex].deadline <= block.timestamp,
        "DEADLINE_NOT_EXCEEDED"
    );
    require(
        proposals[proposalIndex].executed == false,
        "PROPOSAL_ALREADY_EXECUTED"
    );
    _;

    }


}