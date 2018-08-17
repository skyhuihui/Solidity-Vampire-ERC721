pragma solidity ^0.4.24;

import "./ownable.sol";
import "./SafeMath.sol";
import "./VampireEvent.sol";
import "./VampireStruct.sol";

contract ERC721 {
   function balanceOf(address _owner) public constant returns (uint balance);
   //所有权相关的接口
   function ownerOf(uint256 _tokenId) public constant returns (address owner);
   function approve(address _to, uint256 _tokenId) public;
   function takeOwnership(uint256 _tokenId) public;
   function transfer(address _to, uint256 _tokenId) public;
   //事件
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract ERC20{
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract Vampire is Ownable, VampireEvent, VampireStruct, ERC721 {

    using SafeMath for *;
    
    uint dnaDigits = 20;
    uint dnaModulus = 10 ** dnaDigits; // dna bits
    uint creatcooling; // How long does it take to create one
    uint dayCountMoney; // Price of single breeding
    uint randNonce = 0; // Random number nonce calculation valuep
    uint singCount = 30000000000000000000; // Number of login gifts
    uint biddersTime; // Bidding time
    uint32 createNewTime; // The time of the last vampire feeding.
    uint32 winBattle;// The winning ratio of battle
    uint32 battleColling; // Combat cooling time
    uint32 lastTimeBattle; // Last combat time
    
    ERC20 erc20; // Token contracts
    
    VampireStruct.Vampire [] public vampires; //Vampire []
    VampireStruct.Bidder [] public bidder; //bidder []
    
    mapping (uint => address) vamToAddr; //uint => address Vampire number corresponding user
    mapping (address => uint) addrVamCount; //address => count Number of vampires for users
    mapping (address => uint) addrToSignCount; //address => count User sign in days
    mapping (uint => uint) vamToAuction; // vamID => batter Vampire corresponding auction structure id
    mapping (uint => address) vamApprovals; // erc721 => approval To grant authorization
    
    //VampireOwner
    modifier VampireOwner(uint _vampireId){
        require(msg.sender == vamToAddr[_vampireId]);
        _;  
    }

    function () 
    public 
    payable
    {}

    // Set erc20 token address
    function setErc20Address(address _erc20)
        public 
        onlyOwner
        {
            erc20 = ERC20(_erc20);
        }
    
    // How long can it generate the cost of vampires again
    function setCreatCooling(uint _time, uint _dayCountMoney)
        public 
        onlyOwner
    {
        creatcooling = 1 seconds * _time;
        dayCountMoney = _dayCountMoney;
      
     }
    
    // How long can it generate the cost of vampires again
     function setWinBattle(uint32 _winBattle) 
    public 
    onlyOwner
    {
        winBattle = _winBattle;
      
    }
  
    // Set the combat cooldown time.
    function setbattleColling(uint32 _battleColling) 
    public 
    onlyOwner
    {
        battleColling = _battleColling;
      
    }
    // set Bidding time
    function setBiddingTime(uint _biddersTime)
    public
    onlyOwner
    {
        biddersTime = 1 seconds * _biddersTime;
    }
  
    // Creating new vampires
    function creatVampiers()
    public 
    {
        // Each user is generated once.
        require(addrVamCount[msg.sender] == 0);
        uint32 time = uint32(now);
        uint32 rarity = getRarity();
        _creatVampiers(time, rarity, 1, 0);
      
    }
  
    // Vampires eat food ,Creating new vampires
    function creatNewVampiers(uint _vamId) 
    public 
    VampireOwner(_vamId)
    {
        // Over cooling time
        require(now > createNewTime + creatcooling);
        // Reset the time to create new creatures.
        createNewTime = uint32(now);
        if(getRarity() == 1 && _vamId != 0)
        uint32 rarity = getRarity();
        _creatVampiers(createNewTime, rarity, vampires[_vamId].level, _vamId);
      
    }
  
    // Create high varity vampires
    function createVarityVampires(uint32 rarity) 
    public 
    onlyOwner
    {
        uint32 time = uint32(now);
        _creatVampiers(time, rarity, 1, 0);

    }
  
    // _creatVampiers private
    function _creatVampiers(uint32 time,
        uint32 rarity, 
        uint level, 
        uint 
        fatherID) 
    private 
    {
        uint dna = _generateRandomDna(time);
        // vampires.push
        uint id = vampires.push(VampireStruct.Vampire("%E5%90%B8%E8%A1%80%E9%AC%BC", dna, level, fatherID, 100, time, rarity)).sub(1);
        // set vamToAddr
        vamToAddr[id] = msg.sender;
        // addrVamCount++
        addrVamCount[msg.sender] = addrVamCount[msg.sender].add(1);
        // Creat  event
        emit creatVampiersEvent("%E5%90%B8%E8%A1%80%E9%AC%BC", time, rarity, id, dna, level, fatherID);
        
    }
  
    // Calculated rarity
    function getRarity() 
    private 
    view 
    returns(uint32)
    {
        // Generating random numbers
        uint random = _getRandom();
        // Get 1-5 different rarity according to scale.
        if(random <= 5)
            return 5;
        else if(random <= 15 && random > 5)
            return 4;
        else if(random <= 30 && random >15)
            return 3;
        else if(random <= 50 && random > 30)
            return 2;
        else
            return 1;
            
    }
  
    // Get random numbers
    function _getRandom() 
    private 
    returns (uint)
    {
        uint random = uint(keccak256(now, msg.sender, randNonce)) % 100;
        randNonce++;
        return random;
    }
  
    //get dna, Ensure DNA length is 20 bits.
    function _generateRandomDna(uint32 time) 
    private 
    view 
    returns (uint) 
    {
        uint rand = uint(keccak256(time));
        return rand % dnaModulus;
    
    }
  
    // rename vampire
    function renameVampiers(string _name, uint _vamId) 
    public 
    VampireOwner(_vamId)
    {
        vampires[_vamId].name = _name;
        emit renameVampierEvent(_vamId, _name);
        
    }
  
    // Vampire fighting  ， Get some profits
    function Battle(uint _vamId, 
        uint _otherVamId) 
    public 
    VampireOwner(_vamId)
    {
        require(now > battleColling + lastTimeBattle);
        lastTimeBattle = uint32(now);
        // Generating random numbers
        uint random = _getRandom();
        // Winning ratio
        if(random > winBattle){
            // Calculating combat effectiveness
            vampires[_vamId].power.add(50);
            erc20.transfer(msg.sender, 50000000000000000000);
            if(vampires[_otherVamId].power <= 50)
                vampires[_otherVamId].power = 0;
            else
                vampires[_otherVamId].power.sub(50);
        } else{
            // Calculating combat effectiveness
            vampires[_otherVamId].power.add(50);
            if(vampires[_vamId].power <= 50)
                vampires[_vamId].power = 0;
            else
                vampires[_vamId].power.sub(50);
        }
      
    }
    
    // Users sign in to give token
    function sign()
    public
    {
        require(addrToSignCount[msg.sender] <= 14);
        addrToSignCount[msg.sender] = addrToSignCount[msg.sender].add(1);
        erc20.transfer(msg.sender, singCount);
    }
  
    // Get users of vampires
    function getVampiresByOwner(address _owner) 
    public 
    view 
    returns(uint[]) 
    {
        uint[] memory result = new uint[](addrVamCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < vampires.length; i++) {
          if (vamToAddr[i] == _owner) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    
    }
  
    // Start vampire auction
    function startBidders(uint money, 
    uint _vamId) 
    public 
    VampireOwner(_vamId)
    {
        address [] addrs;
        uint [] moneys;
        uint id = bidder.push(VampireStruct.Bidder(addrs, moneys, money, uint32(now), false)).sub(1);
        vamToAuction[id] = _vamId; 
    }
    
    // Start vampire auction
    function Bidders(uint money, 
    uint _vamId) 
    public 
    {
        require(now < biddersTime + bidder[vamToAuction[_vamId]].startTime);
        require(money > bidder[vamToAuction[_vamId]].money);
        require(money > bidder[vamToAuction[_vamId]].moneys[bidder[vamToAuction[_vamId]].moneys.length.sub(1)]);
        bidder[vamToAuction[_vamId]].addrs.push(msg.sender);
        bidder[vamToAuction[_vamId]].moneys.push(money);
        emit auction(msg.sender, money, _vamId);
    }
    
    // end vampire auction
    function endBidders(uint _vamId)
    public 
    onlyOwner{
        for (uint i = 0; i < bidder.length; i++) {
            if (now > biddersTime + bidder[vamToAuction[_vamId]].startTime
            && bidder[vamToAuction[_vamId]].grant == false) {
                vamToAddr[_vamId] = bidder[vamToAuction[_vamId]].addrs[bidder[vamToAuction[_vamId]].addrs.length.sub(1)];
                bidder[vamToAuction[_vamId]].grant = true;
          }
        }
    }
    
    // get vampire count
    function balanceOf(address _owner) 
    public 
    view 
    returns 
    (uint256 _balance) 
    {
        return addrVamCount[_owner];
    }

    // Get vampires users
    function ownerOf(uint256 _tokenId) 
    public 
    view 
    returns 
    (address _owner) 
    {
        return vamToAddr[_tokenId];
    }
    
    //Vampire trade
    function _transfer(address _from, 
    address _to, 
    uint256 _tokenId) 
    private 
    {
        addrVamCount[_to] = addrVamCount[_to].add(1);
        addrVamCount[msg.sender] = addrVamCount[msg.sender].sub(1);
        vamToAddr[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }
    
    //Vampire trade
    function transfer(address _to, 
    uint _vamId) 
    public 
    VampireOwner(_vamId) 
    {
        _transfer(msg.sender, _to, _vamId);
    }
    
    function approve(address _to, 
    uint256 _tokenId) 
    public 
    VampireOwner(_tokenId) 
    {
        vamApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) 
    public 
    {
        require(vamApprovals[_tokenId] == msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }
    
    // withdraw
    function withdraw() 
    public 
    onlyOwner 
    {
        owner.transfer(address(this).balance);
    }
  
    // withdrawalToken
    function withdrawalToken()
    public 
    onlyOwner
    {
        uint256 b = erc20.balanceOf(address(this));
        erc20.transfer(owner, b);
    }
}