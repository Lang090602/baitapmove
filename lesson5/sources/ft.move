// Hoàn thiện đoạn code để có thể publish được
module lesson5::FT_TOKEN {
    use std::option;
    use sui::url;
    use sui::coin::{Self, CoinMetadata, TreasuryCap, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use std::string;
    use std::ascii;
    use sui::event;

    struct FT_TOKEN { }

    fun init(witness: FT_TOKEN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
             witness,
            2,
            b"BADAO$", 
            b"BADAO TOKEN",
            b"Token for lesson 04",
            option::some(url::new_unsafe_from_bytes(b"https://docs.sui.io/learn/objects")),
            ctx 
        );
            transfer::public_share_object(treasury_cap);
            transfer::public_transfer(metadata, tx_context::sender(ctx));
    }

    // hoàn thiện function để có thể tạo ra 10_000 token cho mỗi lần mint, và mỗi owner của token mới có quyền mint
    public fun mint(_: &CoinMetadata<FT_TOKEN>, treasury_cap: &mut TreasuryCap<FT_TOKEN>, amount: u64, recipient: address, ctx: &mut TxContext) {
         assert!(amount == 10000, "Số lượng phải là 10000 để mint");
         coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
    }

    // Hoàn thiện function sau để user hoặc ai cũng có quyền tự đốt đi số token đang sở hữu
    public entry fun burn_token(treasury_cap: &mut TreasuryCap<FT_TOKEN>, coin: Coin<FT_TOKEN>) {
            coin::burn(treasury_cap, coin);
    }

    // Hoàn thiện function để chuyển token từ người này sang người khác.
    public entry fun transfer_token(coin: &mut Coin<FT_TOKEN>, amount: u64, recipient: address, ctx: &mut TxContext) {
            let coin = split_token(coin, amount, ctx);
            transfer::public_transfer(coin, recipient);
        // sau đó khởi 1 Event, dùng để tạo 1 sự kiện khi function transfer được thực thi
    struct TransferEvent has copy, drop {
        sender: address,
        recipient: address,
        amount: u64
    }
    event::emit(TransferEvent {
        sender: tx_context::sender(ctx),
        recipient,
        amount,
    });
    }

    // Hoàn thiện function để chia Token Object thành một object khác dùng cho việc transfer
    // gợi ý sử dụng coin:: framework
    public fun split_token(token: &mut coin::Coin<FT_TOKEN>, split_amount: u64, ctx: &mut TxContext): Coin<FT_TOKEN> {
        coin::split(token, split_amount, ctx);
    }

    // Viết thêm function để token có thể update thông tin sau
    public entry fun update_name(coin: &mut CoinMetadata<FT_TOKEN>, treasury_cap: &TreasuryCap, new_name: string::String) {
        coin::update_name<FT_TOKEN>(treasury_cap, coin, new_name);
        event::emit(UpdateEvent { success: true, data: "name đã được cập nhật thành công.".into() });
    }

    public entry fun update_description(treasury_cap: &TreasuryCap<FT_TOKEN>, coin: &mut CoinMetadata<FT_TOKEN>, description: string::String) {
        coin::update_description<FT_TOKEN>(treasury_cap, coin, description);
        event::emit(UpdateEvent { success: true, data: "description đã được cập nhật thành công.".into() });
    }

    public entry fun update_symbol(treasury_cap: &TreasuryCap<FT_TOKEN>, coin: &mut CoinMetadata<FT_TOKEN>, symbol: ascii::String) {
        coin::update_symbol(treasury_cap, coin, symbol);
        event::emit(UpdateEvent { success: true, data: "symbol đã được cập nhật thành công.".into() });
    }

    public entry fun update_icon_url(treasury_cap: &TreasuryCap<FT_TOKEN>, coin: &mut CoinMetadata<FT_TOKEN>, url: ascii::String) {
        coin::update_icon_url(treasury_cap, coin, url);
        event::emit(UpdateEvent { success: true, data: "icon url đã được cập nhật thành công.".into() });
    }


    // sử dụng struct này để tạo event cho các function update bên trên.
    struct UpdateEvent {
        success: bool,
        data: String
    }
    

    // Viết các function để get dữ liệu từ token về để hiển thị
    public entry fun get_token_name(coin: &CoinMetadata<FT_TOKEN>): string::String {
        coin::get_name(coin);
    }
    public entry fun get_token_description(coin: &CoinMetadata<FT_TOKEN>): string::String {
        coin::get_description(coin);
    }
    public entry fun get_token_symbol(coin: &CoinMetadata<FT_TOKEN>): ascii::String {
        coin::get_symbol(coin);
    }
    public entry fun get_token_icon_url(coin: &CoinMetadata<FT_TOKEN>): option::Option<url::Url> {
        coin::get_icon_url(coin);
    }
}
