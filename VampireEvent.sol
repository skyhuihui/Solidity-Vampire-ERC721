pragma solidity ^0.4.24;

contract VampireEvent {

    // creatVampiersEvent
    event creatVampiersEvent(string name,  uint32 time, uint32 rarity, uint vamId, uint dna, uint level, uint fatherID);
    
    // renameVampierEvent
    event renameVampierEvent(uint vamId, string name);
    
    // Battle victory
    event battleVictory(uint vamId);
    
    // Maximum amount of auction
    event auction(address addr, uint amount, uint vamId);
}