// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Test, console2} from "forge-std/Test.sol";

import {FixedMath} from "./FixedMath.sol";

// forge create FixedMath --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY
// forge create Simps --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --libraries src/FixedMath.sol:FixedMath:0x5fbdb2315678afecb367f032d93f642f64180aa3
// /System/Volumes/Data/Users/michaelreilly/Library/Python/3.9/bin/slither

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /*
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    */
}

// File: contracts/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Simps is Ownable, Test {
    using FixedMath for int256;

    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;

    event CreatedRoom(address subject, uint256 roomNumber, uint256 steepness);
    event Trade(address trader, address subject, bool isBuy, uint256 shareAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);
    event FeeDestinationChanged(address newDestination);
    event ProtocolFeePercentChanged(uint256 newPercent);
    event SubjectFeePercentChanged(uint256 newPercent);
    event Transfer(address indexed from, address indexed to, uint value);

    enum Curves {
        Quadratic,
        Linear,
        Sigmoid,
        FriendTech
    }

    struct Room {
        Curves curve;
        uint256 floor;
        int256 currentLimit;
        uint256 maxPrice;
        uint256 steepness;
        uint256 sharesSupply;
        mapping(address holder => uint256 balance) sharesBalance;
    }

    mapping(address subject => Room[] room) public rooms;

    function createRoom(Curves curve, uint256 steepness, uint256 floor, uint256 maxPrice, int256 currentLimit) public returns (uint256) {
        require(steepness >= 1_000, "Invalid steepness value");
        require(steepness <= 10_000_000, "Invalid steepness value");
        Room storage r = rooms[msg.sender].push();
        r.curve = curve;
        r.steepness = steepness;
        r.sharesSupply = 1;
        r.floor = floor;
        r.currentLimit = currentLimit;
        r.maxPrice = maxPrice;
        r.sharesBalance[msg.sender] = 1;
        emit CreatedRoom(msg.sender, rooms[msg.sender].length, steepness);
        return rooms[msg.sender].length - 1;
    }

    function getRoomsLength(address sharesSubject) public view returns (uint256) {
        return rooms[sharesSubject].length;
    }

    function setFeeDestination(address feeDestination) public onlyOwner {
        require(feeDestination != address(0), "Invalid address");
        protocolFeeDestination = feeDestination;
        emit FeeDestinationChanged(feeDestination);
    }

    function setProtocolFeePercent(uint256 feePercent) public onlyOwner {
        protocolFeePercent = feePercent;
        emit ProtocolFeePercentChanged(feePercent);
    }

    function setSubjectFeePercent(uint256 feePercent) public onlyOwner {
        subjectFeePercent = feePercent;
        emit SubjectFeePercentChanged(feePercent);
    }

    function getSharesSupply(address sharesSubject, uint256 roomNumber) public view returns (uint256) {
        return rooms[sharesSubject][roomNumber].sharesSupply;
    }

    function getSharesBalance(address sharesSubject, uint256 roomNumber, address holder) public view returns (uint256) {
        return rooms[sharesSubject][roomNumber].sharesBalance[holder];
    }

    function transfer(address recipient, address sharesSubject, uint256 roomNumber, uint amount) external returns (bool) {
        require(rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Invalid address");
        rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] -= amount;
        rooms[sharesSubject][roomNumber].sharesBalance[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function createRoomAndBuyShares(Curves curve, uint256 amount, uint256 steepness, uint256 floor, uint256 maxPrice, int256 currentLimit) payable public {
        createRoom(curve, steepness, floor, maxPrice, currentLimit);
        buyShares(msg.sender, rooms[msg.sender].length - 1, amount);
    }

    // sigmoid
    function getPriceSigmoid(uint256 supply, uint256 amount, uint256 steepness, uint256 floor, uint256 maxPrice, int256 currentLimit) public pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < amount; i++) {
            int256 midpoint = currentLimit;
            int256 numerator = int256(supply + i) - midpoint;
            int256 innerSqrt = (int256(steepness) + (numerator)**2);
            int256 fixedInner = innerSqrt.toFixed();
            int256 fixedDenominator = fixedInner.sqrt();
            int256 fixedNumerator = numerator.toFixed();
            int256 midVal = fixedNumerator.divide(fixedDenominator) + FixedMath.fixed1();
            int256 fixedFinal = (int256(maxPrice) * 1_000_000) / 2 * midVal;
            int256 finalVal = fixedFinal / 1_000_000_000_000 ether;
            total += uint256(finalVal) + floor;
        }
        return total;
    }

    // friend tech
    function getPriceFriend(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = (supply - 1 ) * (supply) * (2 * (supply - 1) + 1) / 6; // 1/6 * (n - 1) * (n) * (2(n - 1) + 1) // 9 * 10 * 19 / 6 = 285 // 
        uint256 sum2 = (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6; // 1/6 * (n - 1 + 1) * (n + 1) * (2(n - 1 + 1) + 1) = 10 * 11 * 21 / 6 = 385
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    // quadratic
    function getPriceQuadratic(uint256 supply, uint256 amount, uint256 steepness, uint256 floor) public pure returns (uint256) {
        uint256 sum1 = (supply - 1 ) * (supply) * (2 * (supply - 1) + 1) / 6;        
        uint256 sum2 = (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / steepness + floor;
    }

    // linear
    function getPriceLinear(uint256 supply, uint256 amount, uint256 steepness, uint256 floor) public pure returns (uint256) {
        uint256 sum1 = (supply - 1) * supply;
        uint256 sum2 = (supply - 1 + amount) * (supply + amount);
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / (steepness / 500) + floor;
    }

    function getPrice(address sharesSubject, uint256 roomNumber, uint256 amount, bool isBuy) view public returns (uint256 price) {
        Room storage r = rooms[sharesSubject][roomNumber];
        uint256 supply = isBuy ? r.sharesSupply : r.sharesSupply - amount;
        uint256 floor = r.floor;
        uint256 steepness = r.steepness;
        if (rooms[sharesSubject][roomNumber].curve == Curves.Quadratic) {
            return getPriceQuadratic(supply, amount, steepness, floor);
        } else if (rooms[sharesSubject][roomNumber].curve == Curves.Linear) {
            return getPriceLinear(supply, amount, steepness, floor);
        } else if (rooms[sharesSubject][roomNumber].curve == Curves.FriendTech) {
            return getPriceFriend(supply, amount);
        } else if (rooms[sharesSubject][roomNumber].curve == Curves.Sigmoid) {
            int256 currentLimit = r.currentLimit;
            uint256 maxPrice = r.maxPrice;
            return getPriceSigmoid(supply, amount, steepness, floor, maxPrice, currentLimit);
        }
    }

    function getBuyPrice(address sharesSubject, uint256 roomNumber, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSubject, roomNumber, amount, true);
    }

    function getSellPrice(address sharesSubject, uint256 roomNumber, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSubject, roomNumber, amount, false);
    }

    function getBuyPriceAfterFee(address sharesSubject, uint256 roomNumber, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(sharesSubject, roomNumber, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(address sharesSubject, uint256 roomNumber, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, roomNumber, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price - protocolFee - subjectFee;
    }

    function buyShares(address sharesSubject, uint256 roomNumber, uint256 amount) public payable {
        require(amount > 0, "Invalid amount");
        require(rooms[sharesSubject][roomNumber].sharesSupply > 0, "Invalid room");
        require(sharesSubject != address(0), "Invalid address");

        require(supply > 0 || sharesSubject == msg.sender, "Only the shares' subject can buy the first share");

        uint256 supply = rooms[sharesSubject][roomNumber].sharesSupply;
        uint256 price = getPrice(sharesSubject, roomNumber, amount, true);

        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;

        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");
        
        rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] = rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] + amount;
        rooms[sharesSubject][roomNumber].sharesSupply = supply + amount;

        emit Trade(msg.sender, sharesSubject, true, amount, price, protocolFee, subjectFee, supply + amount);

        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function sellShares(address sharesSubject, uint256 roomNumber, uint256 amount) public payable {
        uint256 supply = rooms[sharesSubject][roomNumber].sharesSupply;
        uint256 price = getPrice(sharesSubject, roomNumber, amount, false);

        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;

        require(rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] >= amount, "Insufficient shares");

        rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] = rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] - amount;
        rooms[sharesSubject][roomNumber].sharesSupply = supply - amount;

        emit Trade(msg.sender, sharesSubject, false, amount, price, protocolFee, subjectFee, supply - amount);

        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

}