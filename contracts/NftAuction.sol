// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


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

    /**
     * @notice ChainLink 价格源映射
     * @dev address(0) 代表 ETH 价格源
     */
    mapping(address =>AggregatorV3Interface) public priceFeeds;

    /**
     *  给代币地址设置ChainLink价格源
     * @param payToken 代币地址，address(0) 一般代表 ETH。
     * @param priceFeed ChainLink 价格预言机地址
     */
    function setPricesFeed(address payToken,address priceFeed) external{
        priceFeeds[payToken] = AggregatorV3Interface(priceFeed);
    }
    /**
     * 
     * @param payToken 代币地址，address(0) 一般代表 ETH。
     * @return 返回代币的最新价格，8位小数
     */
    function getChainLinkFeedLatestPrice(address payToken) public view returns(uint256){
        AggregatorV3Interface priceFeed = priceFeeds[payToken];
        (,int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }
    /**
     * 
     * @param _auctionId 拍卖ID
     * @param _bidAmount  出价金额
     * @param _payToken  支付代币地址，address(0) 一般代表 ETH。
     * @dev 竞拍
     */
    function placeBid(
        uint256 _auctionId,
        uint256 _bidAmount,
        address _payToken
        ) external payable{
        //当前拍卖
        Auction storage auction = auctions[_auctionId]; 
        // 拍卖必须存在
        require(auction.seller != address(0), "auction not exist");
        // 拍卖未结束
        require(!auction.ended && block.timestamp < auction.startTime +auction.duration,"auction is ended");
        
        uint256 payValue;
        // 计算出价金额  根据_payToken算出美元价值
        if(_payToken == address(0)){
            _bidAmount = msg.value;
            payValue = _bidAmount * uint(getChainLinkFeedLatestPrice(address(0)));
        }else{
            payValue = _bidAmount * uint(getChainLinkFeedLatestPrice(_payToken));
        }
        uint256 startPrice = auction.startPrice * uint(getChainLinkFeedLatestPrice(auction.payToken));
        uint256 highestBid = auction.hinghestBid * uint(getChainLinkFeedLatestPrice(auction.payToken));
        require(payValue >= startPrice && payValue >highestBid,"bid amount is too low");
        
        // 支付出价金额 转移 ERC20 到合约  
        if(_payToken !=address(0)){
            IERC20(_payToken).transferFrom(msg.sender,address(this),_bidAmount);
        }        

        // 如果有最高出价者，返还之前的出价
        if(auction.highestBid > 0){
            //出价是ETH 退还ETH
            if(auction.payToken == address(0)){
                payable(auction.hightestBidder).transfer(auction.highestBid);
            }else{ // 出价是ERC20 退还ERC20
                IERC20(auction.payToken).transfer(auction.hightestBidder,auction.highestBid);
            }
        }
        //更新合约
        auction.hinghestBid = _bidAmount;
        auction.hightestBidder = msg.sender;
        auction.payToken = _payToken;

    }


}