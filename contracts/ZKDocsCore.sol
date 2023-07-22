// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "./ZKDocsScheduler.sol";

contract ZKDocsCore {
    address public contractOwner;
    address public constant EAS_ATTEST_CONTRACT_ADDR = 0x3e95B8E249c4536FE1db2E4ce5476010767C0A05;
    ZKDocsScheduler schedulerListenerContract;
    IEAS easContract;

    struct Contract {
        address recipient;
        address creator;
        address contractAddressToVerifyBalance;
        uint256 borrowingAmount;
        uint256 validUntilTime;
        uint256 uuid;
        string linkToIPFS;
        bool isPendingForSigner;
        bool isRevealed;
        bool isSettled;
    }

    event ContractCreated(
        address indexed recipient,
        uint256 uuidOfNewContract
    );
    event ContractSettled(
        uint256 timestamp,
        address indexed recipient,
        address indexed creator,
        string docSignedHash,
        string ipfsLink,
        uint256 uuidOfContract
    );
    event ContractEnded(
        uint256 timestamp,
        uint256 uuidOfContract
    );
    event ContractDisputed(
        uint256 timestamp,
        uint256 uuidOfContract
    );

    // Map creator wallet address to his/her contracts.
    mapping(address => Contract[]) public allContractsByCreator;
    // Map uuid of a contract to contract object.
    mapping(uint256 => Contract) public contractByID;
    // Map uuid of a contract to contract hash proof.
    mapping(uint256 => string) public contractsHashProofs;

    constructor(address _schedulerAddress) {
        contractOwner = msg.sender;
        schedulerListenerContract = ZKDocsScheduler(_schedulerAddress);
        easContract = IEAS(EAS_ATTEST_CONTRACT_ADDR);
    }

    modifier onlyExistedContract(uint256 _uuid) {
        require (
            contractByID[_uuid].uuid > 0,
            "You can operate only existed contract"
        );
        _;
    }

    modifier onlySettledContract(uint256 _uuid) {
        require (
            contractByID[_uuid].isSettled,
            "Only settled contract can be modified"
        );
        _;
    }

    modifier onlyPendingForSignerContract(uint256 _uuid) {
        require (
            contractByID[_uuid].isPendingForSigner,
            "Only settled contract can be modified"
        );
        _;
    }

    modifier onlyAttestedOnChain(bytes32 _accountSignHash) {
        require (
            easContract.isAttestationValid(_accountSignHash),
            "Opps. Looks like this account not attested on chain yet"
        );
        _;
    }

    function createContract(
        address _recipient,
        uint256 _validTo,
        address _contractAddressToVerifyBalance,
        uint256 _borrowingAmount,
        bytes32 _creatorESignHash
    ) public onlyAttestedOnChain(_creatorESignHash) {
        uint256 uuidOfNewContract = uint256(keccak256(abi.encodePacked(block.number, block.timestamp)));
        Contract memory newContract = Contract(
            _recipient,
            msg.sender,
            _contractAddressToVerifyBalance,
            _borrowingAmount,
            _validTo,
            uuidOfNewContract,
            "",
            true,
            false,
            false
        );

        allContractsByCreator[msg.sender].push(newContract);
        contractByID[uuidOfNewContract] = newContract;

        emit ContractCreated(_recipient, uuidOfNewContract);
    }

    function signContract(
        uint256 _uuid,
        string memory _docSignedHash,
        bytes32 _recipientESignHash,
        string memory _ipfsLink
    ) public onlyExistedContract(_uuid) onlyPendingForSignerContract(_uuid) onlyAttestedOnChain(_recipientESignHash) {
        Contract storage _c = contractByID[_uuid];
        contractsHashProofs[_uuid] = _docSignedHash;
        _c.linkToIPFS = _ipfsLink;
        _c.isSettled = true;
        _c.isPendingForSigner = false;

        emit ContractSettled(
            block.timestamp,
            _c.recipient,
            _c.creator,
            _docSignedHash,
            _ipfsLink,
            _uuid
        );
    }

    function endContract(uint256 _uuid, address _creator) public onlyExistedContract(_uuid) {
        Contract[] storage contractsByCreator = allContractsByCreator[_creator];

        for (uint256 i; i < contractsByCreator.length; i++) {
            if (contractsByCreator[i].uuid == contractByID[_uuid].uuid) {
                contractsByCreator[i] = contractsByCreator[contractsByCreator.length - 1];
                contractsByCreator.pop();

                break;
            }
        }

        delete contractByID[_uuid];

        emit ContractEnded(block.timestamp, _uuid);
    }

    function disputeContract(uint256 _uuid) private onlyExistedContract(_uuid) onlySettledContract(_uuid) {
        contractByID[_uuid].isSettled = false;
        contractByID[_uuid].isRevealed = true;

        emit ContractDisputed(block.timestamp, _uuid);
    }

    function checkForDisput(uint256 _uuid) public {
        Contract memory contractToCheck = contractByID[_uuid];

        if (schedulerListenerContract.shouldDoDisput(
            contractToCheck.validUntilTime,
            contractToCheck.contractAddressToVerifyBalance,
            contractToCheck.creator,
            contractToCheck.borrowingAmount
        )) {
            disputeContract(_uuid);
        }
    }
}
