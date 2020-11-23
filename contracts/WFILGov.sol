/// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;

/// @title WFILGov
/// @author Nazzareno Massari @naszam
/// @notice Wrapped Filecoin (WFIL) Governor
/// @dev All function calls are currently implemented without side effects through TDD approach
/// @dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface WFILToken {
  function wrap(address to, uint256 amount) external returns (bool);
  function unwrap(uint256 amount) external returns (bool);
}

contract WFILGov is AccessControl, Pausable {

    /// @dev Contract Owner
    address private _owner;

    WFILToken internal immutable wfil;

    /// @dev Library
    using SafeERC20 for IERC20;

    /// @dev Roles
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Events
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor(address wfil_)
        public
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(PAUSER_ROLE, msg.sender);

        _owner = msg.sender;
        wfil = WFILToken(wfil_);

    }

    /// @notice Fallback function
    /// @dev Added not payable to revert transactions not matching any other function which send value
    fallback() external {
        revert();
    }

    /// @dev Returns the address of the contract owner
    function owner() public view returns (address) {
        return _owner;
    }


    /// @notice Change the owner address
    /// @param newOwner The address of the new owner
    function setOwner(address newOwner) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILGov: caller is not the default admin");
        require(newOwner != address(0), "WFILGov: new owner is the zero address");
        emit OwnerChanged(_owner, newOwner);
        _owner = newOwner;
    }

    /// @notice Reclaim all ERC20 compatible tokens
    /// @dev Access restricted only for Default Admin
    /// @param token IERC20 address of the token contract
    function reclaimToken(IERC20 token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILGov: caller is not the default admin");
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_owner, balance);
    }


    /// @notice Add a new Custodian
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the new Custodian
    function addCustodian(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILGov: caller is not the default admin");
        grantRole(CUSTODIAN_ROLE, account);
    }

    /// @notice Remove a Custodian
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the Custodian
    function removeCustodian(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILGov: caller is not the default admin");
        revokeRole(CUSTODIAN_ROLE, account);
    }

    /// @notice Add a new Merchant
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the new Merchant
    function addMerchant(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILGov: caller is not the default admin");
        grantRole(MERCHANT_ROLE, account);
    }

    /// @notice Remove a Merchant
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the Merchant
    function removeMerchant(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILGov: caller is not the default admin");
        revokeRole(MERCHANT_ROLE, account);
    }

    /// @notice Pause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function pause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "WFILGov: must have pauser role to pause");
        _pause();
    }

    /// @notice Unpause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function unpause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "WFILGov: must have pauser role to unpause");
        _unpause();
    }
}