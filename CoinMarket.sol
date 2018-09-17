pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title ERC20
 */
interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is Pausable {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf[msg.sender]);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowance[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) whenNotPaused public returns (bool) {
        allowance[msg.sender][_spender] = (
        allowance[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowance[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) whenNotPaused public returns (bool)
    {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

}


/**
 * @title ERC827, an extension of ERC20 token standard
 *
 * @dev Implementation the ERC827, following the ERC20 standard with extra
 * @dev methods to transfer value and data and execute calls in transfers and
 * @dev approvals.
 *
 * @dev Uses OpenZeppelin StandardToken.
 */
contract ERC827Token is StandardToken {

    /**
     * @dev Addition to ERC20 token methods. It allows to
     * @dev approve the transfer of value and execute a call with the sent data.
     *
     * @dev Beware that changing an allowance with this method brings the risk that
     * @dev someone may use both the old and the new allowance by unfortunate
     * @dev transaction ordering. One possible solution to mitigate this race condition
     * @dev is to first reduce the spender's allowance to 0 and set the desired value
     * @dev afterwards:
     * @dev https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address that will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @param _data ABI-encoded contract call to call `_to` address.
     *
     * @return true if the call function was executed successfully
     */
    function approveAndCall(address _spender, uint256 _value, bytes _data) external payable returns (bool)
    {
        require(_spender != address(this));
        super.approve(_spender, _value);
        // solium-disable-next-line security/no-call-value
        require(_spender.call.value(msg.value)(_data));
        return true;
    }

    /**
     * @dev Addition to ERC20 token methods. Transfer tokens to a specified
     * @dev address and execute a call with the sent data on the same transaction
     *
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     * @param _data ABI-encoded contract call to call `_to` address.
     *
     * @return true if the call function was executed successfully
     */
    function transferAndCall(address _to, uint256 _value, bytes _data) external payable returns (bool)
    {
        require(_to != address(this));
        super.transfer(_to, _value);
        // solium-disable-next-line security/no-call-value
        require(_to.call.value(msg.value)(_data));
        return true;
    }

    /**
     * @dev Addition to ERC20 token methods. Transfer tokens from one address to
     * @dev another and make a contract call on the same transaction
     *
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     * @param _value The amout of tokens to be transferred
     * @param _data ABI-encoded contract call to call `_to` address.
     *
     * @return true if the call function was executed successfully
     */
    function transferFromAndCall(address _from, address _to, uint256 _value, bytes _data) external payable returns (bool)
    {
        require(_to != address(this));
        super.transferFrom(_from, _to, _value);

        // solium-disable-next-line security/no-call-value
        require(_to.call.value(msg.value)(_data));
        return true;
    }

    /**
     * @dev Addition to StandardToken methods. Increase the amount of tokens that
     * @dev an owner allowed to a spender and execute a call with the sent data.
     *
     * @dev approve should be called when allowed[_spender] == 0. To increment
     * @dev allowed value is better to use this function to avoid 2 calls (and wait until
     * @dev the first transaction is mined)
     * @dev From MonolithDAO Token.sol
     *
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     * @param _data ABI-encoded contract call to call `_spender` address.
     */
    function increaseApprovalAndCall(address _spender, uint _addedValue, bytes _data) external payable returns (bool)
    {
        require(_spender != address(this));
        super.increaseApproval(_spender, _addedValue);

        // solium-disable-next-line security/no-call-value
        require(_spender.call.value(msg.value)(_data));
        return true;
    }

    /**
     * @dev Addition to StandardToken methods. Decrease the amount of tokens that
     * @dev an owner allowed to a spender and execute a call with the sent data.
     *
     * @dev approve should be called when allowed[_spender] == 0. To decrement
     * @dev allowed value is better to use this function to avoid 2 calls (and wait until
     * @dev the first transaction is mined)
     * @dev From MonolithDAO Token.sol
     *
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     * @param _data ABI-encoded contract call to call `_spender` address.
     */
    function decreaseApprovalAndCall(address _spender, uint _subtractedValue, bytes _data) external payable returns (bool)
    {
        require(_spender != address(this));
        super.decreaseApproval(_spender, _subtractedValue);

        // solium-disable-next-line security/no-call-value
        require(_spender.call.value(msg.value)(_data));
        return true;
    }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableBurnableToken is ERC827Token {
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(address _from, uint256 _value) onlyOwner external returns (bool) {
        require(_value <= balanceOf[_from]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
}

contract MintableBurnableTokenWithAgents is MintableBurnableToken {

    mapping(address => uint256) public agents;
    mapping(uint256 => address) public agentId;
    uint256 public agentCount = 0;

    event AgentTransfer(address indexed agent, address indexed from, address indexed to, uint256 value);
    event AddAgent(address indexed agent);
    event DelAgent(address indexed agent);

    modifier onlyAgent() {
        require(agents[msg.sender] != 0);
        _;
    }

    function addAgent(address _agent) external onlyOwner {
        require(agents[_agent] == 0);
        agents[_agent] = ++agentCount;
        agentId[agentCount] = _agent;
        emit AddAgent(_agent);
    }

    function delAgent(address _agent) external onlyOwner {
        require(agents[_agent] != 0);
        require(agentCount > 0);
        agentId[agents[_agent]] = agentId[agentCount];
        delete agents[_agent];
        delete agentId[agentCount--];
        emit DelAgent(_agent);
    }

    function agentTransfer(address _from, address _to, uint256 _value) onlyAgent external returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit AgentTransfer(msg.sender, _from, _to, _value);
        return true;
    }
}


contract OrangeDucat is MintableBurnableTokenWithAgents {
    // Public variables of the token
    string public name = "Orange Ducat";
    //  string public symbol = "ORD";
    string public symbol = "🍊RNG";
    uint8 public decimals = 18; //equal to Ether, it's simpler

    constructor (uint _supply) public {
        mint(owner, _supply * (10 ** uint256(decimals)));
    }

    /**
     * @dev Disallows direct send by settings a default function without the `payable` flag.
     */
    function() external {}

    /**
     * @dev Reject all ERC223 compatible tokens
     * @param from_ address The address that is transferring the tokens
     * @param value_ uint256 the amount of the specified token
     * @param data_ Bytes The data passed from the caller.
     */
    function tokenFallback(address from_, uint256 value_, bytes data_) pure external {
        from_;
        value_;
        data_;
        revert();
    }

    /**
     * @dev Transfer all Ether held by the contract to the owner.
     */
    function reclaimEther() onlyOwner external {
        owner.transfer(address(this).balance);
    }

    /**
     * @dev Reclaim all ERC20Basic compatible tokens
     * @param token ERC20Basic The address of the token contract
     */
    function reclaimToken(ERC20 token) onlyOwner external {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }
}

