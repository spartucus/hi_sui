## Sui HI Marketplace Demo Scripts

### Overview
This repository contains a set of shell scripts that walk through the full lifecycle of an NFT marketplace deployed on the Sui testnet. The scripts demonstrate how to publish Move packages, mint NFTs, create listings, execute purchases, manage marketplace settings, and inspect emitted events.

### Core Concepts Comparison (Ethereum vs Sui)

1. 【Abilities系统】
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


### Usage
```bash
./scripts/0_setup.sh
./scripts/1_publish.sh
./scripts/2_mint_nft.sh
# ...持续执行直到 ./scripts/11_summary.sh
```