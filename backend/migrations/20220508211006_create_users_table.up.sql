CREATE TABLE users (
  user_id UUID DEFAULT gen_random_uuid(),
  display_name TEXT NOT NULL,
  pronouns TEXT NOT NULL,

  PRIMARY KEY (user_id)
);
