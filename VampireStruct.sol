pragma solidity ^0.4.24;

contract VampireStruct {
    
    struct Vampire{
        string name;
        uint dna;
        uint level;
        uint fatherID;
        uint power;
        uint32 creatTime;
        uint32 rarity; 
    }
    
    // auction
    struct Bidder{
        address [] addrs;
        uint [] moneys;
        uint money;
        uint32 startTime;
        bool grant;
    }
}