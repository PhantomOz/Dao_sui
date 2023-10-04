module dao::dao{
    // imports
    use sui::object::{Self, UID, Map, Vec, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // Defining The DAO contract and Proposals
    struct Dao has key, store {
        admins: Vec<UID>,
        proposals: Vec<Proposal>,
        votes: Map<u32, Map<UID, bool>>
        members: Vec<UID>,
    }

    struct Proposal has key, store{
        id: UID,
        title: String,
        description: String,
        author: UID,
        executed: bool,
        created_at_ms: u64,
    }

    // implementing the DAO contract
    impl Dao {
        fn new() -> Self {
            Self {
                admins: Vec::new(),
                proposals: Vec::new(),
                votes: Map::new(),
                members: Vec::new(),
            }
        }

        fn add_admin(&mut self, ctx: &TxContext, admin: UID) -> transfer::TransferResult<()> {
            if !self.admins.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            self.admins.push(admin);
            Ok(())
        }

        fn remove_admin(&mut self, ctx: &TxContext, admin: UID) -> transfer::TransferResult<()> {
            if !self.admins.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            self.admins.retain(|&x| x != admin);
            Ok(())
        }

        fn add_member(&mut self, ctx: &TxContext, member: UID) -> transfer::TransferResult<()> {
            if !self.admins.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            self.members.push(member);
            Ok(())
        }

        fn remove_member(&mut self, ctx: &TxContext, member: UID) -> transfer::TransferResult<()> {
            if !self.admins.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            self.members.retain(|&x| x != member);
            Ok(())
        }

        fn create_proposal(&mut self, ctx: &TxContext, title: String, description: String) -> transfer::TransferResult<()> {
            if !self.members.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            let proposal = Proposal {
                id: ctx.tx_id,
                title,
                description,
                author: ctx.sender,
                executed: false,
                created_at_ms: ctx.timestamp_ms,
            };
            self.proposals.push(proposal);
            Ok(())
        }

        fn vote(&mut self, ctx: &TxContext, proposal_id: UID, vote: bool) -> transfer::TransferResult<()> {
            if !self.members.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            if !self.proposals.iter().any(|x| x.id == proposal_id) {
                return Err(transfer::Error::InvalidInput);
            }
            if !self.votes.contains_key(&proposal_id) {
                self.votes.insert(proposal_id, Map::new());
            }
            self.votes.get_mut(&proposal_id).unwrap().insert(ctx.sender, vote);
            Ok(())
        }

        fn execute_proposal(&mut self, ctx: &TxContext, proposal_id: UID) -> transfer::TransferResult<()> {
            if !self.admins.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            if !self.proposals.iter().any(|x| x.id == proposal_id) {
                return Err(transfer::Error::InvalidInput);
            }
            let proposal = self.proposals.iter_mut().find(|x| x.id == proposal_id).unwrap();
            if proposal.executed {
                return Err(transfer::Error::InvalidInput);
            }
            let votes = self.votes.get(&proposal_id).unwrap();
            let mut yes_votes = 0;
            let mut no_votes = 0;
            for vote in votes.values() {
                if *vote {
                    yes_votes += 1;
                } else {
                    no_votes += 1;
                }
            }
            if yes_votes > no_votes {
                proposal.executed = true;
                Ok(())
            } else {
                Err(transfer::Error::InvalidInput)
            }
        }

        fn get_proposal(&self, ctx: &TxContext, proposal_id: UID) -> transfer::TransferResult<Proposal> {
            if !self.members.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            if !self.proposals.iter().any(|x| x.id == proposal_id) {
                return Err(transfer::Error::InvalidInput);
            }
            Ok(self.proposals.iter().find(|x| x.id == proposal_id).unwrap().clone())
        }

        fn get_proposals(&self, ctx: &TxContext) -> transfer::TransferResult<Vec<Proposal>> {
            if !self.members.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            Ok(self.proposals.clone())
        }

        fn get_vote(&self, ctx: &TxContext, proposal_id: UID) -> transfer::TransferResult<bool> {
            if !self.members.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            if !self.proposals.iter().any(|x| x.id == proposal_id) {
                return Err(transfer::Error::InvalidInput);
            }
            if !self.votes.contains_key(&proposal_id) {
                return Err(transfer::Error::InvalidInput);
            }
            Ok(self.votes.get(&proposal_id).unwrap().get(&ctx.sender).unwrap().clone())
        }

}