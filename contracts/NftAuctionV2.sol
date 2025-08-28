pragma solidity ^0.8.28;
import "./NftAuction.sol";
contract NftAuctionV2  is NftAuction{
    function version() public pure returns(string memory){
        return "v2.0";
    }
}