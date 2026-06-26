const db = require('../db');

async function recalculateTrades(groupId) {
    await db.execute(
        `DELETE FROM trade_calculations WHERE group_id = ?`,
        [groupId]
    );    

    const [calcResult] = await db.execute(
        `INSERT INTO trade_calculations (group_id, status, started_at)
         VALUES (?, 'processing', NOW())`,
        [groupId]
    );
    const calculationId = calcResult.insertId;

    await db.execute(
        `DELETE FROM trades WHERE group_id = ?`,
        [groupId]
    );

    try {
        const [members] = await db.execute(
            `SELECT user_id FROM group_members WHERE group_id = ?`,
            [groupId]
        );

        if (members.length < 2) {
            await db.execute(
                `UPDATE trade_calculations
                 SET status = 'completed', completed_at = NOW()
                 WHERE id = ?`,
                [calculationId]
            );
            return 0;
        }

        const userIds = members.map(m => m.user_id);
        const placeholders = userIds.map(() => '?').join(', ');

        const [collections] = await db.execute(
            `SELECT user_id, sticker_id, duplicates_amount, needs
             FROM collection
             WHERE user_id IN (${placeholders})
               AND (needs = 1 OR duplicates_amount > 0)`,
            userIds
        );

        const stickersNeededBy = {};
        const stickersOfferedBy = {};

        for (const row of collections) {
            const { user_id, sticker_id, duplicates_amount, needs } = row;

            if (needs) {
                if (!stickersNeededBy[sticker_id]) stickersNeededBy[sticker_id] = new Set();
                stickersNeededBy[sticker_id].add(user_id);
            }

            if (duplicates_amount > 0 && !needs) {
                if (!stickersOfferedBy[sticker_id]) stickersOfferedBy[sticker_id] = new Set();
                stickersOfferedBy[sticker_id].add(user_id);
            }
        }

        const newTrades = [];
        const tradeKeys = new Set();

        const addTrade = (steps) => {
            const key = steps
                .map(s => `${s.fromUserId}:${s.stickerId}:${s.toUserId}`)
                .sort()
                .join('|');

            if (tradeKeys.has(key)) return;
            tradeKeys.add(key);
            newTrades.push(steps);
        };

        // 2-way trades
        // Complexity: O(offered_stickers^2 * users^2)
        for (const [stickerX, offerers] of Object.entries(stickersOfferedBy)) {
            const xNeeders = stickersNeededBy[stickerX];
            if (!xNeeders) continue;

            for (const userA of offerers) {
                for (const userB of xNeeders) {
                    if (userA === userB) continue;

                    for (const [stickerY, yOfferers] of Object.entries(stickersOfferedBy)) {
                        if (!yOfferers.has(userB)) continue;
                        if (!stickersNeededBy[stickerY]?.has(userA)) continue;

                        addTrade([
                            { fromUserId: userA, toUserId: userB, stickerId: Number(stickerX) },
                            { fromUserId: userB, toUserId: userA, stickerId: Number(stickerY) },
                        ]);
                    }
                }
            }
        }

        // 3-way trades
        // Complexity: O(offered_stickers^3 * users^3)
        for (const [stickerX, offerers] of Object.entries(stickersOfferedBy)) {
            const xNeeders = stickersNeededBy[stickerX];
            if (!xNeeders) continue;

            for (const userA of offerers) {
                for (const userB of xNeeders) {
                    if (userA === userB) continue;

                    for (const [stickerY, yOfferers] of Object.entries(stickersOfferedBy)) {
                        if (!yOfferers.has(userB)) continue;

                        const yNeeders = stickersNeededBy[stickerY];
                        if (!yNeeders) continue;

                        for (const userC of yNeeders) {
                            if (userC === userA || userC === userB) continue;

                            for (const [stickerZ, zOfferers] of Object.entries(stickersOfferedBy)) {
                                if (!zOfferers.has(userC)) continue;
                                if (!stickersNeededBy[stickerZ]?.has(userA)) continue;

                                addTrade([
                                    { fromUserId: userA, toUserId: userB, stickerId: Number(stickerX) },
                                    { fromUserId: userB, toUserId: userC, stickerId: Number(stickerY) },
                                    { fromUserId: userC, toUserId: userA, stickerId: Number(stickerZ) },
                                ]);
                            }
                        }
                    }
                }
            }
        }

        for (const steps of newTrades) {
            const [tradeResult] = await db.execute(
                `INSERT INTO trades (group_id) VALUES (?)`,
                [groupId]
            );
            const tradeId = tradeResult.insertId;

            for (let i = 0; i < steps.length; i++) {
                const { fromUserId, toUserId, stickerId } = steps[i];
                await db.execute(
                    `INSERT INTO trade_steps
                        (trade_id, step_order, from_user_id, to_user_id, sticker_id, quantity)
                     VALUES (?, ?, ?, ?, ?, 1)`,
                    [tradeId, i + 1, fromUserId, toUserId, stickerId]
                );
            }
        }

        await db.execute(
            `UPDATE trade_calculations
             SET status = 'completed', completed_at = NOW()
             WHERE id = ?`,
            [calculationId]
        );

        return newTrades.length;

    } catch (err) {
        await db.execute(
            `UPDATE trade_calculations
             SET status = 'failed', completed_at = NOW(), error_message = ?
             WHERE id = ?`,
            [err.message, calculationId]
        );

        throw err;
    }
}

module.exports = recalculateTrades;