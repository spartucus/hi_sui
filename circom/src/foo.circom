pragma circom 2.0.6;

include "../node_modules/circomlib/circuits/poseidon.circom";

template PoseidonChecker() {
    signal input a;
    signal output b;

    component poseidon = Poseidon(1);
    poseidon.inputs[0] <== a;
    b <== poseidon.out;

    log("a =", a);
    log("b =", b);
 }

 component main = PoseidonChecker();