CREATE TABLE pending_logins (
  login_id UUID DEFAULT gen_random_uuid(),
  user_key UUID NOT NULL REFERENCES users (user_id),
  login_token TEXT UNIQUE NOT NULL,
  expires TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp + '30 days',

  PRIMARY KEY (login_id)
);

CREATE TABLE sessions (
  session_id UUID DEFAULT gen_random_uuid(),
  user_key UUID NOT NULL REFERENCES users (user_id),
  session_token TEXT UNIQUE NOT NULL,
  expires TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp + '30 days',

  PRIMARY KEY (session_id)
);

ALTER TABLE users ADD UNIQUE (email); 
