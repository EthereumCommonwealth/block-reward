// Copyright 2018 Parity Technologies (UK) Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

pragma solidity ^0.4.24;


interface BlockReward {
    // produce rewards for the given beneficiaries, with corresponding reward codes.
    // only callable by `SYSTEM_ADDRESS`
    function reward(address[] beneficiaries, uint16[] kind)
        external
        returns (address[], uint256[]);
}


contract CallistoBlockReward is BlockReward {
    address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    // uint256 constant MINER_REWARD = 0x16c4abbebea0100000;
    uint256 constant STAKE_REWARD = 0x340aad21b3b700000;
    address constant STAKE_ADDRESS = 0x3c06f218Ce6dD8E2c535a8925A2eDF81674984D9;
    address constant STAKE_ADDRESS_HF1 = 0xd813419749b3c2cDc94A2F9Cfcf154113264a9d6;
    uint256 constant TREASURY_REWARD = 0x68155a43676e00000;
    address constant TREASURY_ADDRESS = 0x74682Fc32007aF0b6118F259cBe7bCCC21641600;
    uint256 constant TREASURY_REWARD_HF1 = STAKE_REWARD;
    uint256 constant STAKE_REWARD_HF1 = TREASURY_REWARD;
    uint256 constant HF1_BLOCK = 0x155cc0;

    // Monetary policy
    uint256[5] MP_MINER_REWARD = [0x16c4abbebea0100000, 0xcaf67003701680000, 0x7068fb1598aa00000, 0x3dd356e57a5d80000, 0x21b91820143300000];

    uint256[5] MP_STAKE_REWARD = [0x68155a43676e00000, 0x1f399b1438a100000, 0x12bc29d8eec700000, 0xb3db2b55c1100000, 0x6bd495d530c90000];

    uint256[5] MP_TREASURY_REWARD = [0x340aad21b3b700000, 0x4e1003b28d9280000, 0x38347d8acc5500000, 0x2757f17ac23b80000, 0x1af996539a2a60000];

    modifier onlySystem {
        require(msg.sender == SYSTEM_ADDRESS);
        _;
    }

    // produce rewards for the given benefactors, with corresponding reward codes.
    // only callable by `SYSTEM_ADDRESS`
    function reward(address[] beneficiaries, uint16[] kind)
        external
        onlySystem
        returns (address[], uint256[])
    {
        require(beneficiaries.length == kind.length);

        address[] memory addresses = new address[](3); // minimum 3 for author, ubi contract and dev contract
        uint256[] memory rewards = new uint256[](3);
        uint256 blockPosition = getBlockPosition();
        uint256 MINER_REWARD = getMinerReward(blockPosition);

        addresses[1] = getStakeAddress();
        rewards[1] = getStakeReward(blockPosition);

        addresses[2] = TREASURY_ADDRESS;
        rewards[2] = getTreasuryReward(blockPosition);

        for (uint i = 0; i < beneficiaries.length; i++) {
            if (kind[i] == 0) { // author
                uint256 finalReward = MINER_REWARD + (MINER_REWARD >> 5) * (beneficiaries.length - 1);
                addresses[0] = beneficiaries[i];
                rewards[0] = finalReward;

            } else if (kind[i] >= 100) { // uncle
                uint16 depth = kind[i] - 100;
                uint256 uncleReward = (MINER_REWARD * (8 - depth)) >> 3;

                addresses = pushAddressArray(addresses, beneficiaries[i]);
                rewards = pushUint256Array(rewards, uncleReward);
            }
        }

        return (addresses, rewards);
    }

    function pushAddressArray(address[] arr, address addr)
        internal
        pure
        returns (address[])
    {
        address[] memory ret = new address[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            ret[i] = arr[i];
        }
        ret[ret.length - 1] = addr;
        return ret;
    }

    function pushUint256Array(uint256[] arr, uint256 u)
        internal
        pure
        returns (uint256[])
    {
        uint256[] memory ret = new uint256[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            ret[i] = arr[i];
        }
        ret[ret.length - 1] = u;
        return ret;
    }

    function getStakeAddress()
        internal
        view
        returns (address)
    {
        if (block.number > HF1_BLOCK) {
            return STAKE_ADDRESS_HF1;
        }
        return STAKE_ADDRESS;
    }

    function getTreasuryReward(uint256 blockPosition)
        internal
        view
        returns (uint256)
    {
        if (block.number > HF1_BLOCK) {
            return MP_TREASURY_REWARD[blockPosition];
        }
        return TREASURY_REWARD;
    }

    function getStakeReward(uint256 blockPosition)
        internal
        view
        returns (uint256)
    {
        if (block.number > HF1_BLOCK) {
            return MP_STAKE_REWARD[blockPosition];
        }
        return STAKE_REWARD;
    }

    function getMinerReward(uint blockPosition)
        internal
        view
        returns (uint256)
    {
        return MP_MINER_REWARD[blockPosition];
    }

    function getBlockPosition()
        internal
        view
        returns (uint256)
    {
        if (block.number < 2750001) {
            return 0;
        } else if (block.number < 4250001) {
            return 1;
        } else if (block.number < 5750001) {
            return 2;
        } else if (block.number < 7250001) {
            return 3;
        }
        return 4;
    }    
}