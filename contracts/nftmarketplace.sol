//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//INTERNAL IMPORT FOR NFT OPENZEPPELIN
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsold;

    address payable owner;
    uint256 listingprice = 0.0025 ether;

    mapping(uint256 => Marketitem) private idMarketitems;

    struct Marketitem {
        uint256 itemId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketitemscreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    modifier onlyowner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    constructor() ERC721("NFT cert Token", "NFTM") {
        owner = payable(msg.sender);
    }

    function updateListingprice(
        uint256 _listingprice
    ) public payable onlyowner {
        listingprice = _listingprice;
    }

    function getlistingprice() public view returns (uint256) {
        return listingprice;
    }

    //Lets create NFT Token function

    function createtoken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    //creating market items

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "price must be at least 1 ");
        require(
            msg.value == listingprice,
            "price must be equal to listing price"
        );
        idMarketitems[tokenId] = Marketitem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);
        emit idMarketitemscreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    //function for resale
    function reselltoken(uint256 tokenId, uint256 price) public payable {
        require(
            idMarketitems[tokenId].owner == msg.sender,
            "only item owner can perform this sale"
        );
        require(
            msg.value == listingprice,
            "price must be equal to listing price"
        );

        idMarketitems[tokenId].sold = false;
        idMarketitems[tokenId].price = price;
        idMarketitems[tokenId].seller = payable(msg.sender);
        idMarketitems[tokenId].owner = payable(address(this));

        _itemsold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    //function create Market sale
    function createmarketsale(uint256 tokenId) public payable {
        uint256 price = idMarketitems[tokenId].price;

        require(
            msg.value == price,
            "please submit the asking price in order to complete purchase"
        );
        idMarketitems[tokenId].owner = payable(msg.sender);
        idMarketitems[tokenId].sold = true;
        idMarketitems[tokenId].owner = payable(address(0));

        _itemsold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingprice);
        payable(idMarketitems[tokenId].seller).transfer(msg.value);
    }

    //function unsold market items
    function fetchMarketitems() public view returns (Marketitem[] memory) {
        uint256 itemstoshow = _itemsold.current();
        uint256 itemcount = _tokenIds.current();
        uint256 unsolditems = itemcount - itemstoshow;
        uint256 currentindex = 0;

        Marketitem[] memory items = new Marketitem[](unsolditems);
        for (uint256 i = 0; i < itemcount; i++) {
            if (idMarketitems[i + 1].owner == address(this)) {
                uint256 currentid = i + 1;

                Marketitem storage currentItem = idMarketitems[currentid];
                items[currentindex] = currentItem;
                currentindex += 1;
            }
        }
        return items;
    }
    //purchase 
    function fetchmyNFT() public view returns(Marketitem[] memory)
    {
        uint256 totalcount = _tokenIds.current(); 
        uint256 itemcount = 0;
        uint256 currentindex = 0;

        for (uint256 i = 0; i < totalcount; i++) {
            if(idMarketitems[i+1].owner == msg.sender)
            {
                itemcount += 1;
            }
            
        }
        Marketitem[] memory items = new Marketitem[](itemcount);
        for (uint256 i = 0; i < totalcount; i++) {

            if (idMarketitems[i+1].owner == msg.sender) {
                
            uint256 currentid = i + 1;
            Marketitem storage currentItem = idMarketitems[currentid];
            items[currentindex] = currentItem;
            currentindex += 1;
            }

        }
        return items;
    }
    //single user items
    function fetchitemsListed() public view returns(Marketitem[] memory)
    {
        uint256 totalcount = _tokenIds.current();
        uint256 itemcount = 0;
        uint256 currentindex = 0;
        
        for (uint256 i = 0; i < totalcount; i++) {
            if(idMarketitems[i+1].seller == msg.sender)
            {
                itemcount += 1;
            }
            
        }
        Marketitem[] memory items = new Marketitem[](itemcount);
        for (uint256 i = 0; i < totalcount; i++) {
            if(idMarketitems[i+1].seller == msg.sender)
            {
                uint256 currentid = i + 1;
                Marketitem storage currentitem = idMarketitems[currentid];
                items[currentindex] = currentitem;
                currentindex += 1;

            }
            
        }
        return items;
    }
}
