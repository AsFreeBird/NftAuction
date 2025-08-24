// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NftAuction is Initializable,UUPSUpgradeable{

    struct Auction {
        address seller; // 卖家
        address hightestBidder; // 最高出价者
        uint256 stratPrice;// 起拍价
        uint256 hinghestBid; // 最高出价
        uint256 startTime; // 开始时间
        bool ended; // 是否结束
        uint256 duration; // 持续时间
        address nftAddress; // NFT合约地址
        uint256 tokenId; // NFT的tokenId
        address payToken; // 支付代币地址
    }  

    address public admin; // 管理员地址  
    
    uint256 public auctionId; // 拍卖ID

    mapping(uint256=> Auction) public auctions; // 拍卖列表
    
    // 初始化
    function initialize() public initializer{
        admin = msg.sender;
    }

    function createAuction(
        uint256 _startPrice,
        uint256 _duration,
        address _nftAddress,
        uint256 _tokenId
        ) public{

        require(msg.sender == admin,"adimin can not create auction");

        require(_duration>10,"duration must > 10s");

        require(_startPrice>0,"startPrice must > 0");

        // 将NFT转移到合约地址
        IERC721(_nftAddress).transferFrom(msg.sender,address(this),_tokenId);
        
        // 创建拍卖
        auctions[auctionId] = Auction({
            seller:msg.sender,
            duration:_duration,
            startTime:block.timestamp,
            ended: false,
            stratPrice:_startPrice,
            hinghestBid:0,
            hightestBidder:address(0),
            nftAddress:_nftAddress,
            tokenId:_tokenId,
            payToken:address(0)
        });

        auctionId++;
    }



}