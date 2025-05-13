// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title NFTBatchMint
 * @dev Advanced NFT contract with batch minting capability
 * @notice This contract implements a high-performance NFT system with:
 * - Gas-efficient batch minting
 * - Metadata management
 * - Ownership tracking
 * - Modern security features
 */
contract NFTBatchMint is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 public constant MAX_BATCH_SIZE = 50; // Optimized for gas efficiency
    string public baseURI;
    uint256 public mintPrice = 0.05 ether; // Default mint price

    // Events for frontend integration
    event BatchMinted(address indexed to, uint256[] tokenIds);
    event BaseURIUpdated(string newBaseURI);
    event MintPriceUpdated(uint256 newPrice);

    /**
     * @dev Constructor function
     * @param name NFT collection name
     * @param symbol NFT collection symbol
     * @param initialBaseURI Initial base URI for metadata
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory initialBaseURI
    ) ERC721(name, symbol) {
        baseURI = initialBaseURI;
    }

    /**
     * @dev Batch mint NFTs to a single address
     * @param to Address to receive the NFTs
     * @param count Number of NFTs to mint
     * @param uris Array of metadata URIs (must match count)
     * @notice This is the core batch minting function with gas optimization
     */
    function batchMint(
        address to,
        uint256 count,
        string[] memory uris
    ) external payable {
        require(count > 0, "Count must be positive");
        require(count <= MAX_BATCH_SIZE, "Exceeds max batch size");
        require(uris.length == count, "URI count mismatch");
        require(msg.value >= mintPrice.mul(count), "Insufficient payment");

        uint256[] memory mintedTokenIds = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uris[i]);
            mintedTokenIds[i] = tokenId;
        }

        emit BatchMinted(to, mintedTokenIds);
    }

    /**
     * @dev Update base URI for metadata
     * @param newBaseURI New base URI
     * @notice Only callable by owner
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @dev Update mint price
     * @param newPrice New mint price in wei
     * @notice Only callable by owner
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    /**
     * @dev Withdraw contract balance
     * @notice Only callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // Override functions for ERC721 compatibility
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Get current token counter
     * @return Current token ID counter
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Get owner's token IDs
     * @param owner Address to query
     * @return Array of token IDs owned by the address
     */
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }
}
