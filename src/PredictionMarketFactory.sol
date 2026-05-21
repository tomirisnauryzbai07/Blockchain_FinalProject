// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketTypes} from "./libraries/MarketTypes.sol";
import {PredictionMarket} from "./PredictionMarket.sol";

contract PredictionMarketFactory {
    address public owner;
    address public treasury;
    address public outcomeToken;

    PredictionMarket[] internal markets;
    mapping(bytes32 salt => address market) public marketBySalt;
    mapping(address market => MarketTypes.MarketMetadata metadata) internal marketMetadata;

    event MarketCreated(
        address indexed market,
        string question,
        uint64 endTime,
        uint256 feeBps,
        address collateralToken,
        address oracleAdapter,
        bytes32 oracleQuestionId
    );
    event DeterministicMarketCreated(address indexed market, bytes32 indexed salt, string question);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "NOT_OWNER");
    }

    constructor(address initialOwner, address treasury_, address outcomeToken_) {
        require(initialOwner != address(0), "ZERO_OWNER");
        require(treasury_ != address(0), "ZERO_TREASURY");
        require(outcomeToken_ != address(0), "ZERO_OUTCOME_TOKEN");

        owner = initialOwner;
        treasury = treasury_;
        outcomeToken = outcomeToken_;
    }

    function createMarket(
        MarketTypes.MarketConfig calldata config
    ) external onlyOwner returns (address market) {
        PredictionMarket newMarket = new PredictionMarket(treasury, outcomeToken, config);
        markets.push(newMarket);
        market = address(newMarket);
        _storeMetadata(market, config, false, bytes32(0));

        emit MarketCreated(
            market,
            config.question,
            config.endTime,
            config.feeBps,
            config.collateralToken,
            config.oracleAdapter,
            config.oracleQuestionId
        );
    }

    function createMarketDeterministic(
        MarketTypes.MarketConfig calldata config,
        bytes32 salt
    ) external onlyOwner returns (address market) {
        require(marketBySalt[salt] == address(0), "SALT_ALREADY_USED");

        PredictionMarket newMarket = new PredictionMarket{salt: salt}(treasury, outcomeToken, config);
        markets.push(newMarket);

        market = address(newMarket);
        marketBySalt[salt] = market;
        _storeMetadata(market, config, true, salt);

        emit DeterministicMarketCreated(market, salt, config.question);
    }

    function marketCount() external view returns (uint256) {
        return markets.length;
    }

    function marketAt(uint256 index) external view returns (address) {
        return address(markets[index]);
    }

    function marketDetails(address market) external view returns (MarketTypes.MarketMetadata memory) {
        return marketMetadata[market];
    }

    function _storeMetadata(
        address market,
        MarketTypes.MarketConfig calldata config,
        bool deterministic,
        bytes32 salt
    ) internal {
        marketMetadata[market] = MarketTypes.MarketMetadata({
            question: config.question,
            endTime: config.endTime,
            resolveWindow: config.resolveWindow,
            feeBps: config.feeBps,
            collateralToken: config.collateralToken,
            oracleAdapter: config.oracleAdapter,
            oracleQuestionId: config.oracleQuestionId,
            deterministic: deterministic,
            deploymentSalt: salt
        });
    }
}
