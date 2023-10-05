module dao::dao{
    // imports
    use sui::object::{Self, UID, Map, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // Defining The DAO contract and Proposals
    struct Proposal{
        id: UID,
        title: String,
        description: String,
        author: address,
        executed: bool,
        created_at_ms: u64,
    }

    struct Vote {
        proposal_id: UID,
        vote: bool,
    }

    struct Dao has store {
        admins: vector<address>,
        proposals: vector<Proposal>,
        votes: vector<Vote>,
        members: vector<UID>,
    }


    // implementing the DAO contracts
    fun init(ctx: &mut TxContext){
        let admins = Dao{
            admins: vector![ctx.sender],
            proposals: vector![],
            votes: vector![],
            members: vector![],
        };
        ctx.store.set(admins);   
    }

    fun add_admin(ctx: &TxContext, admin: UID) -> transfer::TransferResult<()> {
        if !self.admins.contains(&ctx.sender) {
            return Err(transfer::Error::Unauthorized);
        }
        ctx.admins.push(admin);            
    }

        fun remove_admin(ctx: &TxContext, admin: UID) -> transfer::TransferResult<()> {
            if !self.admins.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            ctx.admins.retain(|&x| x != admin);
        }

        fun add_member(ctx: &TxContext, member: UID) -> transfer::TransferResult<()> {
            if !self.admins.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            ctx.members.push(member);
        }

        fun remove_member(ctx: &TxContext, member: UID) -> transfer::TransferResult<()> {
            if !self.admins.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            ctx.members.retain(|&x| x != member);
        }

        fun create_proposal(ctx: &TxContext, title: String, description: String) -> transfer::TransferResult<()> {
            if !self.members.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            let proposal = Proposal {
                id: object::new(ctx),
                title,
                description,
                author: ctx.sender,
                executed: false,
                created_at_ms: ctx.timestamp_ms,
            };
            self.proposals.push(proposal);
        }

        fun vote(&mut self, ctx: &TxContext, proposal_id: UID, vote: bool) -> transfer::TransferResult<()> {
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
        }

        fun execute_proposal(&mut self, ctx: &TxContext, proposal_id: UID) -> transfer::TransferResult<()> {
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
            } else {
                Err(transfer::Error::InvalidInput)
            }
        }

        fun get_proposal(&self, ctx: &TxContext, proposal_id: UID) -> transfer::TransferResult<Proposal> {
            if !self.members.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            if !self.proposals.iter().any(|x| x.id == proposal_id) {
                return Err(transfer::Error::InvalidInput);
            }
            Ok(self.proposals.iter().find(|x| x.id == proposal_id).unwrap().clone())
        }

        fun get_proposals(&self, ctx: &TxContext) -> transfer::TransferResult<Vec<Proposal>> {
            if !self.members.contains(&ctx.sender) {
                return Err(transfer::Error::Unauthorized);
            }
            Ok(self.proposals.clone())
        }

        fun get_vote(&self, ctx: &TxContext, proposal_id: UID) -> transfer::TransferResult<bool> {
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