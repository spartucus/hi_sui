#[test_only]
module sui_hi::sui_hi_tests;

use sui::sui::SUI;
use sui::coin::{Coin, Self};
use std::type_name;
use sui::{test_scenario::{begin, ctx, end}};
use sui::poseidon;

#[test]
fun test_sui_typename() {
    let name = type_name::with_defining_ids<SUI>();
    let name_string = name.into_string();
    std::debug::print(&name_string); // "0000000000000000000000000000000000000000000000000000000000000002::sui::SUI"
    let name_string = std::string::from_ascii(name_string);
    std::debug::print(&name_string);
    let serialized_name = sui::bcs::to_bytes(&name);
    std::debug::print(&serialized_name); // "0000000000000000000000000000000000000000000000000000000000000002::sui::SUI"

    let name_string2 = name.module_string();
    std::debug::print(&name_string2); // "sui"

    let name_string3 = name.address_string();
    std::debug::print(&name_string3); // "0000000000000000000000000000000000000000000000000000000000000002"
}

fun deposit(
    coin: Coin<0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC>,
    ctx: &TxContext
) {
    let coin_value = coin::value(&coin);
    assert!(coin_value > 0, 1);

    let sender = ctx.sender();
    transfer::public_transfer(coin, sender);
}

#[test]
fun test_deposit() {
    let mut scenario = begin(@0xF);
    let ctx = ctx(&mut scenario);

    let name = type_name::with_defining_ids<0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC>();
    let name_string = name.into_string();
    std::debug::print(&name_string); // "a1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC"

    let coin = coin::mint_for_testing<0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC>(100, ctx);
    deposit(coin, ctx);

    end(scenario);
}

#[test]
fun test_poseidon() {
    let a = 18586133768512220936620570745912940619677854269274689475585506675881198879027;
    let b = poseidon::poseidon_bn254(&vector[a]);
    std::debug::print(&b);

    let c = 17744324452969507964952966931655538206777558023197549666337974697819074895989;
    assert!(b == c, 1);
}