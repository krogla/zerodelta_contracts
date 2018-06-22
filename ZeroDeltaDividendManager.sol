pragma solidity ^0.4.24;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ZeroDeltaDividendToken {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);

    function holders(uint256) external view returns (address);
    function holdersCount() external view returns (uint256);
}


contract ZeroDeltaDividendManager {
    using SafeMath for uint256;

    ZeroDeltaDividendToken public dividendToken;
    uint256 public retainedEarning;

    /* Handle payments we couldn't make. */
    mapping (address => uint256) public pendingWithdrawals;

    /* Indicates a payment is now available to a shareholder */
    event WithdrawalAvailable(address indexed holder, uint256 amount);

    /* Indicates a payment is payed to a shareholder */
    event WithdrawalPayed(address indexed holder, uint256 amount);

    /* Indicates a dividend payment was made. */
    event DividendPayment(uint256 totalPaidOut);

    /* Create our contract with references to other contracts as required. */
    constructor (ZeroDeltaDividendToken _dividendToken) public{
        /* Setup access to our other contracts and validate their versions */
        dividendToken = _dividendToken;
    }

    // Makes a dividend payment - we make it available to all senders then send the change back to the caller.  We don't actually send the payments to everyone to reduce gas cost and also to
    // prevent potentially getting into a situation where we have recipients throwing causing dividend failures and having to consolidate their dividends in a separate process.

    function () public payable {
        payDividend();
    }

    function payDividend() public payable {
        retainedEarning = retainedEarning.add(msg.value);
        require(retainedEarning > 0);

        /* Determine how much to pay each shareholder. */
        uint256 totalSupply = dividendToken.totalSupply();
        uint256 totalPaidOut = 0;
        /* Enum all accounts and send them payment */
        // внимание! id холдера начинаются с 1!
        for (uint256 i = 1; i <= dividendToken.holdersCount(); i++) {
            address holder = dividendToken.holders(i);
            uint256 withdrawal = retainedEarning.mul(dividendToken.balanceOf(holder)).div(totalSupply);
            pendingWithdrawals[holder] = pendingWithdrawals[holder].add(withdrawal);
            emit WithdrawalAvailable(holder, withdrawal);
            totalPaidOut = totalPaidOut.add(withdrawal);
        }
        retainedEarning = retainedEarning.sub(totalPaidOut);
        emit DividendPayment(totalPaidOut);
    }

    /* Allows a user to request a withdrawal of their dividend in full. */
    function withdrawDividend() public {
        uint amount = pendingWithdrawals[msg.sender];
        // Ensure we have dividends available
        require (amount > 0);//!!!
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        // delete pendingWithdrawals[msg.sender];
        msg.sender.transfer(amount);
        emit WithdrawalPayed(msg.sender, amount);
    }
}
