/*
==========================================
核心概念对比总结（以太坊 vs Sui）
==========================================

1. 【能力系统】
   以太坊: 没有能力系统，所有对象行为一致
   Sui:
   - key: 可以作为顶层对象拥有（必须）
   - store: 可以存储在其他对象内部或转移
   - copy: 可以复制值
   - drop: 可以隐式丢弃（否则必须显式解构）

2. 【对象所有权】
   以太坊: 所有状态在合约中，通过mapping管理
   Sui: 四种对象类型
   - Owned: 被单个地址拥有（快速，无共识开销）
   - Shared: 所有人可访问（需要共识）
   - Immutable: 不可变对象（freeze）
   - Wrapped: 被其他对象包含

3. 【转移函数】
   - transfer::transfer: 模块内部使用
   - transfer::public_transfer: 跨模块，需要store
   - transfer::share_object: 转为共享对象
   - transfer::freeze_object: 冻结为不可变

4. 【Coin处理】
   以太坊: msg.value接收ETH，需要.call{value}()发送
   Sui: 
   - 接收: Coin<SUI>参数
   - 分割: coin::split
   - 合并: coin::join
   - 提取: balance::split / coin::take
   - 转换: coin::into_balance / coin::from_balance

5. 【函数类型】
   - entry: 可以直接从交易调用（类似public external）
   - public: 可以被其他模块调用
   - public(package): 只能被同package调用
   - private: 只能模块内部调用

6. 【事件系统】
   以太坊: emit EventName(...)
   Sui: event::emit(EventStruct { ... })
   事件结构体必须有copy + drop能力

7. 【交易上下文】
   以太坊: msg.sender, block.timestamp等
   Sui: TxContext - tx_context::sender(ctx), tx_context::epoch(ctx)

8. 【对象包装模式 (Wrapping)】
   Sui特有: 一个对象可以被包含在另一个对象内部
   - 解决了不能在同一交易中接收owned对象后立即share的问题
   - Listing包装NFT，然后Listing成为shared对象
   - 购买时通过解构Listing来取出NFT

9. 【gas优化】
   Sui优势: 
   - Owned对象操作不需要共识（更便宜更快）
   - 并行执行没有依赖关系的交易
   - 建议: 尽量使用owned对象，减少shared对象使用

==========================================
*/

module sui_hi::marketplace {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::event;
    use std::string::String;

    // ============ 错误码 ============
    const EInsufficientPayment: u64 = 1;
    const ENotOwner: u64 = 2;
    #[allow(unused_const)]
    const ENotForSale: u64 = 3;

    // ============ 能力展示 ============
    
    // 1. NFT: 只有 key + store - 可以转移和存储，但不能复制或丢弃
    // 适用场景：唯一资产（NFT、土地证书等）
    public struct NFT has key, store {
        id: UID,
        name: String,
        description: String,
        url: String,
        creator: address,
    }

    // 2. 元数据: 只有 copy + drop + store - 可以复制和丢弃
    // 适用场景：配置信息、统计数据等
    #[allow(unused_field)]
    public struct Metadata has copy, drop, store {
        total_sales: u64,
        floor_price: u64,
    }

    // 3. 管理员权限: 只有 key - 不能转移，只能删除
    // 适用场景：权限凭证、一次性票据
    public struct AdminCap has key {
        id: UID,
    }

    // 4. 市场共享对象: key + store
    // 适用场景：需要全局访问的合约状态
    public struct Marketplace has key {
        id: UID,
        balance: Balance<SUI>,  // 平台收益
        fee_percent: u64,       // 平台手续费百分比
    }

    // 5. 挂单信息: key + store - 使用wrapping模式包装NFT
    // 关键改进：NFT被包装在Listing内部，而不是单独的shared对象
    public struct Listing has key, store {
        id: UID,
        nft: NFT,           // NFT被包装在内部
        price: u64,
        seller: address,
    }

    // ============ 事件 ============
    
    public struct NFTMinted has copy, drop {
        nft_id: ID,
        creator: address,
        name: String,
    }

    public struct NFTListed has copy, drop {
        nft_id: ID,
        price: u64,
        seller: address,
    }

    public struct NFTSold has copy, drop {
        nft_id: ID,
        price: u64,
        seller: address,
        buyer: address,
    }

    // ============ 初始化函数 ============
    
    fun init(ctx: &mut TxContext) {
        // 创建市场共享对象
        let marketplace = Marketplace {
            id: object::new(ctx),
            balance: balance::zero(),
            fee_percent: 2, // 2%手续费
        };
        
        // 转为共享对象，任何人都可以访问
        transfer::share_object(marketplace);

        // 创建管理员权限，发送给部署者
        let admin = AdminCap {
            id: object::new(ctx),
        };
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    // ============ NFT铸造 ============
    
    // 铸造NFT并直接转移给接收者
    public fun mint_nft(
        name: String,
        description: String,
        url: String,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let minted_name = copy name;

        let nft = NFT {
            id: object::new(ctx),
            name,
            description,
            url,
            creator: tx_context::sender(ctx),
        };
        
        let nft_id = object::id(&nft);
        
        event::emit(NFTMinted {
            nft_id,
            creator: tx_context::sender(ctx),
            name: minted_name,
        });

        // transfer: 转移所有权给指定地址（对象变成owned）
        transfer::public_transfer(nft, recipient);
    }

    public fun mint_and_share_nft(
        name: String,
        description: String,
        url: String,
        ctx: &mut TxContext
    ) {
        let minted_name = copy name;

        let nft = NFT {
            id: object::new(ctx),
            name,
            description,
            url,
            creator: tx_context::sender(ctx),
        };

        let nft_id = object::id(&nft);

        event::emit(NFTMinted {
            nft_id,
            creator: tx_context::sender(ctx),
            name: minted_name,
        });

        transfer::share_object(nft);
    }

    // ============ Transfer函数对比 ============
    
    // 1. transfer::transfer - 只能在模块内部使用，转移任意类型（有key能力）
    #[allow(lint(custom_state_change))]
    public fun internal_transfer_nft(nft: NFT, recipient: address) {
        transfer::transfer(nft, recipient);
    }

    // 2. transfer::public_transfer - 可以跨模块使用，但要求类型有store能力
    #[allow(lint(custom_state_change))]
    public fun public_transfer_nft(nft: NFT, recipient: address) {
        transfer::public_transfer(nft, recipient);
    }

    // 3. transfer::freeze_object - 冻结对象，使其不可变
    #[allow(lint(custom_state_change))]
    public fun freeze_nft(nft: NFT) {
        transfer::freeze_object(nft);
    }

    // 4. transfer::share_object - 转为共享对象
    #[allow(lint(custom_state_change), lint(share_owned))]
    public fun share_nft(nft: NFT) {
        transfer::share_object(nft);
    }

    // ============ 市场功能 - 展示Coin处理 ============
    
    // 挂单出售NFT - 使用wrapping模式
    // NFT被包装在Listing对象内部，然后Listing成为shared对象
    public fun list_nft(
        nft: NFT,
        price: u64,
        ctx: &mut TxContext
    ) {
        let nft_id = object::id(&nft);
        let seller = tx_context::sender(ctx);

        // 创建Listing并将NFT包装进去
        let listing = Listing {
            id: object::new(ctx),
            nft,  // NFT被包装在Listing内部
            price,
            seller,
        };

        event::emit(NFTListed {
            nft_id,
            price,
            seller,
        });

        // 将包含NFT的Listing转为共享对象
        transfer::share_object(listing);
    }

    // 购买NFT - 展示接收和处理Coin
    #[allow(unused_let_mut, lint(self_transfer))]
    public fun buy_nft(
        marketplace: &mut Marketplace,
        mut listing: Listing,  // 接收shared对象的所有权
        mut payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let buyer = tx_context::sender(ctx);
        
        // 验证支付金额
        let payment_value = coin::value(&payment);
        assert!(payment_value >= listing.price, EInsufficientPayment);

        // 计算平台手续费
        let fee = (listing.price * marketplace.fee_percent) / 100;
        let seller_amount = listing.price - fee;

        // 分割手续费
        let fee_coin = coin::split(&mut payment, fee, ctx);
        
        // 将手续费加入平台余额
        let fee_balance = coin::into_balance(fee_coin);
        balance::join(&mut marketplace.balance, fee_balance);

        // 分割卖家收益
        let seller_coin = coin::split(&mut payment, seller_amount, ctx);
        
        // 转账给卖家
        transfer::public_transfer(seller_coin, listing.seller);

        // 如果有找零，退还给买家
        let change_value = coin::value(&payment);
        if (change_value > 0) {
            transfer::public_transfer(payment, buyer);
        } else {
            coin::destroy_zero(payment);
        };

        // 从Listing中取出NFT
        let Listing { id, nft, price, seller } = listing;
        let nft_id = object::id(&nft);

        // 转移NFT给买家
        transfer::public_transfer(nft, buyer);

        event::emit(NFTSold {
            nft_id,
            price,
            seller,
            buyer,
        });

        // 删除Listing对象
        object::delete(id);
    }

    // 取消挂单 - 从Listing中取回NFT
    #[allow(unused_let_mut)]
    public fun cancel_listing(
        mut listing: Listing,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        
        // 只有卖家可以取消
        assert!(listing.seller == sender, ENotOwner);

        // 解构Listing并取出NFT
        let Listing { id, nft, price: _, seller } = listing;

        // 将NFT归还给卖家
        transfer::public_transfer(nft, seller);
        
        // 删除Listing对象
        object::delete(id);
    }

    // ============ 管理员功能 ============
    
    // 提取平台收益 - 需要AdminCap权限
    public fun withdraw_fees(
        _: &AdminCap,  // 验证管理员权限
        marketplace: &mut Marketplace,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let withdrawn = coin::take(&mut marketplace.balance, amount, ctx);
        transfer::public_transfer(withdrawn, recipient);
    }

    // 更新手续费 - 需要AdminCap权限
    public fun update_fee(
        _: &AdminCap,
        marketplace: &mut Marketplace,
        new_fee_percent: u64,
    ) {
        marketplace.fee_percent = new_fee_percent;
    }

    // ============ 查询函数（View函数）============
    
    public fun get_nft_info(nft: &NFT): (String, String, String, address) {
        (nft.name, nft.description, nft.url, nft.creator)
    }

    public fun get_listing_info(listing: &Listing): (ID, u64, address) {
        let nft_id = object::id(&listing.nft);
        (nft_id, listing.price, listing.seller)
    }

    public fun get_marketplace_fee(marketplace: &Marketplace): u64 {
        marketplace.fee_percent
    }

    public fun get_marketplace_balance(marketplace: &Marketplace): u64 {
        balance::value(&marketplace.balance)
    }

    // ============ 测试函数 ============
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}