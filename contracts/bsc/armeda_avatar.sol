// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../other/random_generator.sol";


// 用户定制出来的nft头像
contract AreamdaAvatar is RandomGenerator, Ownable, ERC721Enumerable, ERC721URIStorage {
    // for inherit
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        ERC721._burn(tokenId);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Enumerable).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId
        || super.supportsInterface(interfaceId);
    }

    using Address for address;
    using Strings for uint256;

    mapping(address => uint) public minters;
    address public superMinter;

    function setSuperMinter(address newSuperMinter_) public onlyOwner returns (bool) {
        superMinter = newSuperMinter_;
        return true;
    }

    function setMinterBatch(address[] calldata newMinters_, uint[] calldata amounts_) public onlyOwner returns (bool) {
        require(newMinters_.length > 0 && newMinters_.length == amounts_.length,"ids and amounts length mismatch");
        for (uint i = 0; i < newMinters_.length; ++i) {
            minters[newMinters_[i]] = amounts_[i];
        }
        return true;
    }

    struct CardInfo {
        uint currentAmount;
        uint burnedAmount;
        uint maxAmount;
        string baseURI;
    }

   CardInfo public cardInfoes;    
    

    constructor(string memory name_, string memory symbol_, string memory myBaseURI_) ERC721(name_, symbol_) {
        cardInfoes.baseURI = myBaseURI_;
    }

    function setMyBaseURI(string calldata uri_) public onlyOwner {
        cardInfoes.baseURI = uri_;
    }

    function setMaxAmount(uint amount_) public onlyOwner {
       cardInfoes.maxAmount = amount_; 
    }

    function setTokenURI(uint tokenId_, string calldata tokenURI_) public onlyOwner returns (bool) {
        _setTokenURI(tokenId_, tokenURI_);
        return true;
    }

    function mint(address player_) public returns (uint256) {
        if (superMinter != _msgSender()) {
            require(minters[_msgSender()] > 0, "K: not minter");
            minters[_msgSender()] -= 1;
        }

        require(cardInfoes.currentAmount < cardInfoes.maxAmount, "k: amount out of limit");
        cardInfoes.currentAmount += 1;

        uint tokenId = random(gasleft());
        _mint(player_, tokenId);
        _setTokenURI(tokenId, tokenId.toHexString(32));

        return tokenId;
    }

    function mintWithId(address player_, uint tokenId_) public returns (bool) {
        if (superMinter != _msgSender()) {
            require(minters[_msgSender()] > 0, "K: not minter");
            minters[_msgSender()] -= 1;
        }

        require(cardInfoes.currentAmount < cardInfoes.maxAmount, "k: amount out of limit");
        cardInfoes.currentAmount += 1;

        _mint(player_, tokenId_);
        _setTokenURI(tokenId_, tokenId_.toHexString(32));

        return true;
    }

    function mintMulti(address player_, uint amount_) public returns (uint[] memory) {
        require(amount_ > 0, "K: missing amount");
        require(cardInfoes.maxAmount - cardInfoes.currentAmount >= amount_, "K: amount out of limit");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()] >= amount_, "K: not minter");
            minters[_msgSender()] -= amount_;
        }

        cardInfoes.currentAmount += amount_;

        uint tokenId;
        uint[] memory info = new uint[](amount_);
        for (uint i = 0; i < amount_; ++i) {
            tokenId = random(gasleft());
            _mint(player_, tokenId);
            _setTokenURI(tokenId, tokenId.toHexString(32));
            info[i] = tokenId;
        }
        return info;
    }

    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "K: burner isn't owner");

        cardInfoes.burnedAmount += 1;
        _burn(tokenId_);
        return true;
    }

    function burnMulti(uint[] calldata tokenIds_) public returns (bool){
        for (uint i = 0; i < tokenIds_.length; ++i) {
            burn(tokenIds_[i]);
        }
        return true;
    }

    function tokenURI(uint tokenId_) override(ERC721URIStorage, ERC721) public view returns (string memory) {
        require(_exists(tokenId_), "K: nonexistent token");

        string memory tURI = super.tokenURI(tokenId_);
        string memory base = _myBaseURI();

        return string(abi.encodePacked(base, "/", tURI));
    }

    function batchTokenURI(address account_) public view returns (string[] memory) {
        uint amount = balanceOf(account_);
        uint tokenId;
        string[] memory info = new string[](amount);
        for (uint i = 0; i < amount; i++) {
            tokenId = tokenOfOwnerByIndex(account_, i);
            info[i] = tokenURI(tokenId);
        }
        return info;
    }

    function _myBaseURI() internal view returns (string memory) {
        return cardInfoes.baseURI;
    }
}
