-- insert
INSERT INTO users (cognito_sub, email, display_name) VALUES ('0001', 'diego@email.com', 'Diego');
INSERT INTO users (cognito_sub, email, display_name) VALUES ('0002', 'bonnie@email.com', 'Bonnie');
INSERT INTO users (cognito_sub, email, display_name) VALUES ('0003', 'merlin@email.com', 'Merlin');

INSERT INTO user_groups (name, invite_code, created_by_user_id) VALUES ('Awesome Group', '12345', 1);
INSERT INTO user_groups (name, invite_code, created_by_user_id) VALUES ('Doink Group', '67890', 3);

INSERT INTO group_members (group_id, user_id, role) VALUES (1, 1, 'owner');
INSERT INTO group_members (group_id, user_id, role) VALUES (1, 2, 'member');
INSERT INTO group_members (group_id, user_id, role) VALUES (1, 3, 'member');

INSERT INTO group_members (group_id, user_id, role) VALUES (2, 3, 'owner');
INSERT INTO group_members (group_id, user_id, role) VALUES (2, 2, 'member');

INSERT INTO stickers (name, country) VALUES ('Messi', 'Argentina');
INSERT INTO stickers (name, country) VALUES ('Neymar', 'Brazil');
INSERT INTO stickers (name, country) VALUES ('Vini Jr.', 'Brazil');
INSERT INTO stickers (name, country) VALUES ('Mbappe', 'France');
INSERT INTO stickers (name, country) VALUES ('Ronaldo', 'Portugal');
INSERT INTO stickers (name, country) VALUES ('Modric', 'Croatia');
INSERT INTO stickers (name, country) VALUES ('Hormiga', 'Mexico');
INSERT INTO stickers (name, country) VALUES ('Luis Romo', 'Mexico');
INSERT INTO stickers (name, country) VALUES ('Ochoa', 'Mexico');
INSERT INTO stickers (name, country) VALUES ('Egypt Stadium Left', 'Egypt');
INSERT INTO stickers (name, country) VALUES ('Egypt Stadium Right', 'Egypt');
INSERT INTO stickers (name, country) VALUES ('Japan Crest', 'Japan');

-- One-on-one trade
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (1, 1, 1, 0);
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (2, 1, 0, 1); -- I have 0 extras and need this sticker
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (3, 1, 0, 0); -- I don't have extras, but I do have the sticker, so I don't need more

-- Three-way trade
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (1, 2, 0, 1);
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (2, 2, 0, 0);
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (3, 2, 1, 0);

INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (1, 3, 1, 0);
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (2, 3, 0, 1);
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (3, 3, 0, 0);

INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (1, 4, 0, 0);
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (2, 4, 1, 0);
INSERT INTO collection (user_id, sticker_id, amount, needs) VALUES (3, 4, 0, 1);