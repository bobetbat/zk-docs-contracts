// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ZKDocsCore {
    address public contractOwner;

    struct Contract {
        address signer;
        uint256 validUntilTime;
        string contractType;
        string contractMethodToCheck;
        address contractAddressToCheck;
        bool isPendingForSigner;
        bool isRevealed;
        bool isSettled;
        uint256 uuid;
    }

    event ContractCreated(
        address indexed signer,
        uint256 uuid
    );
    event ContractSettled(
        uint256 timestamp,
        uint256 uuid
    );
    event ContractEnded(
        uint256 timestamp,
        uint256 uuid
    );
    event ContractDisputed(
        uint256 timestamp,
        uint256 uuid
    );

    // Map creator wallet address to his/her contracts.
    mapping(address => Contract[]) public allContractsByCreator;
    mapping(uint256 => Contract) public contractByID;
    mapping(uint256 => string) public contractsHashProofs;

    constructor() {
        contractOwner = msg.sender;
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

    function createContract(
        address _signer,
        uint256 _validTo,
        string memory _contractType,
        string memory _contractMethodToCheck,
        address _contractAddrToCheck
    ) public {
        uint256 uuidOfNewContract = uint256(keccak256(abi.encodePacked(block.number, block.timestamp)));
        Contract memory newContract = Contract(
            _signer,
            _validTo,
            _contractType,
            _contractMethodToCheck,
            _contractAddrToCheck,
            true,
            false,
            false,
            uuidOfNewContract
        );

        allContractsByCreator[msg.sender].push(newContract);
        contractByID[uuidOfNewContract] = newContract;

        emit ContractCreated(_signer, uuidOfNewContract);
    }

    function signContract(uint256 _uuid, string memory _txHash) public onlyExistedContract(_uuid) onlyPendingForSignerContract(_uuid) {
        contractsHashProofs[_uuid] = _txHash;
        contractByID[_uuid].isSettled = true;
        contractByID[_uuid].isPendingForSigner = false;

        emit ContractSettled(block.timestamp, _uuid);
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

    function disputeContract(uint256 _uuid) public onlyExistedContract(_uuid) onlySettledContract(_uuid) {
        contractByID[_uuid].isSettled = false;
        contractByID[_uuid].isRevealed = true;

        emit ContractDisputed(block.timestamp, _uuid);
    }
}
