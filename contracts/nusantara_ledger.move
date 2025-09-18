// SPDX-License-Identifier: MIT
// Nusantara Ledger - Transparency Contract
module nusantara_ledger::transparency {
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{String};
    use std::vector;

    /// Document proof record
    struct DocumentProof has key, store {
        id: UID,
        merkle_root: vector<u8>,
        metadata_hash: vector<u8>,
        tag: String,
        timestamp: u64,
        recorder: address,
    }

    /// Emitted when a document proof is recorded
    struct ProofRecorded has copy, drop {
        proof_id: ID,
        merkle_root: vector<u8>,
        metadata_hash: vector<u8>,
        tag: String,
        recorder: address,
        timestamp: u64,
    }

    /// Record a document proof on-chain
    public entry fun record_proof(
        merkle_root: vector<u8>,
        metadata_hash: vector<u8>,
        tag: String,
        ctx: &mut TxContext
    ) {
        let proof = DocumentProof {
            id: object::new(ctx),
            merkle_root,
            metadata_hash,
            tag,
            timestamp: tx_context::epoch_timestamp_ms(ctx),
            recorder: tx_context::sender(ctx),
        };

        let proof_id = object::id(&proof);

        event::emit(ProofRecorded {
            proof_id,
            merkle_root: proof.merkle_root,
            metadata_hash: proof.metadata_hash,
            tag: proof.tag,
            recorder: proof.recorder,
            timestamp: proof.timestamp,
        });

        transfer::transfer(proof, tx_context::sender(ctx));
    }
}
