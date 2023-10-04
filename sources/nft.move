
module nft::sui_bootcampers {
    use sui::tx_context::{sender, TxContext};
    use std::string::{utf8, String};
    use sui::transfer::transfer;
    use sui::object::{Self, UID};

    use sui::package;
    use sui::display;

    struct Bootcampers has key, store {
        id: UID,
        name: String,
        img_url: String,
    }

    struct SUI_BOOTCAMPERS has drop {}

   
    fun init(otw: SUI_BOOTCAMPERS, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"creator"),
        ];

        let values = vector[
            // For `name` one can use the `Hero.name` property
            utf8(b"{name}"),
            // For `image_url` use an IPFS template + `img_url` property.
            utf8(b"ipfs://{img_url}"),
            // Description is static for all `Hero` objects.
            utf8(b"A Sui Hero is a Sui Bootcamper!"),
            // Creator field can be any
            utf8(b"Group 4 Sui x Encode Bootcamp")
        ];

        
        let publisher = package::claim(otw, ctx);

        
        let display = display::new_with_fields<Bootcampers>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer(publisher, sender(ctx));
        transfer(display, sender(ctx));
    }

    public fun mint(name: String, img_url: String, ctx: &mut TxContext): Bootcampers {
        let id = object::new(ctx);
        Bootcampers { id, name, img_url }
    }
}