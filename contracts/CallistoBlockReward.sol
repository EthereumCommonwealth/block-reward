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

    uint256 constant MINER_REWARD = 0x16c4abbebea0100000;
    uint256 constant STAKE_REWARD = 0x340aad21b3b700000;
    address constant STAKE_ADDRESS = 0x3c06f218Ce6dD8E2c535a8925A2eDF81674984D9;
    address constant STAKE_ADDRESS_HF1 = 0xd813419749b3c2cdc94a2f9cfcf154113264a9d6;
    uint256 constant TREASURY_REWARD = 0x68155a43676e00000;
    address constant TREASURY_ADDRESS = 0x74682Fc32007aF0b6118F259cBe7bCCC21641600;
    uint256 constant TREASURY_REWARD_HF1 = STAKE_REWARD;
    uint256 constant STAKE_REWARD_HF1 = TREASURY_REWARD;
    uint256 constant HF1_BLOCK = 0x155cc0;

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

        address stake_address = STAKE_ADDRESS;
        uint256 stake_reward = STAKE_REWARD;

        address treasury_address = TREASURY_ADDRESS;
        uint256 treasury_reward = TREASURY_REWARD;

        // HF1 code
        if (block.number >= HF1_BLOCK) {
            stake_reward = STAKE_REWARD_HF1;
            treasury_reward = TREASURY_REWARD_HF1;
            stake_address = STAKE_ADDRESS_HF1;
        }

        addresses[1] = stake_address;
        rewards[1] = stake_reward;

        addresses[2] = treasury_address;
        rewards[2] = treasury_reward;

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
}