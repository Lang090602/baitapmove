// hoàn thiện code để module có thể publish được
module lesson6::hero_game {
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self,Coin};
    use sui::transfer;
    use sui::sui::SUI;
    use sui::event;
    const ERROR: u64 = 0;
    const MONTER_WON: u64 = 1;


    // Điền thêm các ability phù hợp cho các object
    struct Hero has key, store {
        id: UID,
        name: String,
        hp: u64,
        experience: u64,
        sword: Option<Sword>,
        armor: Option<Armor>,
        game_id: ID,

    }

    // Điền thêm các ability phù hợp cho các object
    struct Sword has key, store{
        id: UID,
        attack: u64,
        strenght: u64,
        game_id: ID,
    }

    // Điền thêm các ability phù hợp cho các object
    struct Armor has key, store {
        id: UID,
        defense: u64,
        game_id: ID,
    }

    // Điền thêm các ability phù hợp cho các object
    struct Monter has key, store {
        id: UID,
        hp: u64,
        strenght: u64,
        game_id: ID,
    }

    struct GameInfo has key{
        id: UID,
        admin: address
    }

    // hoàn thiện function để khởi tạo 1 game mới
    fun new_game(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);

        transfer::freeze_object(GameInfo {
            id,
            admin: sender
        });
        transfer::transfer(
            GameAdmin {
                id: object::new(ctx),
                game_id,
                // heros: 0,
                monters: 0
            }, sender
        );
    }

    struct GameAdmin has key, store {
        id: UID,
        game_id: ID,
        // heros: u64, 
        monters: u64
    }

    fun init(ctx: &mut TxContext) {
        new_game(ctx)
    }

    // function để create các vật phẩm, nhân vật trong game.
    public fun hero_hp(hero: &Hero):u64 {
        if (hero.hp == 0) {
            0
        };
        
        let sword_suc_manh = if (option::is_some(&hero.sword)) {
            sword_suc_manh(option::borrow(&hero.sword))
        } else {
            0
        };
        (hero.experience * hero.hp) + sword_suc_manh
    }

    public fun sword_suc_manh(sword: &Sword): u64 {
        sword.attack + sword.strenght
    }

    public fun create_hero(game: &GameInfo, name: string, sword: &Sword, armor: &Armor, ctx: &mut TxContext): Hero{
        Hero {
            id: object::new(ctx),
            name,
            experience: 0,
            hp: 100,
            sword: option::some(sword),
            armor: option::some(armor),
            game_id: get_name_id(game)
        }
    }
    public fun create_sword(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext) {
        let value = coin::value(&payment);
        assert!(value >= 10, ERROR);

        let attack = (value * 2);
        let strenght = (value * 3);

        transfer::public_transfer(payment, game.admin);

        Sword {
            id: object::new(ctx),
            attack,
            strenght,
            game_id: get_name_id(game)
        };
    }
    public fun create_armor(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext) {
        let value = coin::value(&payment);
        assert!(value >= 10, ERROR);

        let defense = (value * 2);


         transfer::public_transfer(payment, game.admin);

         Armor {
            id: object::new(ctx),
            defense,
            game_id: get_name_id(game)
         };
    }

    public fun get_name_id(game_info: &GameInfo): ID {
        object::id(game_info)
    }

    // function để create quái vật, chiến đấu với hero, chỉ admin mới có quyền sử dụng function này
    // Gợi ý: khởi tạo thêm 1 object admin.
    public entry fun create_monter(admin: GameAdmin, game: &GameInfo, hp: u64, strenght: u64, player: address, ctx: &mut TxContext) {
        admin.monters = admin.monters += 1;
        let monter = Monter {
            id: object::new(ctx),
            hp,
            game_id: get_name_id(game),
        }
        transfer:transfer(monter, player);
    }

    // func để tăng điểm kinh nghiệm cho hero sau khi giết được quái vật
    fun level_up_hero(hero: &mut Hero, amount: u64 ) {
        hero.experience + amount;
        hero.hp + amount;
    }
    fun level_up_sword(sword: &mut Sword, amount: u64) {
        sword.attack + amount;
        sword.strenght + amount;
    }
    fun level_up_armor(armor: &mut Armor, amount: u64) {
        armor.defense + amount;
    }

    struct AttackedEvent has copy, drop {
        slayer: address,
        hero: ID,
        monter: ID,
        game_id: ID,
    }
    // Tấn công, hoàn thiện function để hero và monter đánh nhau
    // gợi ý: kiểm tra số điểm hp và strength của hero và monter, lấy hp trừ đi số sức mạnh mỗi lần tấn công. HP của ai về 0 trước người đó thua
    public entry fun attack_monter(game: &GameInfo, hero: &mut Hero, monter: Monter, ctx: &mut TxContext) {
        let Monter (id: monter_id, hp: monter_hp, game_id: _) = monter;
        let hero_hp = hero_hp(hero);

        while (monter_hp > hero_hp) {
            monter_hp = monter_hp - hero_hp;
            assert!(hero_hp >= monter_hp, MONTER_WON);
            hero_hp = hero_hp - monter_hp;
        };
        hero_hp = hero_hp;
        hero.experience = hero.experience + hero.hp;
        if(option::is_some(&hero.sword)) {
            level_up_sword(option::borrow_mut(&mut hero.sword), 2)
        };
        event::emit(AttackedEvent {
            slayer:: tx_context::sender(ctx),
            hero: object::uid_to_inner(&hero.id),
            monter: object::uid_to_inner(&monter_id),
            game_id: get_name_id(game)
        });
        object::delete(monter_id);
    }

}
