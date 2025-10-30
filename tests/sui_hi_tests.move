#[test_only]
module sui_hi::sui_hi_tests;

use sui::sui::SUI;
use std::type_name;

#[test]
fun test_sui_typename() {
    let name = type_name::with_defining_ids<SUI>();
    let name_string = name.into_string();
    std::debug::print(&name_string); // "0000000000000000000000000000000000000000000000000000000000000002::sui::SUI"

    let name_string2 = name.module_string();
    std::debug::print(&name_string2); // "sui"

    let name_string3 = name.address_string();
    std::debug::print(&name_string3); // "0000000000000000000000000000000000000000000000000000000000000002"
}