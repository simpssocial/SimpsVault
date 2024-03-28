// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {FixedMath} from "./FixedMath.sol";

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Simps
 * @dev A contract for creating and managing rooms for trading shares with various curves.
 */
contract SimpsVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
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
        Sigmoid
    }

    struct Room {
        Curves curve;
        uint256 floor;
        int256 midPoint;
        uint256 maxPrice;
        uint256 steepness;
        uint256 sharesSupply;
        mapping(address holder => uint256 balance) sharesBalance;
    }

    mapping(address subject => Room[] room) public rooms;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     * @param initialOwner The address to be set as the initial owner.
     */
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Checks whether the upgrade is authorized.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /**
     * @dev Creates a new room for trading shares with the specified bonding curve.
     * @param curve The curve type for price calculation.
     * @param steepness The steepness parameter for the curve.
     * @param floor The floor price for the shares.
     * @param maxPrice The maximum price for the shares.
     * @param midPoint The mid point of the sigmoid curve.
     * @return room The index of the created room.
     */
    function createRoom(Curves curve, uint256 steepness, uint256 floor, uint256 maxPrice, int256 midPoint) public returns (uint256 room) {
        require(msg.sender == tx.origin, "Invalid sender");
        require(steepness >= 1_000, "Invalid steepness value");
        require(steepness <= 10_000_000, "Invalid steepness value");
        Room storage r = rooms[msg.sender].push();
        r.curve = curve;
        r.steepness = steepness;
        r.sharesSupply = 1;
        r.floor = floor;
        r.midPoint = midPoint;
        r.maxPrice = maxPrice;
        r.sharesBalance[msg.sender] = 1;
        emit CreatedRoom(msg.sender, rooms[msg.sender].length, steepness);
        return rooms[msg.sender].length - 1;
    }

    /**
     * @dev Sets the address where protocol fees will be sent.
     * @param feeDestination The address to set as the fee destination.
     */
    function setFeeDestination(address feeDestination) public onlyOwner {
        require(feeDestination != address(0), "Invalid address");
        protocolFeeDestination = feeDestination;
        emit FeeDestinationChanged(feeDestination);
    }

    /**
     * @dev Sets the percentage of protocol fees.
     * @param feePercent The percentage of protocol fees to set.
     */
    function setProtocolFeePercent(uint256 feePercent) public onlyOwner {
        require(feePercent <= 500000000000000000, "Invalid fee percent"); // max 50%
        protocolFeePercent = feePercent;
        emit ProtocolFeePercentChanged(feePercent);
    }

    /**
     * @dev Sets the percentage of subject fees.
     * @param feePercent The percentage of subject fees to set.
     */
    function setSubjectFeePercent(uint256 feePercent) public onlyOwner {
        require(feePercent <= 500000000000000000, "Invalid fee percent"); // max 50%
        subjectFeePercent = feePercent;
        emit SubjectFeePercentChanged(feePercent);
    }

    /**
     * @dev Gets the number of rooms for a given shares subject.
     * @param sharesSubject The address of the shares subject.
     * @return The number of rooms.
     */
    function getRoomsLength(address sharesSubject) public view returns (uint256) {
        return rooms[sharesSubject].length;
    }

    /**
     * @dev Gets the total supply of shares for a given room.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @return The total supply of shares.
     */
    function getSharesSupply(address sharesSubject, uint256 roomNumber) public view returns (uint256) {
        return rooms[sharesSubject][roomNumber].sharesSupply;
    }

    /**
     * @dev Gets the balance of shares for a given holder in a specific room.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param holder The address of the shares holder.
     * @return The balance of shares.
     */
    function getSharesBalance(address sharesSubject, uint256 roomNumber, address holder) public view returns (uint256) {
        return rooms[sharesSubject][roomNumber].sharesBalance[holder];
    }

    /**
     * @dev Transfers shares from the sender to a recipient.
     * @param recipient The address of the recipient.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param amount The amount of shares to transfer.
     * @return A boolean indicating whether the transfer was successful.
     */
    function transfer(address recipient, address sharesSubject, uint256 roomNumber, uint amount) external returns (bool) {
        require(rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Invalid address");
        rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] -= amount;
        rooms[sharesSubject][roomNumber].sharesBalance[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Creates a new room for trading shares with the specified parameters and buys shares in that room.
     * @param curve The curve type for price calculation.
     * @param amount The amount of shares to buy.
     * @param steepness The steepness parameter for the curve.
     * @param floor The floor price for the shares.
     * @param maxPrice The maximum price for the shares.
     * @param midPoint The mid point of the sigmoid curve.
     * @return room The index of the created room.
     */
    function createRoomAndBuyShares(Curves curve, uint256 amount, uint256 steepness, uint256 floor, uint256 maxPrice, int256 midPoint) payable public returns (uint256 room) {
        uint256 roomIndex = createRoom(curve, steepness, floor, maxPrice, midPoint);
        buyShares(msg.sender, roomIndex, amount);
        return roomIndex;
    }

    /**
     * @dev Calculates the price for a Sigmoid curve given the supply, amount, and curve parameters.
     * @param supply The current supply of shares.
     * @param amount The amount of shares to buy.
     * @param steepness The steepness parameter for the curve.
     * @param floor The floor price for the shares.
     * @param maxPrice The maximum price for the shares.
     * @param midPoint The mid point of the sigmoid curve.
     * @return price The total price for the shares.
     */
    function getPriceSigmoid(uint256 supply, uint256 amount, uint256 steepness, uint256 floor, uint256 maxPrice, int256 midPoint) public pure returns (uint256 price) {
        uint256 total = 0;
        int256 numerator = int256(supply + amount) - midPoint;
        int256 innerSqrt = (int256(steepness) + (numerator)**2);
        int256 fixedInner = innerSqrt.toFixed();
        int256 fixedDenominator = fixedInner.sqrt();
        int256 fixedNumerator = numerator.toFixed();
        int256 midVal = fixedNumerator.divide(fixedDenominator) + FixedMath.fixed1();
        int256 fixedFinal = (int256(maxPrice) * 1_000_000) / 2 * midVal;
        int256 finalVal = fixedFinal / 1_000_000_000_000 ether;
        total += uint256(finalVal) + floor;
        return total;
    }

    /**
     * @dev Calculates the price for a quadratic curve given the supply, amount, steepness, and floor price.
     * @param supply The current supply of shares.
     * @param amount The amount of shares to buy.
     * @param steepness The steepness parameter for the curve.
     * @param floor The floor price for the shares.
     * @return price The total price for the shares.
     */
    function getPriceQuadratic(uint256 supply, uint256 amount, uint256 steepness, uint256 floor) public pure returns (uint256 price) {
        uint256 sum1 = (supply - 1 ) * (supply) * (2 * (supply - 1) + 1) / 6;        
        uint256 sum2 = (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / steepness + floor;
    }

    /**
     * @dev Calculates the price for a linear curve given the supply, amount, steepness, and floor price.
     * @param supply The current supply of shares.
     * @param amount The amount of shares to buy.
     * @param steepness The steepness parameter for the curve.
     * @param floor The floor price for the shares.
     * @return price The total price for the shares.
     */
    function getPriceLinear(uint256 supply, uint256 amount, uint256 steepness, uint256 floor) public pure returns (uint256 price) {
        uint256 sum1 = (supply - 1) * supply;
        uint256 sum2 = (supply - 1 + amount) * (supply + amount);
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / (steepness / 500) + floor;
    }

    /**
     * @dev Calculates the price for buying or selling shares based on the specified parameters.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param amount The amount of shares to buy or sell.
     * @param isBuy A boolean indicating whether the transaction is a buy or sell.
     * @return price The calculated price for the shares.
     */
    function getPrice(address sharesSubject, uint256 roomNumber, uint256 amount, bool isBuy) view public returns (uint256 price) {
        Room storage r = rooms[sharesSubject][roomNumber];
        uint256 supply = isBuy ? r.sharesSupply : r.sharesSupply - amount;
        uint256 floor = r.floor;
        uint256 steepness = r.steepness;
        if (rooms[sharesSubject][roomNumber].curve == Curves.Quadratic) {
            return getPriceQuadratic(supply, amount, steepness, floor);
        } else if (rooms[sharesSubject][roomNumber].curve == Curves.Linear) {
            return getPriceLinear(supply, amount, steepness, floor);
        } else if (rooms[sharesSubject][roomNumber].curve == Curves.Sigmoid) {
            int256 midPoint = r.midPoint;
            uint256 maxPrice = r.maxPrice;
            return getPriceSigmoid(supply, amount, steepness, floor, maxPrice, midPoint);
        }
    }

    /**
     * @dev Calculates the buy price for shares based on the specified parameters.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param amount The amount of shares to buy.
     * @return price The calculated buy price for the shares.
     */
    function getBuyPrice(address sharesSubject, uint256 roomNumber, uint256 amount) public view returns (uint256 price) {
        return getPrice(sharesSubject, roomNumber, amount, true);
    }

    /**
     * @dev Calculates the sell price for shares based on the specified parameters.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param amount The amount of shares to sell.
     * @return price The calculated sell price for the shares.
     */
    function getSellPrice(address sharesSubject, uint256 roomNumber, uint256 amount) public view returns (uint256 price) {
        return getPrice(sharesSubject, roomNumber, amount, false);
    }

    /**
     * @dev Calculates the buy price for shares after applying protocol and subject fees.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param amount The amount of shares to buy.
     * @return price The calculated buy price for the shares after fees.
     */    
    function getBuyPriceAfterFee(address sharesSubject, uint256 roomNumber, uint256 amount) public view returns (uint256 price) {
        uint256 buyPrice = getBuyPrice(sharesSubject, roomNumber, amount);
        uint256 protocolFee = buyPrice * protocolFeePercent / 1 ether;
        uint256 subjectFee = buyPrice * subjectFeePercent / 1 ether;
        return buyPrice + protocolFee + subjectFee;
    }

    /**
     * @dev Calculates the sell price for shares after applying protocol and subject fees.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param amount The amount of shares to sell.
     * @return price The calculated sell price for the shares after fees.
     */
    function getSellPriceAfterFee(address sharesSubject, uint256 roomNumber, uint256 amount) public view returns (uint256 price) {
        uint256 sellPrice = getSellPrice(sharesSubject, roomNumber, amount);
        uint256 protocolFee = sellPrice * protocolFeePercent / 1 ether;
        uint256 subjectFee = sellPrice * subjectFeePercent / 1 ether;
        return sellPrice - protocolFee - subjectFee;
    }

    /**
     * @dev Allows a user to buy shares.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param amount The amount of shares to buy.
     */
    function buyShares(address sharesSubject, uint256 roomNumber, uint256 amount) public payable {
        require(amount > 0, "Invalid amount");
        require(rooms[sharesSubject][roomNumber].sharesSupply > 0, "Invalid room");
        require(sharesSubject != address(0), "Invalid address");

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

        if (msg.value > price + protocolFee + subjectFee) {
            (bool success3, ) = msg.sender.call{value: msg.value - price - protocolFee - subjectFee}("");
            require(success3, "Unable to send funds");
        }
    }

    /**
     * @dev Allows a user to sell shares.
     * @param sharesSubject The address of the shares subject.
     * @param roomNumber The index of the room.
     * @param amount The amount of shares to sell.
     */
    function sellShares(address sharesSubject, uint256 roomNumber, uint256 amount) public payable {
        require(amount > 0, "Invalid amount");
        uint256 supply = rooms[sharesSubject][roomNumber].sharesSupply;
        require(supply > amount, "Cannot sell the last share");
        require(rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] >= amount, "Insufficient shares");

        uint256 price = getPrice(sharesSubject, roomNumber, amount, false);

        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;

        rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] = rooms[sharesSubject][roomNumber].sharesBalance[msg.sender] - amount;
        rooms[sharesSubject][roomNumber].sharesSupply = supply - amount;

        emit Trade(msg.sender, sharesSubject, false, amount, price, protocolFee, subjectFee, supply - amount);

        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

}