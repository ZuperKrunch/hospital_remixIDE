// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MedicalRecordSystem {
    enum Role { None, Admin, Doctor, Patient }
    
    struct Record {
        string ipfsHash;
        uint256 timestamp;
        address doctor;
        bool isActive; 
    }

    address public admin;
    
    
    mapping(address => Role) public roles;
    
    
    mapping(address => Record[]) private patientRecords;
    
    
    mapping(address => mapping(address => bool)) public authorizedDoctors;

    event RoleAssigned(address indexed account, Role role);
    event RecordAdded(address indexed patient, address indexed doctor, string ipfsHash);
    event RecordUpdated(address indexed patient, uint256 index, string newIpfsHash);
    event RecordDeleted(address indexed patient, uint256 index);

    modifier onlyAdmin() {
        require(roles[msg.sender] == Role.Admin, "Access denied: Admin only");
        _;
    }

    modifier onlyDoctor() {
        require(roles[msg.sender] == Role.Doctor, "Access denied: Doctor only");
        _;
    }

    constructor() {
        admin = msg.sender;
        roles[msg.sender] = Role.Admin; 
    }

    
    function assignRole(address _account, Role _role) public onlyAdmin {
        roles[_account] = _role;
        emit RoleAssigned(_account, _role);
    }

   
    function setDoctorAuthorization(address _doctor, bool _status) public {
        require(roles[msg.sender] == Role.Patient || roles[msg.sender] == Role.None, "Only patient can set auth");
        authorizedDoctors[msg.sender][_doctor] = _status;
    }

    
    function addRecord(address _patient, string memory _ipfsHash) public onlyDoctor {
        require(authorizedDoctors[_patient][msg.sender], "Doctor not authorized by this patient");

        patientRecords[_patient].push(Record({
            ipfsHash: _ipfsHash,
            timestamp: block.timestamp,
            doctor: msg.sender,
            isActive: true
        }));

        emit RecordAdded(_patient, msg.sender, _ipfsHash);
    }

    
    function getRecords(address _patient) public view returns (Record[] memory) {
        if (msg.sender == _patient || roles[msg.sender] == Role.Admin) {
            return patientRecords[_patient];
        }
        require(authorizedDoctors[_patient][msg.sender], "Unauthorized to view records");
        return patientRecords[_patient];
    }

    
    function updateRecord(address _patient, uint256 _index, string memory _newIpfsHash) public onlyDoctor {
        require(authorizedDoctors[_patient][msg.sender], "Not authorized");
        require(_index < patientRecords[_patient].length, "Index out of bounds");
        require(patientRecords[_patient][_index].isActive, "Record is deleted");

        patientRecords[_patient][_index].ipfsHash = _newIpfsHash;
        emit RecordUpdated(_patient, _index, _newIpfsHash);
    }

    
    function deleteRecord(address _patient, uint256 _index) public onlyDoctor {
        require(authorizedDoctors[_patient][msg.sender], "Not authorized");
        require(_index < patientRecords[_patient].length, "Index out of bounds");

        patientRecords[_patient][_index].isActive = false;
        emit RecordDeleted(_patient, _index);
    }
}