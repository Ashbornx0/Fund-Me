// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

//Best Practice- put the name of the contract + 2*underscore.
//You can easily tell what contract the error came from.
error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public s__addressToAmountFunded;
    address[] public s__funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5e18;
    AggregatorV3Interface private s__priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        // To keep it modular
        s__priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s__priceFeed) >= MINIMUM_USD, 
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s__addressToAmountFunded[msg.sender] += msg.value;
        s__funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
       // AggregatorV3Interface priceFeed = AggregatorV3Interface(
       //     0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return s__priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s__funders.length;
        for(uint256 funderIndex = 0;
        funderIndex < fundersLength;
        funderIndex++)
        {
            address funder = s__funders[funderIndex];
            s__addressToAmountFunded[funder] = 0;
        }
        s__funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{
            value: address(this).balance
            }("");
        require(callSuccess, "Call failed");
    }


    function withdraw() public onlyOwner { 
        //reads from storage - very high gas.
        for (uint256 funderIndex = 0; 
        funderIndex < s__funders.length; 
        funderIndex++
        ) {
            address funder = s__funders[funderIndex];
            s__addressToAmountFunded[funder] = 0;
        }
        s__funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
    /**
    View/ Pure functions (Getters)
     */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns(uint256) {
    return s__addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns(address) {
        return s__funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}   



// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
