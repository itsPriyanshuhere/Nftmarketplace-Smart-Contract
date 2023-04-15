// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage{

    using Counters for Counters.Counter;
    address payable owner;
    Counters.Counter private _Ids;
    Counters.Counter private _Sold;

    uint256 price = 0.01 ether;

    constructor() ERC721("NFTmarketplace","NFT"){
    owner = payable(msg.sender);
}

struct TokensListed {
    uint256 tokenId;
    address payable owner;
    address payable seller;
    uint256 price;
    bool currentlyListed;
}

mapping(uint256 => TokensListed) private idListedTokens;

function update(uint256 _tokenId, uint256 _listPrice) public payable {
    require(owner == msg.sender, "Only owner can modify");
    idListedTokens[_tokenId].price = _listPrice;
}

function getListPrice(uint256 _tokenId) public view returns(uint256) {
    return idListedTokens[_tokenId].price;
}

function getTokenListed(uint256 _tokenId) public view returns(TokensListed memory) {
    return idListedTokens[_tokenId];
} 

function getListedForToken(uint256 _tokenId) public view returns(bool) {
    return idListedTokens[_tokenId].currentlyListed;
}


    function getCurrentToken() public view returns (uint256){
        return _Ids.current();
    }

    function createToken(string memory tokenURI, uint256 prices) public payable returns(uint){
        require(msg.value == prices, "Not equal to listPrice");
        require(prices > 0, "Invalid Price");

        _Ids.increment();
        uint256 currentTokenId = _Ids.current();
        _safeMint(msg.sender,currentTokenId);
        _setTokenURI(currentTokenId,tokenURI);
        
        createListedToken(currentTokenId,price);
        return currentTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 prices) private{
        idListedTokens[tokenId] = TokensListed(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            prices,
            true
        );

        _transfer(msg.sender, address(this), tokenId);
    }

    function getAllnfts() public view returns(TokensListed[] memory){
        uint count = _Ids.current();
        TokensListed[] memory token = new TokensListed[](count);

        uint currentIndex = 0;

        for(uint i =0;i<count;i++){
            uint currentId = i+1;
            TokensListed storage currentItem = idListedTokens[currentId];
            token[currentIndex] = currentItem;
            currentIndex +=1;
        }

        return token;
    }
    
    function getNfts() public view returns(TokensListed[] memory){
        uint count = _Ids.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i=0;i<count;i++){
            if(idListedTokens[i+1].owner == msg.sender || idListedTokens[i+1].seller == msg.sender){
                itemCount +=1;
            }
        }

        TokensListed[] memory item = new TokensListed[](count);
        for(uint i=0;i<count;i++){
            if(idListedTokens[i+1].owner == msg.sender || idListedTokens[i+1].seller == msg.sender){
                uint currentId = i+1;
                TokensListed storage currentItem = idListedTokens[currentId];
                item[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }
        return item;
    }

    function sale(uint256 tokenId) public payable{
        uint prices = idListedTokens[tokenId].price;
        require(msg.value == prices, "Less amount");
        address seller = idListedTokens[tokenId].seller;
        
        idListedTokens[tokenId].currentlyListed = true;
        idListedTokens[tokenId].seller = payable(msg.sender);
        _Sold.increment();

        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);

        payable(owner).transfer(prices);
        payable(seller).transfer(msg.value);

    }
}
 